import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

enum PowerupType {
  speedBoost,
  nextLevel,
  enemyFreeze,
  immunity,
}

class PowerupPickup extends PositionComponent {
  PowerupPickup({
    required this.type,
    required Vector2 position,
    this.radius = 13,
  }) : _spawnPosition = position.clone() {
    this.position = position;
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
  }

  final PowerupType type;
  final double radius;
  final Vector2 _spawnPosition;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
    // Gentle hover to make pickups readable over animated background.
    position.y = _spawnPosition.y + math.sin(_t * 2.2) * 4;
    super.update(dt);
  }

  @override
  void render(ui.Canvas canvas) {
    final center = ui.Offset(radius, radius);
    final color = _color(type);

    final glow = ui.Paint()
      ..color = color.withValues(alpha: 0.55)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);
    canvas.drawCircle(center, radius * 1.55, glow);

    final body = ui.Paint()..color = color.withValues(alpha: 0.95);
    canvas.drawCircle(center, radius, body);

    final icon = ui.Paint()
      ..color = const ui.Color(0xFF081018)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;

    switch (type) {
      case PowerupType.speedBoost:
        canvas.drawLine(
          ui.Offset(radius * 0.75, radius * 1.25),
          ui.Offset(radius * 1.1, radius * 0.7),
          icon,
        );
        canvas.drawLine(
          ui.Offset(radius * 1.1, radius * 0.7),
          ui.Offset(radius * 1.25, radius * 1.05),
          icon,
        );
        break;
      case PowerupType.nextLevel:
        final path = ui.Path()
          ..moveTo(radius * 0.75, radius * 0.65)
          ..lineTo(radius * 1.35, radius)
          ..lineTo(radius * 0.75, radius * 1.35)
          ..close();
        canvas.drawPath(path, icon..style = ui.PaintingStyle.fill);
        break;
      case PowerupType.enemyFreeze:
        canvas.drawLine(
          ui.Offset(radius * 0.7, radius * 0.7),
          ui.Offset(radius * 1.3, radius * 1.3),
          icon,
        );
        canvas.drawLine(
          ui.Offset(radius * 1.3, radius * 0.7),
          ui.Offset(radius * 0.7, radius * 1.3),
          icon,
        );
        break;
      case PowerupType.immunity:
        final ring = ui.Paint()
          ..color = const ui.Color(0xFF081018)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 2.4;
        canvas.drawCircle(center, radius * 0.45, ring);
        break;
    }
  }

  static ui.Color _color(PowerupType t) {
    switch (t) {
      case PowerupType.speedBoost:
        return const ui.Color(0xFFFFC857);
      case PowerupType.nextLevel:
        return const ui.Color(0xFF70F6FF);
      case PowerupType.enemyFreeze:
        return const ui.Color(0xFF9DA9FF);
      case PowerupType.immunity:
        return const ui.Color(0xFF78FFB3);
    }
  }
}
