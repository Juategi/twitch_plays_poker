import 'dart:math';

import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/deck.dart';
import 'package:twitch_poker_game/engine/models/hand.dart';

class MonteCarloAI {
  final int simulations;
  final Random rnd;
  MonteCarloAI({required this.simulations, int? seed})
    : rnd = seed == null ? Random() : Random(seed);

  // Simple synchronous MC: devuelve probabilidad de ganar (vs n oponentes)
  double estimateWinProbability({
    required List<CardModel> myHole,
    required List<CardModel> community,
    required int opponents,
    required Deck deckTemplate,
  }) {
    final used = <CardModel>{...myHole, ...community};
    final base = deckTemplate.without(used.toList());
    int wins = 0;
    for (int i = 0; i < simulations; i++) {
      final deck = Deck.clone(base);
      deck.shuffle(rnd);
      final comm = List<CardModel>.from(community);
      while (comm.length < 5) comm.add(deck.draw());
      final myBest = HandEvaluator.bestHandFrom([...myHole, ...comm]);
      bool lost = false;
      for (int o = 0; o < opponents; o++) {
        final oppHole = [deck.draw(), deck.draw()];
        final oppBest = HandEvaluator.bestHandFrom([...oppHole, ...comm]);
        if (oppBest.compareTo(myBest) > 0) {
          lost = true;
          break;
        }
      }
      if (!lost) wins++;
    }
    return wins / simulations;
  }
}
