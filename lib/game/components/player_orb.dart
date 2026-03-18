import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../playfield/playfield.dart';
import '../state/player_skin.dart';
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
  PlayerSkin skin = PlayerSkin.orb;
  double speedMultiplier = 1.0;

  double get radius => _radius;

  Vector2? _target;
  bool _capturing = false;
  _CaptureAxis? _captureAxis;

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
        final desiredVel = toDesired.normalized() * (_maxSpeed * speedMultiplier) * _speedScale(dist);
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

    final previousPosition = position.clone();
    position += _velocity * dt;
    position = playfield.clampInside(position, padding: _radius);

    if (_capturing) {
      _preventCaptureBacktracking(previousPosition);
      captureSystem.addPoint(position);
      if (playfield.isOnSafeEdge(position, tolerance: _edgeSnapTolerance)) {
        position = playfield.nearestPointOnSafeEdge(position);
        _capturing = false;
        _captureAxis = null;
        captureSystem.finish();
      }
    }

    super.update(dt);
  }

  Vector2 _desiredPositionFromTarget(Vector2 target) {
    final clampedTarget = playfield.clampInside(target, padding: _radius);

    if (_capturing) {
      _updateCaptureAxis(clampedTarget);
      return _projectToCaptureAxis(clampedTarget);
    }

    final onEdge = playfield.isOnSafeEdge(position, tolerance: _edgeSnapTolerance);
    final targetBorderDist = playfield.distanceToSafeEdge(clampedTarget);

    if (onEdge && targetBorderDist > _leaveEdgeThreshold) {
      _capturing = true;
      _captureAxis = _axisFromDelta(clampedTarget - position);
      captureSystem.start(position);
      return _projectToCaptureAxis(clampedTarget);
    }

    final projected = playfield.nearestPointOnSafeEdge(clampedTarget);
    return projected;
  }

  double _speedScale(double distance) {
    return (distance / 70).clamp(0.15, 1.0);
  }

  void _preventCaptureBacktracking(Vector2 previousPosition) {
    final points = captureSystem.trail.points;
    if (points.length < 2) return;

    final forward = points.last - points[points.length - 2];
    if (forward.length2 <= 0.000001) return;

    final moved = position - previousPosition;
    if (moved.length2 <= 0.000001) return;

    if (moved.dot(forward) < 0) {
      position = previousPosition;
      _velocity = Vector2.zero();
    }
  }

  _CaptureAxis _axisFromDelta(Vector2 delta) {
    return delta.x.abs() >= delta.y.abs() ? _CaptureAxis.horizontal : _CaptureAxis.vertical;
  }

  void _updateCaptureAxis(Vector2 target) {
    final delta = target - position;
    if (delta.length2 <= 0.000001) return;
    final dominant = _axisFromDelta(delta);
    if (dominant == _captureAxis) return;

    final canTurn = switch (_captureAxis) {
      _CaptureAxis.horizontal => delta.y.abs() > 6,
      _CaptureAxis.vertical => delta.x.abs() > 6,
      null => true,
    };
    if (!canTurn) return;

    _captureAxis = dominant;
    _velocity = Vector2.zero();
  }

  Vector2 _projectToCaptureAxis(Vector2 point) {
    final projected = switch (_captureAxis) {
      _CaptureAxis.horizontal => Vector2(point.x, position.y),
      _CaptureAxis.vertical => Vector2(position.x, point.y),
      null => point.clone(),
    };
    return playfield.clampInside(projected, padding: _radius);
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

    switch (skin) {
      case PlayerSkin.orb:
        canvas.drawCircle(center, _radius * 1.35, glowPaint);
        canvas.drawCircle(center, _radius, innerPaint);
        canvas.drawCircle(center, _radius * 0.92, rimPaint);
        break;
      case PlayerSkin.square:
        final rect = ui.Rect.fromCenter(
          center: center,
          width: _radius * 2,
          height: _radius * 2,
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(rect.inflate(_radius * 0.35), ui.Radius.circular(8)),
          glowPaint,
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(rect, ui.Radius.circular(6)),
          innerPaint,
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(rect.deflate(_radius * 0.1), ui.Radius.circular(5)),
          rimPaint,
        );
        break;
      case PlayerSkin.triangle:
        final tri = ui.Path()
          ..moveTo(center.dx, center.dy - _radius)
          ..lineTo(center.dx + _radius * 0.92, center.dy + _radius * 0.85)
          ..lineTo(center.dx - _radius * 0.92, center.dy + _radius * 0.85)
          ..close();
        final triGlow = ui.Path()
          ..moveTo(center.dx, center.dy - _radius * 1.35)
          ..lineTo(center.dx + _radius * 1.2, center.dy + _radius * 1.1)
          ..lineTo(center.dx - _radius * 1.2, center.dy + _radius * 1.1)
          ..close();
        canvas.drawPath(triGlow, glowPaint);
        canvas.drawPath(tri, innerPaint);
        canvas.drawPath(tri, rimPaint);
        break;
    }

    super.render(canvas);
  }
}

enum _CaptureAxis { horizontal, vertical }
