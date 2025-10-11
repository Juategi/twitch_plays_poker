// lib/main.dart
import 'package:flutter/material.dart';
import 'package:twitch_poker_game/engine/ai/poker_ai_mini_cfr.dart';
import 'package:twitch_poker_game/engine/engine.dart';
import 'package:twitch_poker_game/engine/models/card.dart';
import 'package:twitch_poker_game/engine/models/game_state.dart';
import 'package:twitch_poker_game/engine/models/player.dart';
import 'package:twitch_poker_game/ui/card_widget.dart';

void main() {
  runApp(const PokerApp());
}

class PokerApp extends StatelessWidget {
  const PokerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Texas Auto Flow (Flutter)',
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
  bool handRunning = false;

  @override
  void initState() {
    super.initState();
    final players = <PlayerModel>[
      PlayerModel('You', 2000, isHuman: true),
      PlayerModel('AI_1', 2000, ai: PokerAIMiniCFR(style: PlayerStyle.tight)),
      PlayerModel('AI_2', 2000, ai: PokerAIMiniCFR(style: PlayerStyle.loose)),
      PlayerModel(
        'AI_3',
        2000,
        ai: PokerAIMiniCFR(style: PlayerStyle.aggressive),
      ),
    ];
    controller = GameController(
      players: players,
      smallBlind: 10,
      bigBlind: 20,
      mcSimulations: 1000,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Texas Hold\'em — Auto Flow (MC AI)')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ValueListenableBuilder<GameState>(
          valueListenable: controller.notifier,
          builder: (context, gs, _) {
            final humanIdx = controller.humanIndex();
            final waitingHuman =
                gs.waitReason == WaitReason.waitingForHuman &&
                gs.waitingPlayerIndex == humanIdx;
            return Column(
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
                              .map((c) => CardWidget(card: c))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        if (gs.waitReason == WaitReason.waitingForHuman)
                          Text(
                            'Waiting for human action...',
                            style: const TextStyle(color: Colors.amber),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: gs.players.asMap().entries.map((e) {
                      final idx = e.key;
                      final p = e.value;
                      return Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: controller.currentTurnIndex == idx
                                ? Colors.green
                                : null,
                            child: Text(p.isHuman ? 'Y' : p.id.split('_').last),
                          ),
                          Column(
                            children: [
                              Text('${p.id} — stack ${p.stack}'),
                              Text(
                                'contrib ${p.contributed} ${p.folded ? "(folded)" : ""} ${p.allIn ? "(all-in)" : ""}',
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (p.isHuman)
                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: waitingHuman
                                          ? () => controller.humanFold(idx)
                                          : null,
                                      child: const Text('Fold'),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      onPressed: waitingHuman
                                          ? () =>
                                                controller.humanCheckOrCall(idx)
                                          : null,
                                      child: const Text('Call/Check'),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      onPressed: waitingHuman
                                          ? () => _onRaisePressed(idx)
                                          : null,
                                      child: const Text('Raise'),
                                    ),
                                    const SizedBox(width: 6),
                                    ElevatedButton(
                                      onPressed: waitingHuman
                                          ? () => controller.humanAllIn(idx)
                                          : null,
                                      child: const Text('All-in'),
                                    ),
                                  ],
                                ),

                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: p.hole
                                    .map((c) => CardWidget(card: c))
                                    .toList(),
                              ),
                            ],
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: handRunning
                          ? null
                          : () async {
                              handRunning = true;
                              setState(() {});
                              await controller.startHandAndAutoFlow();
                              handRunning = false;
                              setState(() {});
                            },
                      child: const Text('Start Hand (Auto Flow)'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'The engine runs until it needs YOUR decision; press the action buttons to continue.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onRaisePressed(int humanIndex) async {
    final input = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final ctrl = TextEditingController(text: '50');
        return AlertDialog(
          title: const Text('Raise amount (chips to add)'),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(ctx).pop(int.tryParse(ctrl.text) ?? 0),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (input != null && input > 0) {
      controller.humanRaise(humanIndex, input);
    }
  }
}
