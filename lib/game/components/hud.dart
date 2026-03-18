import 'package:flame/components.dart';
import 'package:flame/game.dart';

class Hud extends PositionComponent with HasGameReference<FlameGame> {
  Hud({
    required double Function() scoreProvider,
    required double Function() capturedProvider,
    required String? Function() statusProvider,
  })  : _scoreProvider = scoreProvider,
        _capturedProvider = capturedProvider,
        _statusProvider = statusProvider;

  final double Function() _scoreProvider;
  final double Function() _capturedProvider;
  final String? Function() _statusProvider;

  late final TextComponent _text;
  late final TextComponent _status;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(16, 16);
    anchor = Anchor.topLeft;

    _text = TextComponent(
      text: '',
      textRenderer: TextPaint(),
    );
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
    _text.text = 'Score: ${score.toStringAsFixed(0)}\nCaptured: ${captured.toStringAsFixed(1)}%';
    _status.text = _statusProvider() ?? '';
    super.update(dt);
  }
}
