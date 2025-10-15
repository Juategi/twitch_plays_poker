// lib/main.dart
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter/material.dart';
import 'package:twitch_poker_game/env.dart';
import 'package:twitch_poker_game/ui/poker_home.dart';

void main() {
  OpenAI.apiKey = Env.key1;
  OpenAI.showLogs = true;
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
