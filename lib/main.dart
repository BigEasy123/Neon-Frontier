import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'game/neon_frontier_game.dart';
import 'game/services/ad_service.dart';

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
  late final NeonFrontierGame _game;
  final ValueNotifier<int> _sessionVersion = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _adService = AdService();
    _adService.initialize();
    _game = NeonFrontierGame(
      adService: _adService,
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
        child: GameWidget<NeonFrontierGame>(
          game: _game,
          overlayBuilderMap: <String, Widget Function(BuildContext, NeonFrontierGame)>{
            NeonFrontierGame.endOverlayId: (context, game) {
              return _EndRunOverlay(game: game, sessionVersion: _sessionVersion);
            },
          },
        ),
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
                  Text('Score: ${session.score.toStringAsFixed(0)}'),
                  Text('Captured: ${(session.captured * 100).toStringAsFixed(1)}%'),
                  const SizedBox(height: 16),
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
