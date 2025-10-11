import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twitch_poker_game/engine/models/card.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({super.key, required this.card});
  final CardModel card;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Center(
        child: SvgPicture.asset(card.getAssetPath(), fit: BoxFit.fitWidth),
      ),
    );
  }
}
