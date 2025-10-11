import 'dart:math';

import 'package:twitch_poker_game/engine/models/card.dart';

class Deck {
  final List<CardModel> cards;
  Deck.cards(this.cards);
  Deck.full()
    : cards = [
        for (var s in Suit.values)
          for (var r in Rank.values) CardModel(s, r),
      ];
  Deck.clone(Deck other) : cards = List<CardModel>.from(other.cards);
  CardModel draw() {
    if (cards.isEmpty) throw StateError('Deck empty');
    return cards.removeLast();
  }

  List<CardModel> drawMultiple(int n) => List.generate(n, (_) => draw());
  Deck without(List<CardModel> used) {
    final rem = cards.where((c) => !used.contains(c)).toList();
    return Deck.cards(rem);
  }

  void shuffle([Random? rnd]) {
    final random = rnd ?? Random();
    for (int i = cards.length - 1; i > 0; i--) {
      int j = random.nextInt(i + 1);
      final temp = cards[i];
      cards[i] = cards[j];
      cards[j] = temp;
    }
  }
}
