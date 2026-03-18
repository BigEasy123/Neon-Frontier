import 'package:flame/components.dart';
import 'package:flame/game.dart';

class Hud extends PositionComponent with HasGameReference<FlameGame> {
  Hud({
    required double Function() scoreProvider,
    required double Function() capturedProvider,
    required double Function() targetProvider,
    required int Function() levelProvider,
    required String Function() playerSkinProvider,
    required String Function() effectsProvider,
    required String? Function() statusProvider,
  }) : _scoreProvider = scoreProvider,
       _capturedProvider = capturedProvider,
       _targetProvider = targetProvider,
       _levelProvider = levelProvider,
       _playerSkinProvider = playerSkinProvider,
       _effectsProvider = effectsProvider,
       _statusProvider = statusProvider;

  final double Function() _scoreProvider;
  final double Function() _capturedProvider;
  final double Function() _targetProvider;
  final int Function() _levelProvider;
  final String Function() _playerSkinProvider;
  final String Function() _effectsProvider;
  final String? Function() _statusProvider;

  late final TextComponent _text;
  late final TextComponent _status;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(16, 16);
    anchor = Anchor.topLeft;

    _text = TextComponent(text: '', textRenderer: TextPaint());
    add(_text);

    _status = TextComponent(
      text: '',
      anchor: Anchor.topCenter,
      position: Vector2(game.size.x / 2, 18),
      textRenderer: TextPaint(),
    );
    add(_status);
  }

  @override
  void update(double dt) {
    final score = _scoreProvider();
    final captured = _capturedProvider() * 100;
    final target = _targetProvider() * 100;
    final level = _levelProvider();
    final skin = _playerSkinProvider();
    final effects = _effectsProvider();
    _text.text =
        'Level: $level\nScore: ${score.toStringAsFixed(0)}\nCaptured: ${captured.toStringAsFixed(1)}% / ${target.toStringAsFixed(0)}%\nShip: $skin\n$effects';
    _status.text = _statusProvider() ?? '';
    super.update(dt);
  }
}
