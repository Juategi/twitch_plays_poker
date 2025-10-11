import 'dart:math';

import 'package:twitch_poker_game/engine/ai/opponent_modeling.dart';
import 'package:twitch_poker_game/engine/ai/poker_ai_base.dart';
import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/player.dart';

enum PlayerStyle { tight, loose, aggressive }

class PokerAIMiniCFR implements PokerAIBase {
  final Map<PlayerModel, OpponentStats> opponentStats = {};
  final Map<PlayerModel, List<String>> opponentRanges = {};
  final PlayerStyle style; // tight, loose, aggressive

  PokerAIMiniCFR({this.style = PlayerStyle.tight});

  @override
  Future<String> decideAction({
    required PlayerModel player,
    required List<PlayerModel> opponents,
    required List<CardModel> community,
    required int currentBet,
    required int minRaise,
    required String stage,
    required int raisesSoFar,
    required int maxRaisesPerRound,
  }) async {
    //await Future.delayed(Duration(seconds: 2)); // delay IA

    // 1️⃣ Actualizar rangos postflop según oponentes
    _updateOpponentRanges(opponents, stage);

    // 2️⃣ Estimación de equity base según rango y etapa
    double baseEquity = _estimateEquityWithRange(
      player,
      community,
      stage,
      opponents,
    );

    // 3️⃣ Ajuste según opponent modeling
    double adjustment = 0.0;
    for (var opp in opponents) {
      final stats = opponentStats[opp] ?? OpponentStats();
      adjustment += stats.getAdjustment();
    }

    double finalEquity = (baseEquity + adjustment).clamp(0.0, 1.0);
    final canRaise = raisesSoFar < maxRaisesPerRound;
    // 4️⃣ Decisión probabilística
    final rnd = Random().nextDouble();
    // ✅ Bluff dinámico según estilo y etapa
    final bluffChance = _bluffChance(stage);
    if (rnd < bluffChance && canRaise) {
      return "raise";
    }
    if (finalEquity < 0.4) return "fold";
    if (finalEquity < 0.65) return "call";
    if (canRaise && rnd < 0.05) return "raise"; // bluff ocasional
    if (canRaise) {
      return "raise";
    }
    return "call";
  }

  // --- Definición de la probabilidad de bluff según estilo y etapa ---
  double _bluffChance(String stage) {
    double base;
    switch (style) {
      case PlayerStyle.tight:
        base = 0.03;
        break;
      case PlayerStyle.loose:
        base = 0.10;
        break;
      case PlayerStyle.aggressive:
        base = 0.15;
        break;
    }

    // Ajuste según etapa de la mano: más bluff en etapas tardías
    switch (stage) {
      case 'preflop':
        return base;
      case 'flop':
        return base + 0.02;
      case 'turn':
        return base + 0.05;
      case 'river':
        return base + 0.08;
      default:
        return base;
    }
  }

  // --- Actualiza rangos de los rivales postflop según sus acciones ---
  void _updateOpponentRanges(List<PlayerModel> opponents, String stage) {
    for (var opp in opponents) {
      opponentRanges.putIfAbsent(opp, () => _initialRange(opp));
      final stats = opponentStats[opp];
      if (stats != null) {
        // Si bluffea mucho, agregar manos débiles al rango estimado
        if (stats.bluffCount > stats.raiseCount) {
          opponentRanges[opp] = [
            ...opponentRanges[opp]!,
            'JTs',
            'Q9s',
          ]; // ejemplo de manos débiles
        }
        // Si raisea fuerte, eliminar manos débiles del rango
        if (stats.raiseCount > stats.foldCount) {
          opponentRanges[opp] = opponentRanges[opp]!
              .where((h) => !['JTs', 'Q9s'].contains(h))
              .toList();
        }
      }
    }
  }

  // --- Estimación de equity considerando rangos ---
  double _estimateEquityWithRange(
    PlayerModel player,
    List<CardModel> community,
    String stage,
    List<PlayerModel> opponents,
  ) {
    final rnd = Random();
    double stageModifier;
    switch (stage) {
      case 'preflop':
        stageModifier = 0.5;
        break;
      case 'flop':
        stageModifier = 0.6;
        break;
      case 'turn':
        stageModifier = 0.7;
        break;
      case 'river':
        stageModifier = 0.8;
        break;
      default:
        stageModifier = 0.6;
    }

    // Rango propio preflop
    final ownRange = _initialRange(player);
    final inRange = ownRange.contains(PokerHandHelper.holeToCode(player.hole));
    double equity = inRange
        ? stageModifier + rnd.nextDouble() * 0.2
        : stageModifier - 0.1 + rnd.nextDouble() * 0.1;

    // Ajuste según rangos de los oponentes
    for (var opp in opponents) {
      final oppRange = opponentRanges[opp] ?? _initialRange(opp);
      // Si la mano del jugador tiene buena probabilidad contra el rango del oponente, subir equity
      if (_beatsRange(player.hole, oppRange, community)) {
        equity += 0.05;
      } else {
        equity -= 0.05;
      }
    }

    return equity.clamp(0.0, 1.0);
  }

  // --- Inicializa rango simplificado según estilo ---
  List<String> _initialRange(PlayerModel p) {
    switch (style) {
      case PlayerStyle.tight:
        return ['AA', 'KK', 'QQ', 'AKs', 'AQs', 'AK', 'AQ'];
      case PlayerStyle.loose:
        return [
          'AA',
          'KK',
          'QQ',
          'JJ',
          'TT',
          '99',
          'AKs',
          'AQs',
          'KQs',
          'AK',
          'AQ',
          'KQ',
        ];
      case PlayerStyle.aggressive:
        return ['AA', 'KK', 'QQ', 'JJ', 'AKs', 'AQs', 'KQs', 'AK', 'AQ', 'KQ'];
    }
  }

  // --- Verifica si la mano del jugador "vence" en promedio al rango del oponente ---
  bool _beatsRange(
    List<CardModel> hole,
    List<String> oppRange,
    List<CardModel> community,
  ) {
    // Mini-simulación rápida: si el par alto o AK, se considera que gana la mayoría de las veces
    final code = PokerHandHelper.holeToCode(hole); // ej. "AK", "QQ"
    return oppRange.any(
      (h) =>
          PokerHandHelper.handStrength(code) >= PokerHandHelper.handStrength(h),
    );
  }

  void updateOpponentStats(PlayerModel opponent, OpponentAction action) {
    opponentStats.putIfAbsent(opponent, () => OpponentStats()).update(action);
  }
}

class PokerHandHelper {
  /// Convierte las cartas del jugador en un código simple tipo "AK", "QQ", "JTs", etc.
  static String holeToCode(List<CardModel> hole) {
    if (hole.length != 2) return '';
    final r1 = hole[0].rank;
    final r2 = hole[1].rank;
    final suited = hole[0].suit == hole[1].suit;
    final sortedRanks = [r1, r2]
      ..sort(
        (a, b) => _rankValue(b.shortName).compareTo(_rankValue(a.shortName)),
      );
    final code = sortedRanks.join() + (suited ? 's' : '');
    return code; // ej: "AKs", "QJo", "TT"
  }

  /// Valor numérico de cada rango para comparación rápida
  static int _rankValue(String rank) {
    switch (rank) {
      case 'A':
        return 14;
      case 'K':
        return 13;
      case 'Q':
        return 12;
      case 'J':
        return 11;
      case 'T':
        return 10;
      default:
        return int.tryParse(rank) ?? 0;
    }
  }

  /// Estimación rápida de fuerza de la mano (solo para comparación relativa)
  static int handStrength(String code) {
    if (code.length < 2) return 0;
    // Suponemos que los primeros dos caracteres son las cartas
    final r1 = code[0];
    final r2 = code[1];
    return _rankValue(r1) + _rankValue(r2);
  }
}
