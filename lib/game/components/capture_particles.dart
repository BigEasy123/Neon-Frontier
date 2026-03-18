import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../playfield/territory_grid.dart';

class CaptureParticles extends Component {
  final List<_GlowParticle> _particles = <_GlowParticle>[];
  final math.Random _rng = math.Random(13);

  void spawnFromCapturedCells(TerritoryGrid grid, List<Cell> cells) {
    if (cells.isEmpty) return;
    final sampleStep = math.max(1, (cells.length / 24).ceil());
    for (var i = 0; i < cells.length; i += sampleStep) {
      final cell = cells[i];
      final center = grid.cellCenter(cell.c, cell.r);
      final count = 1 + _rng.nextInt(3);
      for (var p = 0; p < count; p++) {
        final angle = _rng.nextDouble() * math.pi * 2;
        final speed = 35 + _rng.nextDouble() * 80;
        _particles.add(
          _GlowParticle(
            position: center.clone(),
            velocity: Vector2(math.cos(angle), math.sin(angle)) * speed,
            radius: 2.2 + _rng.nextDouble() * 4.5,
            lifetime: 0.45 + _rng.nextDouble() * 0.65,
            color: _color(),
          ),
        );
      }
    }
  }

  @override
  void update(double dt) {
    for (final p in _particles) {
      p.update(dt);
    }
    _particles.removeWhere((p) => p.dead);
    super.update(dt);
  }

  @override
  void render(ui.Canvas canvas) {
    for (final p in _particles) {
      final t = 1 - (p.age / p.lifetime).clamp(0.0, 1.0);
      final glowPaint = ui.Paint()
        ..color = p.color.withValues(alpha: 0.45 * t)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 10);
      final corePaint = ui.Paint()..color = p.color.withValues(alpha: 0.85 * t);
      final c = ui.Offset(p.position.x, p.position.y);
      canvas.drawCircle(c, p.radius * (1.5 * t), glowPaint);
      canvas.drawCircle(c, p.radius * t, corePaint);
    }
  }

  ui.Color _color() {
    const palette = <ui.Color>[
      ui.Color(0xFF2EF2FF),
      ui.Color(0xFF8A7CFF),
      ui.Color(0xFFFF4FD8),
      ui.Color(0xFFFFB84D),
    ];
    return palette[_rng.nextInt(palette.length)];
  }
}

class _GlowParticle {
  _GlowParticle({
    required this.position,
    required this.velocity,
    required this.radius,
    required this.lifetime,
    required this.color,
  });

  Vector2 position;
  Vector2 velocity;
  double radius;
  double lifetime;
  ui.Color color;
  double age = 0;

  bool get dead => age >= lifetime;

  void update(double dt) {
    age += dt;
    position += velocity * dt;
    velocity *= math.pow(0.02, dt).toDouble();
  }
}
