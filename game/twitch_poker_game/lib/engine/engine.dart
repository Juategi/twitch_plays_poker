// lib/game/engine.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:twitch_poker_game/engine/mc_request.dart';
import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/deck.dart';
import 'package:twitch_poker_game/engine/models/game_state.dart';
import 'package:twitch_poker_game/engine/models/hand.dart';
import 'package:twitch_poker_game/engine/models/player.dart';

/// ----------------------
/// GameController: automatic flow, pauses for human turn
/// ----------------------
class GameController {
  final List<PlayerModel> players;
  final int smallBlind;
  final int bigBlind;
  final int mcSimulations;
  final ValueNotifier<GameState> notifier;
  late Deck _deck;
  List<CardModel> _community = [];
  int _dealerIndex = 0;

  // internal completer used to pause until human acts
  Completer<void>? _humanActionCompleter;
  int _humanIndexWaiting = -1;
  int currentTurnIndex = -1; // -1 = nadie, 0..n = jugador activo

  GameController({
    required this.players,
    this.smallBlind = 10,
    this.bigBlind = 20,
    this.mcSimulations = 2000,
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

  void _notify({
    WaitReason waitReason = WaitReason.none,
    int waitingPlayerIndex = -1,
  }) {
    final pot = players.fold<int>(0, (s, p) => s + p.contributed);
    notifier.value = state.copyWith(
      players: players,
      community: List.unmodifiable(_community),
      pot: pot,
      dealerIndex: _dealerIndex,
      waitReason: waitReason,
      waitingPlayerIndex: waitingPlayerIndex,
    );
  }

  /// Public API: start a full hand and run the automatic flow.
  /// The future completes when the hand ends (showdown distributed).
  Future<void> startHandAndAutoFlow() async {
    _rotateDealer();
    _deck = Deck.full()..shuffle();
    _community = [];
    for (var p in players) p.clearForNewHand();

    // deal
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

    _notify();
    // preflop betting
    await _bettingRoundAuto(((_dealerIndex + 3) % players.length), 'preflop');

    // if single winner, end early
    if (_onlyOneRemaining()) {
      _awardUncontested();
      _endHand();
      return;
    }

    // flop
    _deck.draw();
    _community.addAll(_deck.drawMultiple(3));
    _notify();
    await _bettingRoundAuto(((_dealerIndex + 1) % players.length), 'flop');
    if (_onlyOneRemaining()) {
      _awardUncontested();
      _endHand();
      return;
    }

    // turn
    _deck.draw();
    _community.add(_deck.draw());
    _notify();
    await _bettingRoundAuto(((_dealerIndex + 1) % players.length), 'turn');
    if (_onlyOneRemaining()) {
      _awardUncontested();
      _endHand();
      return;
    }

    // river
    _deck.draw();
    _community.add(_deck.draw());
    _notify();
    await _bettingRoundAuto(((_dealerIndex + 1) % players.length), 'river');
    // showdown
    _handleShowdown();
    _endHand();
  }

  bool _onlyOneRemaining() {
    return players.where((p) => !p.folded).length == 1;
  }

  void _awardUncontested() {
    final winner = players.firstWhere((p) => !p.folded);
    final pot = players.fold<int>(0, (s, p) => s + p.contributed);
    winner.stack += pot;
    for (var p in players) p.contributed = 0;
    _notify();
  }

  void _endHand() {
    _dealerIndex = (_dealerIndex + 1) % players.length;
    _notify();
  }

  Future<void> _bettingRoundAuto(int starterIndex, String stage) async {
    int currentBet = players
        .map((p) => p.contributed)
        .reduce((a, b) => max(a, b));
    final int minRaise = bigBlind;
    int idx = starterIndex;
    int lastToAct = (starterIndex - 1) % players.length;
    if (lastToAct < 0) lastToAct += players.length;

    bool finished = false;
    final int maxIterations = 1000;
    int iterations = 0;

    // NEW: control de raises por ronda
    int raisesSoFar = 0;
    const int maxRaisesPerRound =
        3; // límite razonable para evitar bonkers-raises

    while (!finished && iterations < maxIterations) {
      iterations++;
      final p = players[idx];

      if (!p.folded && !p.allIn && p.stack > 0) {
        final toCall = currentBet - p.contributed;
        currentTurnIndex = idx;
        _notify();
        if (p.isHuman) {
          // Pause for human action
          _humanIndexWaiting = idx;
          _humanActionCompleter = Completer<void>();
          _notify(
            waitReason: WaitReason.waitingForHuman,
            waitingPlayerIndex: idx,
          );
          await _humanActionCompleter!.future;
          _humanActionCompleter = null;
          _humanIndexWaiting = -1;
          // recalc currentBet after human action
          currentBet = players
              .map((pl) => pl.contributed)
              .reduce((a, b) => max(a, b));
          _notify();
        } else {
          // AI auto-decide and act, but pass raisesSoFar and max limit
          final rnd = Random();
          final delaySeconds = 3 + rnd.nextInt(3); // 3, 4 o 5 segundos
          await Future.delayed(Duration(seconds: delaySeconds));

          final prevBet = currentBet;
          await _aiActForPlayer(
            p,
            toCall,
            currentBet,
            minRaise,
            stage,
            raisesSoFar,
            maxRaisesPerRound,
          );
          // recalc currentBet and update raises counter if it increased
          final newBet = players
              .map((pl) => pl.contributed)
              .reduce((a, b) => max(a, b));
          if (newBet > prevBet) {
            raisesSoFar++;
            // update lastToAct so that the raiser gets action cycle respected
            lastToAct = (idx - 1) % players.length;
            if (lastToAct < 0) lastToAct += players.length;
          }
          currentBet = newBet;
          _notify();
        }
      }

      // termination checks:
      final activeAlive = players
          .where((pl) => !pl.folded && !pl.allIn && pl.stack > 0)
          .toList();
      if (activeAlive.isEmpty) {
        finished = true;
        break;
      }

      // ✅ Nueva lógica de fin de ronda
      final everyoneMatched = players
          .where((pl) => !pl.folded)
          .every((pl) => pl.allIn || pl.contributed == currentBet);

      // Si todos igualaron pero aún no hemos pasado por el último que puede actuar, seguimos
      if (everyoneMatched && idx == lastToAct) {
        finished = true;
        break;
      }

      idx = (idx + 1) % players.length;
    }
  }

  Future<void> _aiActForPlayer(
    PlayerModel p,
    int toCall,
    int currentBet,
    int minRaise,
    String stage,
    int raisesSoFar,
    int maxRaisesPerRound,
  ) async {
    // Prepare deck rest
    final used = <CardModel>{..._community};
    for (var pl in players) used.addAll(pl.hole);
    final deckRest = Deck.full().without(used.toList()).cards;

    final opponents = players.where((pl) => pl != p && !pl.folded).length - 1;
    final req = MCRequest(
      List<CardModel>.from(p.hole),
      List<CardModel>.from(_community),
      max(0, opponents),
      mcSimulations,
      deckRest,
    );

    // Run compute (isolate)
    final equity = await compute<MCRequest, double>(mcWorker, req);

    // Pot odds
    final pot = players.fold<int>(0, (s, pl) => s + pl.contributed);
    final potOdds = toCall == 0 ? 0.0 : toCall / (pot + toCall);

    // Stage-aware aggression modifier
    double stageAgg;
    switch (stage) {
      case 'preflop':
        stageAgg = 0.6;
        break;
      case 'flop':
        stageAgg = 1.0;
        break;
      case 'turn':
        stageAgg = 1.1;
        break;
      case 'river':
        stageAgg = 1.2;
        break;
      default:
        stageAgg = 1.0;
    }

    // Add slight random jitter to equity so AIs don't mirror each other exactly
    final rnd = Random();
    final jitter = (rnd.nextDouble() * 0.06) - 0.03; // ±3%
    final adjEquity = (equity + jitter).clamp(0.0, 1.0);

    // Decision thresholds (equilibrado) and respect max raises
    stageAgg = stageAgg * p.aggressiveness;
    final foldThresh = (potOdds * 0.9) / stageAgg;
    final callThresh = (potOdds * 1.1) / stageAgg;
    final raiseThresh = (stage == 'preflop') ? 0.65 : 0.45 * stageAgg;

    // If we already hit raise cap, disallow further raises and prefer call/fold
    final canRaise = raisesSoFar < maxRaisesPerRound;

    if (adjEquity < foldThresh) {
      // fold
      p.folded = true;
      return;
    }

    if (adjEquity < callThresh) {
      // call (or check if toCall==0)
      if (toCall == 0) {
        // check - do nothing
        return;
      } else {
        final pay = min(p.stack, toCall);
        p.stack -= pay;
        p.contributed += pay;
        if (p.stack == 0) p.allIn = true;
        return;
      }
    }

    // adjEquity >= callThresh: consider raise if allowed
    if (canRaise && adjEquity >= raiseThresh) {
      // perform raise but ensure it actually increases the currentBet
      final desiredRaise = max(toCall + minRaise, (pot * 0.25).toInt());
      final pay = min(p.stack, desiredRaise);
      final newContrib = p.contributed + pay;
      if (newContrib > currentBet) {
        p.stack -= pay;
        p.contributed += pay;
        if (p.stack == 0) p.allIn = true;
        return;
      } else {
        // raise did not increase currentBet (possible when other players already higher) -> act as call
        final callPay = min(p.stack, toCall);
        p.stack -= callPay;
        p.contributed += callPay;
        if (p.stack == 0) p.allIn = true;
        return;
      }
    } else {
      // either not allowed to raise or equity not enough => call or check
      if (toCall == 0) {
        // check
        return;
      } else {
        final pay = min(p.stack, toCall);
        p.stack -= pay;
        p.contributed += pay;
        if (p.stack == 0) p.allIn = true;
        return;
      }
    }
  }

  // Human action APIs — these update state and complete the waiting completer so flow resumes.
  // All amounts are "pay now" (for raises, pass desired extra amount)
  void humanFold(int humanIndex) {
    final h = players[humanIndex];
    h.folded = true;
    _notify();
    _completeHuman();
  }

  void humanCheckOrCall(int humanIndex) {
    final currentBet = players
        .map((pl) => pl.contributed)
        .reduce((a, b) => max(a, b));
    final h = players[humanIndex];
    final toCall = currentBet - h.contributed;
    if (toCall == 0) {
      // check
    } else {
      final pay = min(h.stack, toCall);
      h.stack -= pay;
      h.contributed += pay;
      if (h.stack == 0) h.allIn = true;
    }
    _notify();
    _completeHuman();
  }

  void humanRaise(int humanIndex, int extraRaiseAmount) {
    final currentBet = players
        .map((pl) => pl.contributed)
        .reduce((a, b) => max(a, b));
    final h = players[humanIndex];
    final toCall = currentBet - h.contributed;
    final desired = max(toCall + extraRaiseAmount, toCall + bigBlind);
    final pay = min(h.stack, desired);
    h.stack -= pay;
    h.contributed += pay;
    if (h.stack == 0) h.allIn = true;
    _notify();
    _completeHuman();
  }

  void humanAllIn(int humanIndex) {
    final h = players[humanIndex];
    final pay = h.stack;
    h.contributed += pay;
    h.stack = 0;
    h.allIn = true;
    _notify();
    _completeHuman();
  }

  void _completeHuman() {
    if (_humanActionCompleter != null && !_humanActionCompleter!.isCompleted) {
      _humanActionCompleter!.complete();
    }
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
    removeBustedPlayers();
    _notify();
  }

  // small helper to get index of human (assumes exactly one human)
  int humanIndex() {
    for (int i = 0; i < players.length; i++) if (players[i].isHuman) return i;
    return -1;
  }

  void removeBustedPlayers() {
    players.removeWhere((p) => p.stack <= 0);
  }

  void _rotateDealer() {
    _dealerIndex = (_dealerIndex + 1) % players.length;
    notifier.value = notifier.value.copyWith(dealerIndex: _dealerIndex);
    _notify();
  }
}
