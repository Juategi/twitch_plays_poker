import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/player.dart';

abstract class PokerAIBase {
  /// Devuelve la acción de la IA: "fold", "call", "raise"
  Future<String> decideAction({
    required PlayerModel player,
    required List<PlayerModel> opponents,
    required List<CardModel> community,
    required int currentBet,
    required int minRaise,
    required String stage,
    required int raisesSoFar,
    required int maxRaisesPerRound,
  });
}
