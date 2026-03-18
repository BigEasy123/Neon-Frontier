import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../playfield/playfield.dart';
import '../playfield/territory_grid.dart';

class TerritoryRenderer extends Component with HasGameReference<FlameGame> {
  TerritoryRenderer({
    required this.playfield,
  });

  final Playfield playfield;

  final List<_CapturePulse> _pulses = <_CapturePulse>[];
  final math.Random _rng = math.Random(7);

  void resetEffects() {
    _pulses.clear();
  }

  void addCapturePulse(List<Cell> cells) {
    if (cells.isEmpty) return;
    _pulses.add(
      _CapturePulse(
        startedAt: game.currentTime(),
        cells: cells,
        color: _randomLavaColor(),
      ),
    );
    if (_pulses.length > 6) {
      _pulses.removeAt(0);
    }
  }

  ui.Color _randomLavaColor() {
    final colors = <ui.Color>[
      const ui.Color(0xFF8A7CFF),
      const ui.Color(0xFF2EF2FF),
      const ui.Color(0xFFFF4FD8),
      const ui.Color(0xFFFFB84D),
      const ui.Color(0xFF4BFF88),
    ];
    return colors[_rng.nextInt(colors.length)];
  }

  @override
  void render(ui.Canvas canvas) {
    final grid = playfield.territory;
    final cs = grid.cellSize;

    final basePaint = ui.Paint()
      ..blendMode = ui.BlendMode.plus
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 14);

    for (var r = 1; r < grid.rows - 1; r++) {
      for (var c = 1; c < grid.cols - 1; c++) {
        if (!grid.isCaptured(c, r)) continue;
        final rect = grid.cellRect(c, r);
        final color = _cellColor(c, r);
        basePaint.color = color.withValues(alpha: 0.10);
        canvas.drawRect(rect.inflate(cs * 0.22), basePaint);
      }
    }

    final now = game.currentTime();
    _pulses.removeWhere((p) => now - p.startedAt > p.duration);
    for (final pulse in _pulses) {
      final t = ((now - pulse.startedAt) / pulse.duration).clamp(0.0, 1.0);
      final eased = _easeOutCubic(t);
      final paint = ui.Paint()
        ..blendMode = ui.BlendMode.plus
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 18)
        ..color = pulse.color.withValues(alpha: 0.45 * eased);

      for (final cell in pulse.cells) {
        final rect = grid.cellRect(cell.c, cell.r);
        canvas.drawRect(rect.inflate(cs * (0.25 + 0.25 * eased)), paint);
      }
    }
  }

  ui.Color _cellColor(int c, int r) {
    final seed = (c * 73856093) ^ (r * 19349663);
    switch (seed % 5) {
      case 0:
        return const ui.Color(0xFF8A7CFF);
      case 1:
        return const ui.Color(0xFF2EF2FF);
      case 2:
        return const ui.Color(0xFFFF4FD8);
      case 3:
        return const ui.Color(0xFFFFB84D);
      default:
        return const ui.Color(0xFF4BFF88);
    }
  }

  double _easeOutCubic(double t) => 1 - math.pow(1 - t, 3).toDouble();
}

class _CapturePulse {
  _CapturePulse({
    required this.startedAt,
    required this.cells,
    required this.color,
  });

  final double startedAt;
  final List<Cell> cells;
  final ui.Color color;
  final double duration = 0.65;
}
