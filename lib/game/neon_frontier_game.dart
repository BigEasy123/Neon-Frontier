import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/energy_orb_enemy.dart';
import 'components/hud.dart';
import 'components/lava_lamp_background.dart';
import 'components/player_orb.dart';
import 'components/territory_renderer.dart';
import 'playfield/playfield.dart';
import 'playfield/territory_grid.dart';
import 'state/game_session.dart';
import 'systems/capture_system.dart';

class NeonFrontierGame extends FlameGame with PanDetector {
  NeonFrontierGame();

  late final Playfield playfield;
  late final TerritoryRenderer territoryRenderer;
  late final CaptureSystem captureSystem;
  late final PlayerOrb player;
  final List<EnergyOrbEnemy> enemies = <EnergyOrbEnemy>[];
  final GameSession session = GameSession();

  Vector2? _dragTarget;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    playfield = Playfield(
      margin: 24,
      safeBorderThickness: 18,
      cellSize: 18,
    )..rebuild(size);

    territoryRenderer = TerritoryRenderer(playfield: playfield);

    captureSystem = CaptureSystem(
      playfield: playfield,
      territoryRenderer: territoryRenderer,
      onCaptureLineHit: _lose,
      onCaptureCompleted: _onCaptureCompleted,
    );

    player = PlayerOrb(
      position: playfield.initialPlayerPosition(),
      radius: 16,
      playfield: playfield,
      captureSystem: captureSystem,
    );

    add(LavaLampBackground());
    add(territoryRenderer);
    add(captureSystem);
    add(player);

    enemies.addAll(
      <EnergyOrbEnemy>[
        EnergyOrbEnemy(playfield: playfield, position: playfield.bounds.center.toVector2() + Vector2(-140, -220)),
        EnergyOrbEnemy(playfield: playfield, position: playfield.bounds.center.toVector2() + Vector2(130, -160)),
        EnergyOrbEnemy(playfield: playfield, position: playfield.bounds.center.toVector2() + Vector2(30, 200)),
      ],
    );
    for (final e in enemies) {
      add(e);
    }

    add(
      Hud(
        scoreProvider: () => session.score,
        capturedProvider: () => session.captured,
        statusProvider: () {
          if (session.win) return 'You win';
          if (session.gameOver) return 'Game Over';
          return null;
        },
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    playfield.rebuild(size);
    if (!captureSystem.isCapturing) {
      player.position = playfield.nearestPointOnSafeEdge(player.position);
    }
  }

  @override
  void update(double dt) {
    captureSystem.setEnemyPositions(enemies.map((e) => e.position));
    super.update(dt);
  }

  @override
  void onPanStart(DragStartInfo info) {
    _dragTarget = info.eventPosition.game;
    player.setDragTarget(_dragTarget);
    super.onPanStart(info);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    _dragTarget = info.eventPosition.game;
    player.setDragTarget(_dragTarget);
    super.onPanUpdate(info);
  }

  @override
  void onPanEnd(DragEndInfo info) {
    _dragTarget = null;
    player.setDragTarget(null);
    super.onPanEnd(info);
  }

  void _onCaptureCompleted(CaptureResult result) {
    session.captured = result.capturedPercent;
    session.score += result.newlyCaptured.length.toDouble();
    if (session.captured >= 0.80) {
      session.win = true;
      pauseEngine();
    }
  }

  void _lose() {
    session.gameOver = true;
    pauseEngine();
  }
}
