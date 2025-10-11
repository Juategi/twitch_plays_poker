// lib/game/engine.dart
import 'dart:async';
import 'dart:math';
import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/deck.dart';
import 'package:twitch_poker_game/engine/models/hand.dart';

/// ----------------------
/// MonteCarlo worker for compute()
/// ----------------------
///
/// //TODO: refactor to implement PokerAIBase
class MCRequest {
  final List<CardModel> myHole;
  final List<CardModel> community;
  final int opponents;
  final int simulations;
  final List<CardModel> deckRest;
  MCRequest(
    this.myHole,
    this.community,
    this.opponents,
    this.simulations,
    this.deckRest,
  );
}

Future<double> mcWorker(MCRequest req) async {
  final rnd = Random();
  int wins = 0;
  final base = Deck.cards(List<CardModel>.from(req.deckRest));
  for (int i = 0; i < req.simulations; i++) {
    final deck = Deck.clone(base);
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
