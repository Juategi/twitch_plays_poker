import 'dart:math';

import 'package:twitch_poker_game/engine/models/card.dart';

/// HandValue comparable
class HandValue implements Comparable<HandValue> {
  final int category;
  final List<int> tie;
  HandValue(this.category, this.tie);
  @override
  int compareTo(HandValue other) {
    if (category != other.category) return category.compareTo(other.category);
    for (var i = 0; i < tie.length && i < other.tie.length; i++) {
      if (tie[i] != other.tie[i]) return tie[i].compareTo(other.tie[i]);
    }
    return 0;
  }

  @override
  String toString() => 'Cat $category / ${tie.join(",")}';
}

class HandEvaluator {
  static HandValue bestHandFrom(List<CardModel> cards) {
    if (cards.length < 5) throw ArgumentError('Need at least 5 cards');
    final combos = _combinations(cards, 5);
    HandValue? best;
    for (var c in combos) {
      final hv = _evalFive(c);
      if (best == null || hv.compareTo(best) > 0) best = hv;
    }
    return best!;
  }

  static HandValue _evalFive(List<CardModel> c) {
    c.sort((a, b) => b.rankValue.compareTo(a.rankValue));
    final ranks = c.map((e) => e.rankValue).toList();
    final suits = c.map((e) => e.suit).toList();
    final isFlush = suits.toSet().length == 1;
    final straightHigh = _straightHigh(ranks);
    if (isFlush && straightHigh != null) return HandValue(9, [straightHigh]);
    for (var r in ranks.toSet()) {
      if (ranks.where((x) => x == r).length == 4) {
        final kicker = ranks.firstWhere((x) => x != r);
        return HandValue(8, [r, kicker]);
      }
    }
    final trips = ranks
        .where((r) => ranks.where((x) => x == r).length == 3)
        .toSet();
    final pairs = ranks
        .where((r) => ranks.where((x) => x == r).length == 2)
        .toSet();
    if (trips.isNotEmpty && (pairs.isNotEmpty || trips.length > 1)) {
      final trip = trips.reduce(max);
      final pair = pairs.isNotEmpty
          ? pairs.reduce(max)
          : trips.where((x) => x != trip).reduce(max);
      return HandValue(7, [trip, pair]);
    }
    if (isFlush) return HandValue(6, ranks);
    if (straightHigh != null) return HandValue(5, [straightHigh]);
    if (trips.isNotEmpty) {
      final trip = trips.reduce(max);
      final kickers = ranks.where((x) => x != trip).toList()
        ..sort((a, b) => b.compareTo(a));
      return HandValue(4, [trip, kickers[0], kickers[1]]);
    }
    final pairSet = ranks
        .where((r) => ranks.where((x) => x == r).length == 2)
        .toSet();
    if (pairSet.length >= 2) {
      final ps = pairSet.toList()..sort((a, b) => b.compareTo(a));
      final kicker = ranks.firstWhere((x) => !ps.contains(x));
      return HandValue(3, [ps[0], ps[1], kicker]);
    }
    if (pairSet.length == 1) {
      final p = pairSet.first;
      final kickers = ranks.where((x) => x != p).toList()
        ..sort((a, b) => b.compareTo(a));
      return HandValue(2, [p, kickers[0], kickers[1], kickers[2]]);
    }
    return HandValue(1, ranks);
  }

  static int? _straightHigh(List<int> ranks) {
    final uniq = ranks.toSet().toList()..sort();
    if (uniq.contains(14)) uniq.insert(0, 1);
    int run = 1;
    for (int i = 1; i < uniq.length; i++) {
      if (uniq[i] == uniq[i - 1] + 1) {
        run++;
        if (run >= 5) return uniq[i];
      } else if (uniq[i] != uniq[i - 1]) {
        run = 1;
      }
    }
    return null;
  }

  static List<List<T>> _combinations<T>(List<T> items, int k) {
    final res = <List<T>>[];
    void helper(int start, List<T> cur) {
      if (cur.length == k) {
        res.add(List<T>.from(cur));
        return;
      }
      for (int i = start; i <= items.length - (k - cur.length); i++) {
        cur.add(items[i]);
        helper(i + 1, cur);
        cur.removeLast();
      }
    }

    helper(0, []);
    return res;
  }
}
