import 'dart:collection';
import 'dart:math' as math;

import 'package:flame/extensions.dart';

import 'playfield.dart';

class TerritoryGrid {
  TerritoryGrid._({
    required this.bounds,
    required this.cellSize,
    required this.cols,
    required this.rows,
    required List<bool> captured,
  }) : _captured = captured;

  final Rect bounds;
  final double cellSize;
  final int cols;
  final int rows;

  final List<bool> _captured;

  int get cellCount => cols * rows;

  bool isCaptured(int c, int r) => _captured[_idx(c, r)];

  setCaptured(int c, int r, bool value) => _captured[_idx(c, r)] = value;

  static TerritoryGrid fromBounds(Rect bounds, {required double cellSize}) {
    final cols = math.max(4, (bounds.width / cellSize).floor());
    final rows = math.max(4, (bounds.height / cellSize).floor());
    final captured = List<bool>.filled(cols * rows, false);
    final grid = TerritoryGrid._(
      bounds: bounds,
      cellSize: cellSize,
      cols: cols,
      rows: rows,
      captured: captured,
    );

    for (var c = 0; c < cols; c++) {
      grid.setCaptured(c, 0, true);
      grid.setCaptured(c, rows - 1, true);
    }
    for (var r = 0; r < rows; r++) {
      grid.setCaptured(0, r, true);
      grid.setCaptured(cols - 1, r, true);
    }

    return grid;
  }

  double capturedPercent() {
    final interior = (cols - 2) * (rows - 2);
    if (interior <= 0) return 0;
    var capturedInterior = 0;
    for (var r = 1; r < rows - 1; r++) {
      for (var c = 1; c < cols - 1; c++) {
        if (isCaptured(c, r)) capturedInterior++;
      }
    }
    return capturedInterior / interior;
  }

  Cell cellForWorld(Vector2 p) {
    final localX = (p.x - bounds.left).clamp(0.0, bounds.width - 0.0001);
    final localY = (p.y - bounds.top).clamp(0.0, bounds.height - 0.0001);
    final c = (localX / cellSize).floor().clamp(0, cols - 1);
    final r = (localY / cellSize).floor().clamp(0, rows - 1);
    return Cell(c, r);
  }

  Rect cellRect(int c, int r) {
    return Rect.fromLTWH(
      bounds.left + c * cellSize,
      bounds.top + r * cellSize,
      cellSize,
      cellSize,
    );
  }

  Vector2 cellCenter(int c, int r) {
    final rect = cellRect(c, r);
    return Vector2(rect.center.dx, rect.center.dy);
  }

  List<Segment> boundarySegments() {
    final segments = <Segment>[];
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (!isCaptured(c, r)) continue;
        final rect = cellRect(c, r);

        final leftOpen = c == 0 ? false : !isCaptured(c - 1, r);
        final rightOpen = c == cols - 1 ? false : !isCaptured(c + 1, r);
        final topOpen = r == 0 ? false : !isCaptured(c, r - 1);
        final bottomOpen = r == rows - 1 ? false : !isCaptured(c, r + 1);

        if (leftOpen) {
          segments.add(
            Segment(
              Vector2(rect.left, rect.top),
              Vector2(rect.left, rect.bottom),
            ),
          );
        }
        if (rightOpen) {
          segments.add(
            Segment(
              Vector2(rect.right, rect.top),
              Vector2(rect.right, rect.bottom),
            ),
          );
        }
        if (topOpen) {
          segments.add(
            Segment(
              Vector2(rect.left, rect.top),
              Vector2(rect.right, rect.top),
            ),
          );
        }
        if (bottomOpen) {
          segments.add(
            Segment(
              Vector2(rect.left, rect.bottom),
              Vector2(rect.right, rect.bottom),
            ),
          );
        }
      }
    }
    return segments;
  }

  CaptureResult captureFromTrail({
    required List<Vector2> trailPoints,
    required List<Vector2> enemyPositions,
    required double wallThickness,
  }) {
    if (trailPoints.length < 2) {
      return CaptureResult.empty(capturedPercent());
    }

    final wall = List<bool>.filled(cellCount, false);
    _rasterizeTrailAsWall(trailPoints, wall: wall, thickness: wallThickness);

    final reachable = List<bool>.filled(cellCount, false);
    final queue = Queue<Cell>();

    for (final enemyPos in enemyPositions) {
      final cell = cellForWorld(enemyPos);
      if (_isBlocked(cell.c, cell.r, wall: wall)) continue;
      final idx = _idx(cell.c, cell.r);
      if (reachable[idx]) continue;
      reachable[idx] = true;
      queue.add(cell);
    }

    while (queue.isNotEmpty) {
      final cur = queue.removeFirst();
      for (final n in cur.neighbors4()) {
        if (n.c < 0 || n.c >= cols || n.r < 0 || n.r >= rows) continue;
        if (_isBlocked(n.c, n.r, wall: wall)) continue;
        final idx = _idx(n.c, n.r);
        if (reachable[idx]) continue;
        reachable[idx] = true;
        queue.add(n);
      }
    }

    final newlyCaptured = <Cell>[];
    for (var r = 1; r < rows - 1; r++) {
      for (var c = 1; c < cols - 1; c++) {
        final idx = _idx(c, r);
        if (_captured[idx]) continue;
        if (wall[idx]) continue;
        if (reachable[idx]) continue;
        _captured[idx] = true;
        newlyCaptured.add(Cell(c, r));
      }
    }

    return CaptureResult(
      newlyCaptured: newlyCaptured,
      capturedPercent: capturedPercent(),
    );
  }

  bool _isBlocked(int c, int r, {required List<bool> wall}) {
    final idx = _idx(c, r);
    return _captured[idx] || wall[idx];
  }

  void _rasterizeTrailAsWall(
    List<Vector2> points, {
    required List<bool> wall,
    required double thickness,
  }) {
    final step = math.max(2.0, cellSize * 0.35);
    final radius = math.max(0.5, thickness / cellSize);

    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i];
      final b = points[i + 1];
      final ab = b - a;
      final len = ab.length;
      if (len <= 0.0001) continue;
      final dir = ab / len;

      final samples = math.max(1, (len / step).ceil());
      for (var s = 0; s <= samples; s++) {
        final p = a + dir * (len * (s / samples));
        final cell = cellForWorld(p);
        for (var dr = -radius.ceil(); dr <= radius.ceil(); dr++) {
          for (var dc = -radius.ceil(); dc <= radius.ceil(); dc++) {
            final cc = cell.c + dc;
            final rr = cell.r + dr;
            if (cc < 0 || cc >= cols || rr < 0 || rr >= rows) continue;
            wall[_idx(cc, rr)] = true;
          }
        }
      }
    }
  }

  int _idx(int c, int r) => r * cols + c;
}

class Cell {
  const Cell(this.c, this.r);

  final int c;
  final int r;

  Iterable<Cell> neighbors4() sync* {
    yield Cell(c - 1, r);
    yield Cell(c + 1, r);
    yield Cell(c, r - 1);
    yield Cell(c, r + 1);
  }
}

class CaptureResult {
  CaptureResult({
    required this.newlyCaptured,
    required this.capturedPercent,
  });

  final List<Cell> newlyCaptured;
  final double capturedPercent;

  static CaptureResult empty(double capturedPercent) {
    return CaptureResult(newlyCaptured: const <Cell>[], capturedPercent: capturedPercent);
  }
}

