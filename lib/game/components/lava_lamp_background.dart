import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../state/level_theme.dart';

class LavaLampBackground extends PositionComponent with HasGameReference<FlameGame> {
  LavaLampBackground({
    required LevelTheme Function() themeProvider,
    int blobCount = 7,
  }) : _themeProvider = themeProvider,
       _blobCount = blobCount;

  final LevelTheme Function() _themeProvider;
  final int _blobCount;
  math.Random _rng = math.Random(3);
  final List<_Blob> _blobs = <_Blob>[];
  int _activeThemeSeed = -1;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    size = game.size;
    position = Vector2.zero();
    priority = -1000;
    _reseedForTheme(_themeProvider());
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    this.size = size;
    for (final blob in _blobs) {
      blob.wrapInto(size);
    }
  }

  @override
  void update(double dt) {
    final theme = _themeProvider();
    if (_activeThemeSeed != theme.seed) {
      _reseedForTheme(theme);
    }
    for (final blob in _blobs) {
      blob.update(dt, size, theme);
    }
    super.update(dt);
  }

  @override
  void render(ui.Canvas canvas) {
    final theme = _themeProvider();
    final bgPaint = ui.Paint()..color = theme.background;
    canvas.drawRect(size.toRect(), bgPaint);

    final flash = ((math.sin(game.currentTime() * 0.65) * 0.5) + 0.5) * theme.flashAmount;

    for (final blob in _blobs) {
      final gradient = ui.Gradient.radial(
        ui.Offset(blob.position.x, blob.position.y),
        blob.radius,
        <ui.Color>[
          blob.color.withValues(alpha: (theme.backgroundGlowAlpha + flash).clamp(0.0, 0.95)),
          blob.color.withValues(alpha: 0.0),
        ],
        const <double>[0.0, 1.0],
      );

      final paint = ui.Paint()
        ..shader = gradient
        ..blendMode = ui.BlendMode.plus
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 24);

      canvas.drawCircle(ui.Offset(blob.position.x, blob.position.y), blob.radius, paint);
    }
  }

  void _reseedForTheme(LevelTheme theme) {
    _activeThemeSeed = theme.seed;
    _rng = math.Random(theme.seed);
    _blobs.clear();
    for (var i = 0; i < _blobCount; i++) {
      _blobs.add(_Blob.random(_rng, size, theme));
    }
  }
}

class _Blob {
  _Blob({
    required this.position,
    required this.radius,
    required this.velocity,
    required this.color,
    required this.phase,
    required this.wobble,
  });

  Vector2 position;
  double radius;
  Vector2 velocity;
  ui.Color color;
  double phase;
  double wobble;

  static _Blob random(math.Random rng, Vector2 size, LevelTheme theme) {
    final pos = Vector2(
      rng.nextDouble() * size.x,
      rng.nextDouble() * size.y,
    );

    final speed = (8 + rng.nextDouble() * 18) * theme.blobSpeedScale;
    final angle = rng.nextDouble() * math.pi * 2;
    final vel = Vector2(math.cos(angle), math.sin(angle))..scale(speed);

    return _Blob(
      position: pos,
      radius: 140 + rng.nextDouble() * 260,
      velocity: vel,
      color: theme.palette[rng.nextInt(theme.palette.length)],
      phase: rng.nextDouble() * math.pi * 2,
      wobble: (0.35 + rng.nextDouble() * 0.55) * theme.blobWobbleScale,
    );
  }

  void update(double dt, Vector2 bounds, LevelTheme theme) {
    phase += dt * 0.6;
    final wobbleScale = 1 + math.sin(phase) * wobble * 0.08;
    radius = radius.clamp(120, 460) * wobbleScale;

    position += velocity * dt;

    velocity.rotate((math.sin(phase * 0.7) * (0.07 + theme.flashAmount * 0.02)) * dt);

    wrapInto(bounds);
  }

  void wrapInto(Vector2 bounds) {
    if (bounds.x <= 0 || bounds.y <= 0) return;
    if (position.x < -radius) position.x = bounds.x + radius;
    if (position.x > bounds.x + radius) position.x = -radius;
    if (position.y < -radius) position.y = bounds.y + radius;
    if (position.y > bounds.y + radius) position.y = -radius;
  }
}
