// lib/main.dart
import 'package:flutter/material.dart';
import 'package:twitch_poker_game/engine/engine.dart';
import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/game_state.dart';
import 'package:twitch_poker_game/engine/models/player.dart';

void main() {
  runApp(const PokerApp());
}

class PokerApp extends StatelessWidget {
  const PokerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Texas AI (MC) - Flutter Ready',
      theme: ThemeData.dark(),
      home: const PokerHome(),
    );
  }
}

class PokerHome extends StatefulWidget {
  const PokerHome({super.key});
  @override
  State<PokerHome> createState() => _PokerHomeState();
}

class _PokerHomeState extends State<PokerHome> {
  late GameController controller;
  @override
  void initState() {
    super.initState();
    final players = <PlayerModel>[
      PlayerModel('You', 2000, isHuman: true),
      PlayerModel('AI_1', 2000),
      PlayerModel('AI_2', 2000),
      PlayerModel('AI_3', 2000),
    ];
    controller = GameController(
      players: players,
      smallBlind: 10,
      bigBlind: 20,
      mcSimulations: 1000,
    );
    controller.notifier.value = controller.notifier.value.copyWith(
      stage: GameStage.idle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Texas Hold\'em — AI MonteCarlo (Flutter)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ValueListenableBuilder<GameState>(
          valueListenable: controller.notifier,
          builder: (context, gs, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text(
                          'Stage: ${gs.stage}   Pot: ${gs.pot}   Dealer: ${gs.dealerIndex}',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: gs.community
                              .map((c) => _cardWidget(c))
                              .toList(),
                        ),
                        if (gs.aiBusy)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 8),
                                Text('AI thinking...'),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: gs.players
                        .map(
                          (p) => ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                p.id.contains('You')
                                    ? 'Y'
                                    : p.id.split('_').last,
                              ),
                            ),
                            title: Text('${p.id} — stack: ${p.stack}'),
                            subtitle: Text(
                              'contrib: ${p.contributed} ${p.folded ? "(folded)" : ""} ${p.allIn ? "(all-in)" : ""}',
                            ),
                            trailing: p.isHuman
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () =>
                                            controller.humanFold(p),
                                        child: const Text('Fold'),
                                      ),
                                      const SizedBox(width: 6),
                                      ElevatedButton(
                                        onPressed: () =>
                                            controller.humanCheck(p),
                                        child: const Text('Check'),
                                      ),
                                      const SizedBox(width: 6),
                                      ElevatedButton(
                                        onPressed: () =>
                                            controller.humanCall(p),
                                        child: const Text('Call'),
                                      ),
                                      const SizedBox(width: 6),
                                      ElevatedButton(
                                        onPressed: () =>
                                            controller.humanAllIn(p),
                                        child: const Text('All-in'),
                                      ),
                                      const SizedBox(width: 6),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: p.hole
                                            .map((c) => _cardWidget(c))
                                            .toList(),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: p.hole
                                        .map((c) => _cardWidget(c))
                                        .toList(),
                                  ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => controller.startNewHand(),
                      child: const Text('Start Hand'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await controller.requestAIActionsForStage(
                          controller.state.stage,
                        );
                      },
                      child: const Text('Run AI Actions'),
                    ),
                    ElevatedButton(
                      onPressed: () => controller.advanceStage(),
                      child: const Text('Advance Stage'),
                    ),
                    ElevatedButton(
                      onPressed: () => controller.rotateDealer(),
                      child: const Text('Rotate Dealer'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Workflow: Start Hand → Run AI Actions → Advance Stage (flop/turn/river)',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _cardWidget(CardModel c) {
    // Aquí mostramos texto por defecto. Para usar imágenes, reemplaza este widget por Image.asset(...)
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: Colors.green[700],
      ),
      child: Text(
        c.toString(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}
