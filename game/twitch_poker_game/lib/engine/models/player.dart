import 'package:twitch_poker_game/engine/ai/poker_ai_base.dart';
import 'package:twitch_poker_game/engine/models/card.dart';

/// ----------------------
/// Player & GameState
/// ----------------------
class PlayerModel {
  final String id;
  int stack;
  List<CardModel> hole = [];
  bool folded = false;
  bool allIn = false;
  int contributed = 0;
  double aggressiveness =
      0.8 + (0.4 * (DateTime.now().microsecond % 1000) / 1000);
  final bool isHuman;
  PokerAIBase? ai;
  PlayerModel(this.id, this.stack, {this.isHuman = false, this.ai});
  void clearForNewHand() {
    hole.clear();
    folded = false;
    allIn = false;
    contributed = 0;
  }

  @override
  String toString() =>
      '$id stack=$stack ${folded ? "(folded)" : ""} ${allIn ? "(allin)" : ""}';
}
