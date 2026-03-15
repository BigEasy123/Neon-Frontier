import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/neon_frontier_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeonFrontierApp());
}

class NeonFrontierApp extends StatelessWidget {
  const NeonFrontierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Frontier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF06060A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8A7CFF),
          secondary: Color(0xFF2EF2FF),
          surface: Color(0xFF0B0B12),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: GameWidget(
            game: NeonFrontierGame(),
          ),
        ),
      ),
    );
  }
}

