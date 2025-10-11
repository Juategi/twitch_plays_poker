import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/player';

enum GameStage { idle, preflop, flop, turn, river, showdown }

class GameState {
  final List<PlayerModel> players;
  final List<CardModel> community;
  final int pot;
  final int dealerIndex;
  final GameStage stage;
  final bool aiBusy;
  final PlayerModel? currentPlayer;

  GameState({
    required this.players,
    required this.community,
    required this.pot,
    required this.dealerIndex,
    required this.stage,
    this.aiBusy = false,
    this.currentPlayer,
  });

  GameState copyWith({
    List<PlayerModel>? players,
    List<CardModel>? community,
    int? pot,
    int? dealerIndex,
    GameStage? stage,
    bool? aiBusy,
    PlayerModel? currentPlayer,
  }) {
    return GameState(
      players: players ?? this.players,
      community: community ?? this.community,
      pot: pot ?? this.pot,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      stage: stage ?? this.stage,
      aiBusy: aiBusy ?? this.aiBusy,
      currentPlayer: currentPlayer ?? this.currentPlayer,
    );
  }
}
