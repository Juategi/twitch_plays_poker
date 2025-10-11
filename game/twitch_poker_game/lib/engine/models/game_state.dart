import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/player.dart';

enum GameStage { idle, preflop, flop, turn, river, showdown }

enum WaitReason { none, waitingForHuman }

class GameState {
  final List<PlayerModel> players;
  final List<CardModel> community;
  final int pot;
  final int dealerIndex;
  final String stage; // idle, preflop, flop, turn, river, showdown
  final WaitReason waitReason;
  final int waitingPlayerIndex; // which player index is awaited (-1 if none)

  GameState({
    required this.players,
    required this.community,
    required this.pot,
    required this.dealerIndex,
    required this.stage,
    this.waitReason = WaitReason.none,
    this.waitingPlayerIndex = -1,
  });

  GameState copyWith({
    List<PlayerModel>? players,
    List<CardModel>? community,
    int? pot,
    int? dealerIndex,
    String? stage,
    WaitReason? waitReason,
    int? waitingPlayerIndex,
  }) {
    return GameState(
      players: players ?? this.players,
      community: community ?? this.community,
      pot: pot ?? this.pot,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      stage: stage ?? this.stage,
      waitReason: waitReason ?? this.waitReason,
      waitingPlayerIndex: waitingPlayerIndex ?? this.waitingPlayerIndex,
    );
  }
}
