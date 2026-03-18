import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/neon_frontier_game.dart';
import 'game/services/ad_service.dart';
import 'game/services/analytics_service.dart';
import 'game/state/player_skin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeonFrontierApp());
}

class NeonFrontierApp extends StatelessWidget {
  const NeonFrontierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Frontier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF06060A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8A7CFF),
          secondary: Color(0xFF2EF2FF),
          surface: Color(0xFF0B0B12),
        ),
      ),
      home: const NeonFrontierHome(),
    );
  }
}

class NeonFrontierHome extends StatefulWidget {
  const NeonFrontierHome({super.key});

  @override
  State<NeonFrontierHome> createState() => _NeonFrontierHomeState();
}

class _NeonFrontierHomeState extends State<NeonFrontierHome> {
  late final AdService _adService;
  late final AnalyticsService _analyticsService;
  late final NeonFrontierGame _game;
  final ValueNotifier<int> _sessionVersion = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _adService = AdService();
    _adService.initialize();
    _analyticsService = AnalyticsService();
    _analyticsService.initialize();
    _game = NeonFrontierGame(
      adService: _adService,
      analyticsService: _analyticsService,
      onSessionChanged: (_) {
        _sessionVersion.value++;
      },
    );
  }

  @override
  void dispose() {
    _sessionVersion.dispose();
    _adService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            GameWidget<NeonFrontierGame>(
              game: _game,
              overlayBuilderMap: <String, Widget Function(BuildContext, NeonFrontierGame)>{
                NeonFrontierGame.endOverlayId: (context, game) {
                  return _EndRunOverlay(game: game, sessionVersion: _sessionVersion);
                },
              },
            ),
            Positioned(
              right: 10,
              top: 10,
              child: _ThemeTestPanel(game: _game, sessionVersion: _sessionVersion),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeTestPanel extends StatelessWidget {
  const _ThemeTestPanel({
    required this.game,
    required this.sessionVersion,
  });

  final NeonFrontierGame game;
  final ValueNotifier<int> sessionVersion;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: sessionVersion,
      builder: (context, _, __) {
        if (!game.isLoaded) {
          return const SizedBox.shrink();
        }
        final session = game.session;
        final theme = game.currentTheme;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xAA0B0B12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF2EF2FF).withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text('Theme Test', style: Theme.of(context).textTheme.labelLarge),
              Text('L${session.level}: ${theme.name}', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: () => game.setLevelForTesting(session.level - 1),
                    child: const Text('Theme -'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () => game.setLevelForTesting(session.level + 1),
                    child: const Text('Theme +'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('Ship', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: <Widget>[
                  _SkinChip(
                    label: 'Orb',
                    selected: game.selectedSkin == PlayerSkin.orb,
                    onTap: () => game.setPlayerSkin(PlayerSkin.orb),
                  ),
                  _SkinChip(
                    label: 'Square',
                    selected: game.selectedSkin == PlayerSkin.square,
                    onTap: () => game.setPlayerSkin(PlayerSkin.square),
                  ),
                  _SkinChip(
                    label: 'Triangle',
                    selected: game.selectedSkin == PlayerSkin.triangle,
                    onTap: () => game.setPlayerSkin(PlayerSkin.triangle),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SkinChip extends StatelessWidget {
  const _SkinChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? const Color(0xFF2EF2FF).withValues(alpha: 0.25) : const Color(0x22171D2A),
          border: Border.all(
            color: selected ? const Color(0xFF2EF2FF) : const Color(0x664A5C7A),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _EndRunOverlay extends StatefulWidget {
  const _EndRunOverlay({
    required this.game,
    required this.sessionVersion,
  });

  final NeonFrontierGame game;
  final ValueNotifier<int> sessionVersion;

  @override
  State<_EndRunOverlay> createState() => _EndRunOverlayState();
}

class _EndRunOverlayState extends State<_EndRunOverlay> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xAA04040A),
      child: Center(
        child: ValueListenableBuilder<int>(
          valueListenable: widget.sessionVersion,
          builder: (context, _, __) {
            final session = widget.game.session;
            final title = session.win ? 'Neon Frontier Secured' : 'Frontier Breached';
            return Container(
              width: 320,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xCC0B0B12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2EF2FF).withValues(alpha: 0.4)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(color: Color(0x552EF2FF), blurRadius: 20),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text('Level: ${session.level}'),
                  Text('Score: ${session.score.toStringAsFixed(0)}'),
                  Text(
                    'Captured: ${(session.captured * 100).toStringAsFixed(1)}% / ${(session.targetCapturePercent * 100).toStringAsFixed(0)}%',
                  ),
                  const SizedBox(height: 16),
                  if (session.win)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () {
                                widget.game.startNextLevel();
                              },
                        child: const Text('Next Level'),
                      ),
                    ),
                  if (session.canContinue)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                await widget.game.tryContinueWithRewardedAd();
                                if (mounted) {
                                  setState(() => _busy = false);
                                }
                              },
                        child: Text(_busy ? 'Loading ad...' : 'Continue (Rewarded Ad)'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _busy
                          ? null
                          : () {
                              widget.game.restartRun();
                            },
                      child: const Text('Restart Run'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
