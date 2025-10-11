import 'package:twitch_poker_game/engine/models/card.dart';

/// ---------------------------
/// MODELO DE JUGADOR Y ESTADO
/// ---------------------------
class PlayerModel {
  final String id;
  int stack;
  List<CardModel> hole = [];
  bool folded = false;
  bool allIn = false;
  int contributed = 0;
  final bool isHuman;
  PlayerModel(this.id, this.stack, {this.isHuman = false});

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
