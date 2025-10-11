// lib/game/engine.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/deck.dart';
import 'package:twitch_poker_game/engine/models/game_state.dart';
import 'package:twitch_poker_game/engine/models/hand.dart';
import 'package:twitch_poker_game/engine/models/player';

/// ---------------------------
/// MONTE CARLO (run in isolate via compute)
/// ---------------------------

/// Payload for isolate
class _MCRequest {
  final List<CardModel> myHole;
  final List<CardModel> community;
  final int opponents;
  final int simulations;
  final List<CardModel> deckRest; // remaining deck
  _MCRequest(
    this.myHole,
    this.community,
    this.opponents,
    this.simulations,
    this.deckRest,
  );
}

/// Top-level function for compute()
Future<double> _mcWorker(_MCRequest req) async {
  final rnd = Random();
  int wins = 0;
  final baseDeck = Deck.cards(List<CardModel>.from(req.deckRest));
  for (int i = 0; i < req.simulations; i++) {
    final deck = Deck.clone(baseDeck);
    deck.shuffle(rnd);
    final comm = List<CardModel>.from(req.community);
    while (comm.length < 5) {
      comm.add(deck.draw());
    }
    final myBest = HandEvaluator.bestHandFrom([...req.myHole, ...comm]);
    bool lost = false;
    for (int o = 0; o < req.opponents; o++) {
      final oppHole = [deck.draw(), deck.draw()];
      final oppBest = HandEvaluator.bestHandFrom([...oppHole, ...comm]);
      if (oppBest.compareTo(myBest) > 0) {
        lost = true;
        break;
      }
    }
    if (!lost) wins++;
  }
  return wins / req.simulations;
}

/// ---------------------------
/// GAME CONTROLLER (Flutter-ready)
/// ---------------------------
class GameController {
  final List<PlayerModel> players;
  final int smallBlind;
  final int bigBlind;
  final int mcSimulations;
  final ValueNotifier<GameState> notifier;
  late Deck _deck;
  List<CardModel> _community = [];
  int _dealerIndex = 0;

  GameController({
    required this.players,
    this.smallBlind = 10,
    this.bigBlind = 20,
    this.mcSimulations = 1000,
  }) : notifier = ValueNotifier(
         GameState(
           players: players,
           community: [],
           pot: 0,
           dealerIndex: 0,
           stage: GameStage.idle,
           currentPlayer: players[3],
         ),
       ) {
    _deck = Deck.full();
  }

  GameState get state => notifier.value;

  void _notify({bool aiBusy = false}) {
    final pot = players.fold<int>(0, (s, p) => s + p.contributed);
    notifier.value = state.copyWith(
      players: players,
      community: List.unmodifiable(_community),
      pot: pot,
      dealerIndex: _dealerIndex,
      aiBusy: aiBusy,
      currentPlayer: state.currentPlayer,
    );
  }

  void startNewHand() {
    _deck = Deck.full();
    _deck.shuffle();
    _community = [];
    for (var p in players) {
      p.clearForNewHand();
    }
    // deal 2 cards each
    for (int i = 0; i < 2; i++) {
      for (var p in players) {
        if (p.stack > 0) {
          p.hole.add(_deck.draw());
        } else {
          p.folded = true;
        }
      }
    }
    // post blinds
    final sbIdx = (_dealerIndex + 1) % players.length;
    final bbIdx = (_dealerIndex + 2) % players.length;
    final sb = players[sbIdx];
    final bb = players[bbIdx];
    final sbAmt = min(sb.stack, smallBlind);
    sb.stack -= sbAmt;
    sb.contributed += sbAmt;
    final bbAmt = min(bb.stack, bigBlind);
    bb.stack -= bbAmt;
    bb.contributed += bbAmt;
    notifier.value = GameState(
      players: players,
      community: _community,
      pot: sbAmt + bbAmt,
      dealerIndex: _dealerIndex,
      stage: GameStage.preflop,
      aiBusy: false,
    );
    _notify();
  }

  /// Request AI actions for current stage. This method runs MC per-AI in isolates
  /// and updates the game state when finished.
  Future<void> requestAIActionsForStage(GameStage stage) async {
    _notify(aiBusy: true);
    final deckTemplate = Deck.full();
    // prepare deck rest once (remove all used)
    final used = <CardModel>{};
    used.addAll(_community);
    for (var p in players) {
      used.addAll(p.hole);
    }
    final deckRest = deckTemplate.without(used.toList()).cards;

    final futures = <Future<void>>[];
    PlayerModel player = state.currentPlayer!;
    if (player.isHuman || player.folded || player.allIn) return;
    // compute toCall
    final currentBet = players
        .map((pl) => pl.contributed)
        .reduce((a, b) => max(a, b));
    final toCall = currentBet - player.contributed;
    final pot = players.fold<int>(0, (s, pl) => s + pl.contributed);
    final opponents =
        players.where((pl) => pl != player && !pl.folded).length - 1;
    final req = _MCRequest(
      List<CardModel>.from(player.hole),
      List<CardModel>.from(_community),
      max(0, opponents),
      mcSimulations,
      deckRest,
    );

    // For each AI, spawn compute task and then decide action when done
    final f = compute<_MCRequest, double>(_mcWorker, req).then((eq) {
      // potOdds
      final potOdds = toCall == 0 ? 0.0 : toCall / (pot + toCall);
      // equilibrado heuristics (same idea as CLI version but simpler)
      if (eq < potOdds * 0.9) {
        player.folded = true;
      } else if (eq < potOdds * 1.1) {
        final pay = min(player.stack, toCall);
        player.stack -= pay;
        player.contributed += pay;
        if (player.stack == 0) player.allIn = true;
      } else {
        // raise heuristic
        final raiseAmt = min(
          player.stack,
          max(bigBlind, toCall + (pot * 0.25).toInt()),
        );
        final pay = min(player.stack, raiseAmt);
        player.stack -= pay;
        player.contributed += pay;
        if (player.stack == 0) player.allIn = true;
      }
      _notify(aiBusy: true);
    });
    futures.add(f);

    await Future.wait(futures);
    _notify(aiBusy: false);
  }

  // Human actions (UI will call these)
  void humanFold(PlayerModel human) {
    human.folded = true;
    _notify();
  }

  void humanCheck(PlayerModel human) {
    final currentBet = players
        .map((pl) => pl.contributed)
        .reduce((a, b) => max(a, b));
    final toCall = currentBet - human.contributed;
    if (toCall == 0) {
      /* check valid */
    } else {
      final pay = min(human.stack, toCall);
      human.stack -= pay;
      human.contributed += pay;
      if (human.stack == 0) human.allIn = true;
    }
    _notify();
  }

  void humanCall(PlayerModel human) {
    final currentBet = players
        .map((pl) => pl.contributed)
        .reduce((a, b) => max(a, b));
    final toCall = currentBet - human.contributed;
    final pay = min(human.stack, toCall);
    human.stack -= pay;
    human.contributed += pay;
    if (human.stack == 0) human.allIn = true;
    _notify();
  }

  void humanRaise(PlayerModel human, int raiseAmount) {
    final currentBet = players
        .map((pl) => pl.contributed)
        .reduce((a, b) => max(a, b));
    final toCall = currentBet - human.contributed;
    final desired = max(toCall + raiseAmount, toCall + bigBlind);
    final pay = min(human.stack, desired);
    human.stack -= pay;
    human.contributed += pay;
    if (human.stack == 0) human.allIn = true;
    _notify();
  }

  void humanAllIn(PlayerModel human) {
    final pay = human.stack;
    human.contributed += pay;
    human.stack = 0;
    human.allIn = true;
    _notify();
  }

  /// Advance stage: flop/turn/river/showdown (UI controls flow)
  void advanceStage() {
    final curr = notifier.value.stage;
    if (curr == GameStage.preflop) {
      _deck.draw();
      _community.addAll(_deck.drawMultiple(3));
      notifier.value = notifier.value.copyWith(
        community: List.unmodifiable(_community),
        stage: GameStage.flop,
      );
    } else if (curr == GameStage.flop) {
      _deck.draw();
      _community.add(_deck.draw());
      notifier.value = notifier.value.copyWith(
        community: List.unmodifiable(_community),
        stage: GameStage.turn,
      );
    } else if (curr == GameStage.turn) {
      _deck.draw();
      _community.add(_deck.draw());
      notifier.value = notifier.value.copyWith(
        community: List.unmodifiable(_community),
        stage: GameStage.river,
      );
    } else if (curr == GameStage.river) {
      _handleShowdown();
      notifier.value = notifier.value.copyWith(stage: GameStage.showdown);
    }
    _notify();
  }

  void _handleShowdown() {
    final contributed = {for (var p in players) p: p.contributed};
    final levels = contributed.values.toSet().toList()..sort();
    int prev = 0;
    for (var level in levels) {
      final participants = contributed.keys
          .where((p) => contributed[p]! >= level)
          .toList();
      final amt = (level - prev) * participants.length;
      if (amt <= 0) continue;
      final contenders = participants.where((p) => !p.folded).toList();
      if (contenders.isEmpty) {
        prev = level;
        continue;
      }
      HandValue? best;
      final winners = <PlayerModel>[];
      for (var c in contenders) {
        final hv = HandEvaluator.bestHandFrom([...c.hole, ..._community]);
        if (best == null || hv.compareTo(best) > 0) {
          best = hv;
          winners.clear();
          winners.add(c);
        } else if (hv.compareTo(best) == 0) {
          winners.add(c);
        }
      }
      final share = amt ~/ winners.length;
      for (var w in winners) {
        w.stack += share;
      }
      final leftover = amt - share * winners.length;
      if (leftover > 0) winners.first.stack += leftover;
      prev = level;
    }
    for (var p in players) {
      p.contributed = 0;
    }
  }

  void rotateDealer() {
    _dealerIndex = (_dealerIndex + 1) % players.length;
    notifier.value = notifier.value.copyWith(dealerIndex: _dealerIndex);
    _notify();
  }
}
