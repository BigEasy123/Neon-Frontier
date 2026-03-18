import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../playfield/playfield.dart';
import '../systems/capture_system.dart';

class PlayerOrb extends PositionComponent with HasGameReference {
  PlayerOrb({
    required Vector2 position,
    required double radius,
    required this.playfield,
    required this.captureSystem,
  }) : _radius = radius {
    this.position = position;
    size = Vector2.all(radius * 2);
    anchor = Anchor.center;
  }

  final Playfield playfield;
  final CaptureSystem captureSystem;
  final double _radius;

  Vector2? _target;
  bool _capturing = false;

  final double _maxSpeed = 540;
  final double _accel = 2200;
  final double _edgeSnapTolerance = 10;
  final double _leaveEdgeThreshold = 28;

  Vector2 _velocity = Vector2.zero();

  void setDragTarget(Vector2? target) {
    _target = target?.clone();
  }

  @override
  void update(double dt) {
    if (_target != null) {
      final desired = _desiredPositionFromTarget(_target!);
      final toDesired = desired - position;

      final dist = toDesired.length;
      if (dist > 0.0001) {
        final desiredVel = toDesired.normalized() * _maxSpeed * _speedScale(dist);
        final dv = desiredVel - _velocity;
        final maxDv = _accel * dt;
        if (dv.length > maxDv) {
          dv.scaleTo(maxDv);
        }
        _velocity += dv;
      }
    } else {
      _velocity *= math.pow(0.0008, dt).toDouble();
    }

    position += _velocity * dt;
    position = playfield.clampInside(position, padding: _radius);

    if (_capturing) {
      captureSystem.addPoint(position);
      if (playfield.isOnSafeEdge(position, tolerance: _edgeSnapTolerance)) {
        position = playfield.nearestPointOnSafeEdge(position);
        _capturing = false;
        captureSystem.finish();
      }
    }

    super.update(dt);
  }

  Vector2 _desiredPositionFromTarget(Vector2 target) {
    final clampedTarget = playfield.clampInside(target, padding: _radius);

    if (_capturing) {
      return clampedTarget;
    }

    final onEdge = playfield.isOnSafeEdge(position, tolerance: _edgeSnapTolerance);
    final targetBorderDist = playfield.distanceToSafeEdge(clampedTarget);

    if (onEdge && targetBorderDist > _leaveEdgeThreshold) {
      _capturing = true;
      captureSystem.start(position);
      return clampedTarget;
    }

    final projected = playfield.nearestPointOnSafeEdge(clampedTarget);
    return projected;
  }

  double _speedScale(double distance) {
    return (distance / 70).clamp(0.15, 1.0);
  }

  @override
  void render(ui.Canvas canvas) {
    final center = ui.Offset(_radius, _radius);

    final glowPaint = ui.Paint()
      ..color = const ui.Color(0xAA2EF2FF)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18);

    final innerPaint = ui.Paint()..color = const ui.Color(0xFFF2FEFF);

    final rimPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const ui.Color(0xFF8A7CFF).withValues(alpha: 0.75);

    canvas.drawCircle(center, _radius * 1.35, glowPaint);
    canvas.drawCircle(center, _radius, innerPaint);
    canvas.drawCircle(center, _radius * 0.92, rimPaint);

    super.render(canvas);
  }
}
