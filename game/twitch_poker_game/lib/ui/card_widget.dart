import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:twitch_poker_game/engine/models/card.dart';

class CardWidget extends StatelessWidget {
  const CardWidget({super.key, required this.card});
  final CardModel card;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green,
      width: 223 / 3,
      height: 324 / 3,
      child: Center(
        child: SvgPicture.asset(card.getAssetPath(), fit: BoxFit.fill),
      ),
    );
  }
}
