import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';

class AnalyticsService {
  FirebaseAnalytics? _analytics;

  bool get isEnabled => _analytics != null;

  Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _analytics = FirebaseAnalytics.instance;
      await _analytics!.setAnalyticsCollectionEnabled(true);
      await _analytics!.logAppOpen();
    } catch (_) {
      // Keep game running when Firebase isn't configured yet.
      _analytics = null;
    }
  }

  Future<void> logRunStarted({
    required int level,
    required String theme,
  }) =>
      _log(
        'run_started',
        <String, Object>{
          'level': level,
          'theme': theme,
        },
      );

  Future<void> logLevelCompleted({
    required int level,
    required double capturedPercent,
    required double score,
  }) =>
      _log(
        'level_completed',
        <String, Object>{
          'level': level,
          'captured_percent': capturedPercent,
          'score': score,
        },
      );

  Future<void> logGameOver({
    required int level,
    required String reason,
    required double score,
  }) =>
      _log(
        'game_over',
        <String, Object>{
          'level': level,
          'reason': reason,
          'score': score,
        },
      );

  Future<void> logPowerupCollected({
    required String type,
    required int level,
  }) =>
      _log(
        'powerup_collected',
        <String, Object>{
          'type': type,
          'level': level,
        },
      );

  Future<void> logSkinSelected(String skin) =>
      _log('player_skin_selected', <String, Object>{'skin': skin});

  Future<void> logAdContinueUsed() => _log('rewarded_continue_used', const <String, Object>{});

  Future<void> logThemePreview({required int level, required String theme}) =>
      _log(
        'theme_preview_selected',
        <String, Object>{
          'level': level,
          'theme': theme,
        },
      );

  Future<void> _log(String name, Map<String, Object> params) async {
    final analytics = _analytics;
    if (analytics == null) return;
    try {
      await analytics.logEvent(name: name, parameters: params);
    } catch (_) {
      // Best-effort analytics only.
    }
  }
}
