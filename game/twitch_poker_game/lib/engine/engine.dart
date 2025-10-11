// lib/game/engine.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// ---------------------------
/// MODELO: cartas, baraja, evaluador
/// ---------------------------
enum Suit { clubs, diamonds, hearts, spades }

enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace,
}

class CardModel {
  final Suit suit;
  final Rank rank;
  const CardModel(this.suit, this.rank);

  int get rankValue => Rank.values.indexOf(rank) + 2;

  @override
  String toString() {
    const rankNames = [
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
      'A',
    ];
    const suitChars = {
      'clubs': '♣',
      'diamonds': '♦',
      'hearts': '♥',
      'spades': '♠',
    };
    return '${rankNames[rankValue - 2]}${suitChars[suit.name]}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardModel && other.suit == suit && other.rank == rank;

  @override
  int get hashCode => suit.hashCode ^ rank.hashCode;
}

class Deck {
  final List<CardModel> cards;
  Deck._(this.cards);
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
    return Deck._(rem);
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
      } else if (uniq[i] != uniq[i - 1])
        run = 1;
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

class GameState {
  final List<PlayerModel> players;
  final List<CardModel> community;
  final int pot;
  final int dealerIndex;
  final String stage; // 'idle','preflop','flop','turn','river','showdown'
  final bool aiBusy;

  GameState({
    required this.players,
    required this.community,
    required this.pot,
    required this.dealerIndex,
    required this.stage,
    this.aiBusy = false,
  });

  GameState copyWith({
    List<PlayerModel>? players,
    List<CardModel>? community,
    int? pot,
    int? dealerIndex,
    String? stage,
    bool? aiBusy,
  }) {
    return GameState(
      players: players ?? this.players,
      community: community ?? this.community,
      pot: pot ?? this.pot,
      dealerIndex: dealerIndex ?? this.dealerIndex,
      stage: stage ?? this.stage,
      aiBusy: aiBusy ?? this.aiBusy,
    );
  }
}

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
  final baseDeck = Deck._(List<CardModel>.from(req.deckRest));
  for (int i = 0; i < req.simulations; i++) {
    final deck = Deck.clone(baseDeck);
    deck.shuffle(rnd);
    final comm = List<CardModel>.from(req.community);
    while (comm.length < 5) comm.add(deck.draw());
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
           stage: 'idle',
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
    );
  }

  void startNewHand() {
    _deck = Deck.full();
    _deck.shuffle();
    _community = [];
    for (var p in players) p.clearForNewHand();
    // deal 2 cards each
    for (int i = 0; i < 2; i++) {
      for (var p in players) {
        if (p.stack > 0)
          p.hole.add(_deck.draw());
        else
          p.folded = true;
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
      stage: 'preflop',
      aiBusy: false,
    );
    _notify();
  }

  /// Request AI actions for current stage. This method runs MC per-AI in isolates
  /// and updates the game state when finished.
  Future<void> requestAIActionsForStage(String stage) async {
    _notify(aiBusy: true);
    final deckTemplate = Deck.full();
    // prepare deck rest once (remove all used)
    final used = <CardModel>{};
    used.addAll(_community);
    for (var p in players) used.addAll(p.hole);
    final deckRest = deckTemplate.without(used.toList()).cards;

    final futures = <Future<void>>[];
    for (var p in players) {
      if (p.isHuman || p.folded || p.allIn) continue;
      // compute toCall
      final currentBet = players
          .map((pl) => pl.contributed)
          .reduce((a, b) => max(a, b));
      final toCall = currentBet - p.contributed;
      final pot = players.fold<int>(0, (s, pl) => s + pl.contributed);
      final opponents = players.where((pl) => pl != p && !pl.folded).length - 1;
      final req = _MCRequest(
        List<CardModel>.from(p.hole),
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
          p.folded = true;
        } else if (eq < potOdds * 1.1) {
          final pay = min(p.stack, toCall);
          p.stack -= pay;
          p.contributed += pay;
          if (p.stack == 0) p.allIn = true;
        } else {
          // raise heuristic
          final raiseAmt = min(
            p.stack,
            max(bigBlind, toCall + (pot * 0.25).toInt()),
          );
          final pay = min(p.stack, raiseAmt);
          p.stack -= pay;
          p.contributed += pay;
          if (p.stack == 0) p.allIn = true;
        }
        _notify(aiBusy: true);
      });
      futures.add(f);
    }

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
    if (curr == 'preflop') {
      _deck.draw();
      _community.addAll(_deck.drawMultiple(3));
      notifier.value = notifier.value.copyWith(
        community: List.unmodifiable(_community),
        stage: 'flop',
      );
    } else if (curr == 'flop') {
      _deck.draw();
      _community.add(_deck.draw());
      notifier.value = notifier.value.copyWith(
        community: List.unmodifiable(_community),
        stage: 'turn',
      );
    } else if (curr == 'turn') {
      _deck.draw();
      _community.add(_deck.draw());
      notifier.value = notifier.value.copyWith(
        community: List.unmodifiable(_community),
        stage: 'river',
      );
    } else if (curr == 'river') {
      _handleShowdown();
      notifier.value = notifier.value.copyWith(stage: 'showdown');
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
        } else if (hv.compareTo(best) == 0)
          winners.add(c);
      }
      final share = amt ~/ winners.length;
      for (var w in winners) w.stack += share;
      final leftover = amt - share * winners.length;
      if (leftover > 0) winners.first.stack += leftover;
      prev = level;
    }
    for (var p in players) p.contributed = 0;
  }

  void rotateDealer() {
    _dealerIndex = (_dealerIndex + 1) % players.length;
    notifier.value = notifier.value.copyWith(dealerIndex: _dealerIndex);
    _notify();
  }
}
