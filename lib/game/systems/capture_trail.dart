import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/extensions.dart';

class CaptureTrail extends Component {
  final List<Vector2> _points = <Vector2>[];
  bool _active = false;

  bool get isActive => _active;
  List<Vector2> get points => _points;

  void start(Vector2 startPoint) {
    _active = true;
    _points
      ..clear()
      ..add(startPoint.clone());
  }

  void addPoint(Vector2 point, {double minDistance = 6}) {
    if (!_active) return;
    if (_points.isEmpty) {
      _points.add(point.clone());
      return;
    }
    if (_points.last.distanceTo(point) >= minDistance) {
      _points.add(point.clone());
    }
  }

  void stop() {
    _active = false;
    _points.clear();
  }

  List<Vector2> finish({bool clear = true}) {
    _active = false;
    final out = _points.map((p) => p.clone()).toList(growable: false);
    if (clear) _points.clear();
    return out;
  }

  @override
  void render(ui.Canvas canvas) {
    if (_points.length < 2) return;

    final path = ui.Path()..moveTo(_points.first.x, _points.first.y);
    for (var i = 1; i < _points.length; i++) {
      path.lineTo(_points[i].x, _points[i].y);
    }

    final glowPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..color = const ui.Color(0x882EF2FF)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);

    final corePaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..color = const ui.Color(0xFFE8FCFF);

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, corePaint);
  }
}
