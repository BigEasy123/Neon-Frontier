import 'dart:math' as math;
import 'dart:ui' as ui;

class LevelTheme {
  const LevelTheme({
    required this.level,
    required this.seed,
    required this.name,
    required this.background,
    required this.palette,
    required this.blobSpeedScale,
    required this.blobWobbleScale,
    required this.backgroundGlowAlpha,
    required this.territoryAlpha,
    required this.territoryGlowAlpha,
    required this.flashAmount,
  });

  final int level;
  final int seed;
  final String name;
  final ui.Color background;
  final List<ui.Color> palette;
  final double blobSpeedScale;
  final double blobWobbleScale;
  final double backgroundGlowAlpha;
  final double territoryAlpha;
  final double territoryGlowAlpha;
  final double flashAmount;
}

class LevelThemeGenerator {
  static LevelTheme fromLevel(int level) {
    final clampedLevel = level < 1 ? 1 : level;
    final seed = clampedLevel * 7919 + 37;
    final rng = math.Random(seed);
    final family = clampedLevel % 3;

    switch (family) {
      // Neon pulse: flashier electric look.
      case 1:
        return LevelTheme(
          level: clampedLevel,
          seed: seed,
          name: 'Neon Pulse',
          background: const ui.Color(0xFF07070C),
          palette: const <ui.Color>[
            ui.Color(0xFF2EF2FF),
            ui.Color(0xFF8A7CFF),
            ui.Color(0xFFFF4FD8),
            ui.Color(0xFFFFE066),
            ui.Color(0xFF72FFBF),
          ],
          blobSpeedScale: 1.20 + rng.nextDouble() * 0.25,
          blobWobbleScale: 1.05 + rng.nextDouble() * 0.20,
          backgroundGlowAlpha: 0.58,
          territoryAlpha: 0.28,
          territoryGlowAlpha: 0.25,
          flashAmount: 0.26,
        );
      // Aqua drift: smooth water-like flow.
      case 2:
        return LevelTheme(
          level: clampedLevel,
          seed: seed,
          name: 'Aqua Drift',
          background: const ui.Color(0xFF041019),
          palette: const <ui.Color>[
            ui.Color(0xFF69D2FF),
            ui.Color(0xFF1AA5FF),
            ui.Color(0xFF4EF4D8),
            ui.Color(0xFF97B8FF),
            ui.Color(0xFFB2F1FF),
          ],
          blobSpeedScale: 0.72 + rng.nextDouble() * 0.20,
          blobWobbleScale: 0.90 + rng.nextDouble() * 0.12,
          backgroundGlowAlpha: 0.46,
          territoryAlpha: 0.31,
          territoryGlowAlpha: 0.16,
          flashAmount: 0.06,
        );
      // Lava lamp: warm, syrupy movement.
      default:
        return LevelTheme(
          level: clampedLevel,
          seed: seed,
          name: 'Lava Bloom',
          background: const ui.Color(0xFF13070A),
          palette: const <ui.Color>[
            ui.Color(0xFFFF7A45),
            ui.Color(0xFFFF4FD8),
            ui.Color(0xFFFFB84D),
            ui.Color(0xFFFFD56A),
            ui.Color(0xFFFA5C6D),
          ],
          blobSpeedScale: 0.86 + rng.nextDouble() * 0.18,
          blobWobbleScale: 1.08 + rng.nextDouble() * 0.24,
          backgroundGlowAlpha: 0.52,
          territoryAlpha: 0.34,
          territoryGlowAlpha: 0.22,
          flashAmount: 0.12,
        );
    }
  }
}
