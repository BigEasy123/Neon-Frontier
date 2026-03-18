import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/capture_particles.dart';
import 'components/energy_orb_enemy.dart';
import 'components/hud.dart';
import 'components/lava_lamp_background.dart';
import 'components/player_orb.dart';
import 'components/territory_renderer.dart';
import 'playfield/playfield.dart';
import 'playfield/territory_grid.dart';
import 'services/ad_service.dart';
import 'state/game_session.dart';
import 'state/level_theme.dart';
import 'systems/capture_system.dart';

class NeonFrontierGame extends FlameGame with PanDetector {
  NeonFrontierGame({
    required AdService adService,
    this.onSessionChanged,
  }) : _adService = adService;

  static const String endOverlayId = 'end_overlay';

  late final Playfield playfield;
  late final TerritoryRenderer territoryRenderer;
  late final CaptureParticles captureParticles;
  late final CaptureSystem captureSystem;
  late final PlayerOrb player;
  final List<EnergyOrbEnemy> enemies = <EnergyOrbEnemy>[];
  final GameSession session = GameSession();
  final AdService _adService;
  final void Function(GameSession session)? onSessionChanged;
  late LevelTheme _theme;

  Vector2? _dragTarget;
  bool _initialized = false;

  LevelTheme get currentTheme => _theme;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    playfield = Playfield(
      margin: 24,
      safeBorderThickness: 18,
      cellSize: 18,
    )..rebuild(size);
    _theme = LevelThemeGenerator.fromLevel(session.level);

    territoryRenderer = TerritoryRenderer(
      playfield: playfield,
      themeProvider: () => _theme,
    );
    captureParticles = CaptureParticles();

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

    add(LavaLampBackground(themeProvider: () => _theme));
    add(territoryRenderer);
    add(captureParticles);
    add(captureSystem);
    add(player);

    _spawnEnemies();

    add(
      Hud(
        scoreProvider: () => session.score,
        capturedProvider: () => session.captured,
        targetProvider: () => session.targetCapturePercent,
        levelProvider: () => session.level,
        statusProvider: () {
          if (session.win) return 'You win';
          if (session.gameOver) return 'Game Over';
          return null;
        },
      ),
    );
    _initialized = true;
    _notifySessionChanged();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (!_initialized) return;
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
    if (session.gameOver || session.win) return;
    _dragTarget = info.eventPosition.widget;
    player.setDragTarget(_dragTarget);
    super.onPanStart(info);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) {
    if (session.gameOver || session.win) return;
    _dragTarget = info.eventPosition.widget;
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
    captureParticles.spawnFromCapturedCells(playfield.territory, result.newlyCaptured);
    if (session.captured >= session.targetCapturePercent) {
      session.win = true;
      session.score += 500;
      overlays.add(endOverlayId);
      pauseEngine();
    }
    _notifySessionChanged();
  }

  void _lose() {
    if (session.gameOver || session.win) return;
    session.gameOversTotal += 1;
    session.gameOver = true;
    overlays.add(endOverlayId);
    pauseEngine();
    _adService.maybeShowInterstitialForGameOver(session.gameOversTotal);
    _notifySessionChanged();
  }

  Future<bool> tryContinueWithRewardedAd() async {
    if (!session.canContinue) return false;
    final rewarded = await _adService.showRewardedToContinue();
    if (!rewarded) return false;

    captureSystem.cancel();
    _dragTarget = null;
    player.setDragTarget(null);
    player.position = playfield.nearestPointOnSafeEdge(player.position);
    session.markContinued();
    overlays.remove(endOverlayId);
    resumeEngine();
    _notifySessionChanged();
    return true;
  }

  void restartRun() {
    session.reset();
    _theme = LevelThemeGenerator.fromLevel(session.level);
    _resetLevelState();
    overlays.remove(endOverlayId);
    resumeEngine();
    _notifySessionChanged();
  }

  void startNextLevel() {
    session.advanceLevel();
    _theme = LevelThemeGenerator.fromLevel(session.level);
    _resetLevelState();
    overlays.remove(endOverlayId);
    resumeEngine();
    _notifySessionChanged();
  }

  void setLevelForTesting(int level) {
    session.configureForLevel(level);
    _theme = LevelThemeGenerator.fromLevel(session.level);
    _resetLevelState();
    overlays.remove(endOverlayId);
    resumeEngine();
    _notifySessionChanged();
  }

  void _spawnEnemies() {
    final center = Vector2(playfield.bounds.center.dx, playfield.bounds.center.dy);
    enemies.addAll(
      <EnergyOrbEnemy>[
        EnergyOrbEnemy(playfield: playfield, position: center + Vector2(-140, -220)),
        EnergyOrbEnemy(playfield: playfield, position: center + Vector2(130, -160)),
        EnergyOrbEnemy(playfield: playfield, position: center + Vector2(30, 200)),
      ],
    );
    for (final e in enemies) {
      add(e);
    }
  }

  void _resetEnemies() {
    final center = Vector2(playfield.bounds.center.dx, playfield.bounds.center.dy);
    final targets = <Vector2>[
      center + Vector2(-140, -220),
      center + Vector2(130, -160),
      center + Vector2(30, 200),
    ];
    for (var i = 0; i < enemies.length; i++) {
      enemies[i].resetPosition(targets[i % targets.length]);
    }
  }

  void _notifySessionChanged() {
    onSessionChanged?.call(session);
  }

  void _resetLevelState() {
    playfield.rebuild(size);
    playfield.notifyTerritoryChanged();
    captureSystem.cancel();
    territoryRenderer.resetEffects();
    player.position = playfield.initialPlayerPosition();
    _dragTarget = null;
    player.setDragTarget(null);
    _resetEnemies();
  }
}
