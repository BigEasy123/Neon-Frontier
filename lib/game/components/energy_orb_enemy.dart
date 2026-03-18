import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../playfield/playfield.dart';

class EnergyOrbEnemy extends PositionComponent with HasGameRef {
  EnergyOrbEnemy({
    required this.playfield,
    required Vector2 position,
    this.radius = 14,
  }) {
    this.position = position;
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
  }

  final Playfield playfield;
  final double radius;

  final math.Random _rng = math.Random();
  late Vector2 _velocity;
  double _phase = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    resetMotion();
  }

  void resetMotion() {
    final angle = _rng.nextDouble() * math.pi * 2;
    final speed = 90 + _rng.nextDouble() * 110;
    _velocity = Vector2(math.cos(angle), math.sin(angle))..scale(speed);
    _phase = _rng.nextDouble() * math.pi * 2;
  }

  void resetPosition(Vector2 to) {
    position = to.clone();
    resetMotion();
  }

  @override
  void update(double dt) {
    _phase += dt;

    final swirl = Vector2(math.cos(_phase * 0.8), math.sin(_phase * 0.9));
    _velocity += swirl * (dt * 26);
    final maxSpeed = 220.0;
    if (_velocity.length > maxSpeed) _velocity.scaleTo(maxSpeed);

    position += _velocity * dt;

    final r = playfield.bounds.deflate(radius);
    var bounced = false;

    if (position.x < r.left) {
      position.x = r.left;
      _velocity.x = _velocity.x.abs();
      bounced = true;
    } else if (position.x > r.right) {
      position.x = r.right;
      _velocity.x = -_velocity.x.abs();
      bounced = true;
    }

    if (position.y < r.top) {
      position.y = r.top;
      _velocity.y = _velocity.y.abs();
      bounced = true;
    } else if (position.y > r.bottom) {
      position.y = r.bottom;
      _velocity.y = -_velocity.y.abs();
      bounced = true;
    }

    if (bounced) {
      _velocity.rotate((_rng.nextDouble() - 0.5) * 0.55);
    }

    super.update(dt);
  }

  @override
  void render(ui.Canvas canvas) {
    final c = ui.Offset(radius, radius);
    final base = _color();

    final glow = ui.Paint()
      ..color = base.withOpacity(0.55)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18);
    canvas.drawCircle(c, radius * 1.6, glow);

    final inner = ui.Paint()..color = base.withOpacity(0.95);
    canvas.drawCircle(c, radius, inner);

    final spec = ui.Paint()..color = const ui.Color(0xFFFFFFFF).withOpacity(0.35);
    canvas.drawCircle(ui.Offset(radius * 0.7, radius * 0.7), radius * 0.35, spec);

    super.render(canvas);
  }

  ui.Color _color() {
    final t = (math.sin(_phase * 0.8) * 0.5 + 0.5);
    return ui.Color.lerp(const ui.Color(0xFF2EF2FF), const ui.Color(0xFFFF4FD8), t)!;
  }
}
