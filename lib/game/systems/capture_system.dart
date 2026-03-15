import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

import '../components/territory_renderer.dart';
import '../playfield/playfield.dart';
import '../playfield/territory_grid.dart';
import 'capture_trail.dart';

typedef CaptureLostCallback = void Function();
typedef CaptureCompletedCallback = void Function(CaptureResult result);

class CaptureSystem extends Component with HasGameRef {
  CaptureSystem({
    required this.playfield,
    required this.territoryRenderer,
    required this.onCaptureLineHit,
    required this.onCaptureCompleted,
  });

  final Playfield playfield;
  final TerritoryRenderer territoryRenderer;
  final CaptureLostCallback onCaptureLineHit;
  final CaptureCompletedCallback onCaptureCompleted;

  final CaptureTrail trail = CaptureTrail();
  final List<Vector2> _enemyPositions = <Vector2>[];

  bool get isCapturing => trail.isActive;

  void setEnemyPositions(Iterable<Vector2> positions) {
    _enemyPositions
      ..clear()
      ..addAll(positions.map((p) => p.clone()));
  }

  void start(Vector2 startPoint) {
    trail.start(startPoint);
  }

  void addPoint(Vector2 p) {
    trail.addPoint(p);
  }

  void cancel() {
    trail.stop();
  }

  void finish() {
    final points = trail.finish(clear: true);
    final result = playfield.territory.captureFromTrail(
      trailPoints: points,
      enemyPositions: _enemyPositions,
      wallThickness: 14,
    );

    if (result.newlyCaptured.isNotEmpty) {
      territoryRenderer.addCapturePulse(result.newlyCaptured);
      playfield.notifyTerritoryChanged();
    }

    onCaptureCompleted(result);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(trail);
  }

  @override
  void update(double dt) {
    if (trail.points.length >= 2 && _enemyPositions.isNotEmpty) {
      final hit = _enemyHitsTrail(
        enemyPositions: _enemyPositions,
        polyline: trail.points,
        threshold: 18,
      );
      if (hit) {
        cancel();
        onCaptureLineHit();
      }
    }
    super.update(dt);
  }

  bool _enemyHitsTrail({
    required List<Vector2> enemyPositions,
    required List<Vector2> polyline,
    required double threshold,
  }) {
    for (final enemy in enemyPositions) {
      for (var i = 0; i < polyline.length - 1; i++) {
        final a = polyline[i];
        final b = polyline[i + 1];
        final d = _distancePointToSegment(enemy, a, b);
        if (d <= threshold) return true;
      }
    }
    return false;
  }

  double _distancePointToSegment(Vector2 p, Vector2 a, Vector2 b) {
    final ab = b - a;
    final denom = ab.length2;
    if (denom <= 0.0000001) return p.distanceTo(a);
    final t = ((p - a).dot(ab) / denom).clamp(0.0, 1.0);
    final q = a + ab * t;
    return p.distanceTo(q);
  }
}
