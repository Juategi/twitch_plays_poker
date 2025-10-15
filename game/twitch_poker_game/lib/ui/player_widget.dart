import 'package:flutter/material.dart';
import 'package:twitch_poker_game/engine/engine.dart';
import 'package:twitch_poker_game/engine/models/player.dart';
import 'package:twitch_poker_game/ui/card_widget.dart';

class PlayerWidget extends StatelessWidget {
  const PlayerWidget({
    super.key,
    required this.idx,
    required this.player,
    required this.controller,
  });
  final int idx;
  final PlayerModel player;
  final GameController controller;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          spacing: 8,
          mainAxisSize: MainAxisSize.min,
          children: player.hole.map((c) => CardWidget(card: c)).toList(),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: controller.currentTurnIndex == idx
                  ? Colors.green
                  : null,
              child: Text(player.isHuman ? 'Y' : player.id.split('_').last),
            ),
            Column(
              children: [
                Text('${player.id} — stack ${player.stack}'),
                Text(
                  'contrib ${player.contributed} ${player.folded ? "(folded)" : ""} ${player.allIn ? "(all-in)" : ""}',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
