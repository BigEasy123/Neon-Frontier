import 'dart:math' as math;

import 'package:flame/events.dart';
import 'package:flame/game.dart';

import 'components/capture_particles.dart';
import 'components/energy_orb_enemy.dart';
import 'components/hud.dart';
import 'components/lava_lamp_background.dart';
import 'components/powerup_pickup.dart';
import 'components/player_orb.dart';
import 'components/territory_renderer.dart';
import 'playfield/playfield.dart';
import 'playfield/territory_grid.dart';
import 'services/ad_service.dart';
import 'services/analytics_service.dart';
import 'state/game_session.dart';
import 'state/level_theme.dart';
import 'state/player_skin.dart';
import 'systems/capture_system.dart';

class NeonFrontierGame extends FlameGame with PanDetector {
  NeonFrontierGame({
    required AdService adService,
    required AnalyticsService analyticsService,
    this.onSessionChanged,
  }) : _adService = adService,
       _analytics = analyticsService;

  static const String endOverlayId = 'end_overlay';

  late final Playfield playfield;
  late final TerritoryRenderer territoryRenderer;
  late final CaptureParticles captureParticles;
  late final CaptureSystem captureSystem;
  late final PlayerOrb player;
  final List<EnergyOrbEnemy> enemies = <EnergyOrbEnemy>[];
  final List<PowerupPickup> powerups = <PowerupPickup>[];
  final GameSession session = GameSession();
  final AdService _adService;
  final AnalyticsService _analytics;
  final void Function(GameSession session)? onSessionChanged;
  late LevelTheme _theme;
  final math.Random _rng = math.Random(19);
  PlayerSkin _selectedSkin = PlayerSkin.orb;
  double _powerupSpawnTimer = 6;
  double _speedBoostRemaining = 0;
  double _freezeRemaining = 0;
  double _immunityRemaining = 0;

  Vector2? _dragTarget;
  bool _initialized = false;

  LevelTheme get currentTheme => _theme;
  PlayerSkin get selectedSkin => _selectedSkin;

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
    )..skin = _selectedSkin;

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
        playerSkinProvider: () => _skinLabel(_selectedSkin),
        effectsProvider: _effectsStatusLabel,
        statusProvider: () {
          if (session.win) return 'You win';
          if (session.gameOver) return 'Game Over';
          return null;
        },
      ),
    );
    _initialized = true;
    _analytics.logRunStarted(level: session.level, theme: _theme.name);
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
    _updatePowerupEffects(dt);
    _maybeSpawnPowerup(dt);
    _checkPowerupPickups();
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
      _analytics.logLevelCompleted(
        level: session.level,
        capturedPercent: session.captured,
        score: session.score,
      );
      overlays.add(endOverlayId);
      pauseEngine();
    }
    _notifySessionChanged();
  }

  void _lose() {
    if (_immunityRemaining > 0) {
      return;
    }
    if (session.gameOver || session.win) return;
    session.gameOversTotal += 1;
    session.gameOver = true;
    _analytics.logGameOver(
      level: session.level,
      reason: 'capture_line_hit',
      score: session.score,
    );
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
    _analytics.logAdContinueUsed();
    overlays.remove(endOverlayId);
    resumeEngine();
    _notifySessionChanged();
    return true;
  }

  void restartRun() {
    session.reset();
    _theme = LevelThemeGenerator.fromLevel(session.level);
    _resetLevelState();
    _analytics.logRunStarted(level: session.level, theme: _theme.name);
    overlays.remove(endOverlayId);
    resumeEngine();
    _notifySessionChanged();
  }

  void startNextLevel() {
    session.advanceLevel();
    _theme = LevelThemeGenerator.fromLevel(session.level);
    _resetLevelState();
    _analytics.logRunStarted(level: session.level, theme: _theme.name);
    overlays.remove(endOverlayId);
    resumeEngine();
    _notifySessionChanged();
  }

  void setLevelForTesting(int level) {
    session.configureForLevel(level);
    _theme = LevelThemeGenerator.fromLevel(session.level);
    _resetLevelState();
    _analytics.logThemePreview(level: session.level, theme: _theme.name);
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
    player.skin = _selectedSkin;
    _speedBoostRemaining = 0;
    _freezeRemaining = 0;
    _immunityRemaining = 0;
    _powerupSpawnTimer = 3 + _rng.nextDouble() * 4;
    for (final p in powerups) {
      p.removeFromParent();
    }
    powerups.clear();
    _resetEnemies();
    for (final e in enemies) {
      e.frozen = false;
    }
  }

  void setPlayerSkin(PlayerSkin skin) {
    _selectedSkin = skin;
    if (_initialized) {
      player.skin = skin;
      _analytics.logSkinSelected(_skinLabel(skin));
      _notifySessionChanged();
    }
  }

  void _updatePowerupEffects(double dt) {
    if (session.gameOver || session.win) return;

    _speedBoostRemaining = (_speedBoostRemaining - dt).clamp(0, 9999).toDouble();
    _freezeRemaining = (_freezeRemaining - dt).clamp(0, 9999).toDouble();
    _immunityRemaining = (_immunityRemaining - dt).clamp(0, 9999).toDouble();

    player.speedMultiplier = _speedBoostRemaining > 0 ? 1.65 : 1.0;
    final frozen = _freezeRemaining > 0;
    for (final e in enemies) {
      e.frozen = frozen;
    }
  }

  void _maybeSpawnPowerup(double dt) {
    if (session.gameOver || session.win) return;
    _powerupSpawnTimer -= dt;
    if (_powerupSpawnTimer > 0) return;
    _powerupSpawnTimer = 7 + _rng.nextDouble() * 8;
    if (powerups.length >= 2) return;

    final rect = playfield.bounds.deflate(52);
    if (rect.width <= 0 || rect.height <= 0) return;

    final pos = Vector2(
      rect.left + _rng.nextDouble() * rect.width,
      rect.top + _rng.nextDouble() * rect.height,
    );
    final type = _rollPowerupType();
    final pickup = PowerupPickup(type: type, position: pos);
    powerups.add(pickup);
    add(pickup);
  }

  PowerupType _rollPowerupType() {
    final level = session.level;
    final levelPenalty = (level - 1) * 0.045;

    // Higher levels reduce support utility, especially top-tier effects.
    final speedWeight = (1.0 - levelPenalty * 0.55).clamp(0.55, 1.0);
    final immunityWeight = (_immunityRemaining > 0 ? 0.35 : 0.70 - levelPenalty * 0.45).clamp(0.28, 0.70);
    final freezeWeight = (_freezeRemaining > 0 ? 0.18 : 0.26 - levelPenalty * 0.62).clamp(0.06, 0.26);
    final nextLevelWeight = (0.12 - levelPenalty * 0.95).clamp(0.015, 0.12);

    final table = <(PowerupType, double)>[
      (PowerupType.speedBoost, speedWeight),
      (PowerupType.immunity, immunityWeight),
      (PowerupType.enemyFreeze, freezeWeight),
      (PowerupType.nextLevel, nextLevelWeight),
    ];

    final total = table.fold<double>(0, (sum, e) => sum + e.$2);
    var roll = _rng.nextDouble() * total;
    for (final entry in table) {
      roll -= entry.$2;
      if (roll <= 0) return entry.$1;
    }
    return table.last.$1;
  }

  void _checkPowerupPickups() {
    if (session.gameOver || session.win) return;
    for (final pickup in List<PowerupPickup>.from(powerups)) {
      final dist = pickup.position.distanceTo(player.position);
      if (dist > pickup.radius + player.radius) continue;
      pickup.removeFromParent();
      powerups.remove(pickup);
      _applyPowerup(pickup.type);
      if (pickup.type == PowerupType.nextLevel) {
        return;
      }
    }
  }

  void _applyPowerup(PowerupType type) {
    _analytics.logPowerupCollected(type: _powerupLabel(type), level: session.level);
    switch (type) {
      case PowerupType.speedBoost:
        _speedBoostRemaining = math.max(_speedBoostRemaining, 8);
        session.score += 60;
        break;
      case PowerupType.nextLevel:
        session.score += 120;
        startNextLevel();
        return;
      case PowerupType.enemyFreeze:
        _freezeRemaining = math.max(_freezeRemaining, 12);
        session.score += 70;
        break;
      case PowerupType.immunity:
        _immunityRemaining = math.max(_immunityRemaining, 10);
        session.score += 80;
        break;
    }
    _notifySessionChanged();
  }

  String _powerupLabel(PowerupType type) {
    switch (type) {
      case PowerupType.speedBoost:
        return 'speed_boost';
      case PowerupType.nextLevel:
        return 'next_level';
      case PowerupType.enemyFreeze:
        return 'enemy_freeze';
      case PowerupType.immunity:
        return 'immunity';
    }
  }

  String _effectsStatusLabel() {
    final chunks = <String>[];
    if (_speedBoostRemaining > 0) {
      chunks.add('SPD ${_speedBoostRemaining.ceil()}s');
    }
    if (_freezeRemaining > 0) {
      chunks.add('FREEZE ${_freezeRemaining.ceil()}s');
    }
    if (_immunityRemaining > 0) {
      chunks.add('IMMUNE ${_immunityRemaining.ceil()}s');
    }
    if (chunks.isEmpty) {
      return 'Powerups: none';
    }
    return 'Powerups: ${chunks.join(' | ')}';
  }

  String _skinLabel(PlayerSkin skin) {
    switch (skin) {
      case PlayerSkin.orb:
        return 'Orb';
      case PlayerSkin.square:
        return 'Square';
      case PlayerSkin.triangle:
        return 'Triangle';
    }
  }
}
