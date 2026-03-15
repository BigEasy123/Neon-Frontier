import 'dart:math' as math;

import 'package:flame/extensions.dart';

import 'territory_grid.dart';

class Playfield {
  Playfield({
    required this.margin,
    required this.safeBorderThickness,
    required this.cellSize,
  });

  final double margin;
  final double safeBorderThickness;
  final double cellSize;

  late Rect bounds;
  late TerritoryGrid territory;
  List<Segment> _safeSegments = <Segment>[];

  void rebuild(Vector2 gameSize) {
    bounds = Rect.fromLTWH(
      margin,
      margin,
      math.max(0, gameSize.x - margin * 2),
      math.max(0, gameSize.y - margin * 2),
    );
    territory = TerritoryGrid.fromBounds(bounds, cellSize: cellSize);
    _rebuildSafeSegments();
  }

  Vector2 initialPlayerPosition() {
    return Vector2(bounds.left + bounds.width * 0.5, bounds.bottom);
  }

  Vector2 clampInside(Vector2 point, {double padding = 0}) {
    final rect = bounds.deflate(padding);
    return Vector2(
      point.x.clamp(rect.left, rect.right),
      point.y.clamp(rect.top, rect.bottom),
    );
  }

  bool isOnSafeEdge(Vector2 point, {double tolerance = 8}) {
    return distanceToSafeEdge(point) <= tolerance;
  }

  double distanceToSafeEdge(Vector2 point) {
    final p = clampInside(point);
    var best = _distanceToOuterBorder(p);
    for (final seg in _safeSegments) {
      final d = seg.distanceTo(p);
      if (d < best) best = d;
    }
    return best;
  }

  Vector2 nearestPointOnSafeEdge(Vector2 point) {
    final p = clampInside(point);
    var best = _nearestPointOnOuterBorder(p);
    var bestD = p.distanceTo(best);
    for (final seg in _safeSegments) {
      final q = seg.nearestPoint(p);
      final d = p.distanceTo(q);
      if (d < bestD) {
        bestD = d;
        best = q;
      }
    }
    return best;
  }

  void notifyTerritoryChanged() {
    _rebuildSafeSegments();
  }

  void _rebuildSafeSegments() {
    _safeSegments = territory.boundarySegments();
  }

  double _distanceToOuterBorder(Vector2 point) {
    final dx = math.min((point.x - bounds.left).abs(), (point.x - bounds.right).abs());
    final dy = math.min((point.y - bounds.top).abs(), (point.y - bounds.bottom).abs());
    return math.min(dx, dy);
  }

  Vector2 _nearestPointOnOuterBorder(Vector2 point) {
    final clampedX = point.x.clamp(bounds.left, bounds.right);
    final clampedY = point.y.clamp(bounds.top, bounds.bottom);

    final dLeft = (clampedX - bounds.left).abs();
    final dRight = (bounds.right - clampedX).abs();
    final dTop = (clampedY - bounds.top).abs();
    final dBottom = (bounds.bottom - clampedY).abs();

    final minD = math.min(math.min(dLeft, dRight), math.min(dTop, dBottom));

    if (minD == dLeft) return Vector2(bounds.left, clampedY);
    if (minD == dRight) return Vector2(bounds.right, clampedY);
    if (minD == dTop) return Vector2(clampedX, bounds.top);
    return Vector2(clampedX, bounds.bottom);
  }
}

class Segment {
  Segment(this.a, this.b);

  final Vector2 a;
  final Vector2 b;

  Vector2 nearestPoint(Vector2 p) {
    final ab = b - a;
    final denom = ab.length2;
    if (denom <= 0.0000001) return a.clone();
    final t = ((p - a).dot(ab) / denom).clamp(0.0, 1.0);
    return a + ab * t;
  }

  double distanceTo(Vector2 p) => p.distanceTo(nearestPoint(p));
}

