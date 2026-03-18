import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../playfield/playfield.dart';
import '../playfield/territory_grid.dart';
import '../state/level_theme.dart';

class TerritoryRenderer extends Component with HasGameReference<FlameGame> {
  TerritoryRenderer({
    required this.playfield,
    required LevelTheme Function() themeProvider,
  }) : _themeProvider = themeProvider;

  final Playfield playfield;
  final LevelTheme Function() _themeProvider;

  final List<_CapturePulse> _pulses = <_CapturePulse>[];

  void resetEffects() {
    _pulses.clear();
  }

  void addCapturePulse(List<Cell> cells) {
    if (cells.isEmpty) return;
    final theme = _themeProvider();
    final rng = math.Random(theme.seed ^ cells.length);
    _pulses.add(
      _CapturePulse(
        startedAt: game.currentTime(),
        cells: cells,
        color: theme.palette[rng.nextInt(theme.palette.length)],
      ),
    );
    if (_pulses.length > 6) {
      _pulses.removeAt(0);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final grid = playfield.territory;
    final theme = _themeProvider();
    final cs = grid.cellSize;

    final basePaint = ui.Paint()
      ..blendMode = ui.BlendMode.srcOver;
    final edgePaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 0.85
      ..color = theme.palette[0].withValues(alpha: 0.45);
    final glowPaint = ui.Paint()
      ..blendMode = ui.BlendMode.plus
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    for (var r = 1; r < grid.rows - 1; r++) {
      for (var c = 1; c < grid.cols - 1; c++) {
        if (!grid.isCaptured(c, r)) continue;
        final rect = grid.cellRect(c, r);
        final color = _cellColor(c, r, theme);
        basePaint.color = color.withValues(alpha: theme.territoryAlpha);
        glowPaint.color = color.withValues(alpha: theme.territoryGlowAlpha);
        canvas.drawRect(rect, basePaint);
        canvas.drawRect(rect.inflate(cs * 0.04), glowPaint);
        canvas.drawRect(rect.deflate(0.4), edgePaint);
      }
    }

    final now = game.currentTime();
    _pulses.removeWhere((p) => now - p.startedAt > p.duration);
    for (final pulse in _pulses) {
      final t = ((now - pulse.startedAt) / pulse.duration).clamp(0.0, 1.0);
      final eased = _easeOutCubic(t);
      final paint = ui.Paint()
        ..blendMode = ui.BlendMode.plus
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 8)
        ..color = pulse.color.withValues(alpha: (0.40 + theme.flashAmount * 0.7) * eased);

      for (final cell in pulse.cells) {
        final rect = grid.cellRect(cell.c, cell.r);
        canvas.drawRect(rect.inflate(cs * (0.08 + 0.15 * eased)), paint);
      }
    }
  }

  ui.Color _cellColor(int c, int r, LevelTheme theme) {
    final seed = (c * 73856093) ^ (r * 19349663) ^ theme.seed;
    return theme.palette[seed.abs() % theme.palette.length];
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
