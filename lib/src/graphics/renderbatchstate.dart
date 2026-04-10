part of 'graphics.dart';

class _RenderBatchState {
  BlendMode blendMode = BlendMode.alpha;

  double lineWidth = 1.0;

  Texture? currentTexture;

  _BatchMode? batchMode;

  bool isScissorEnabled = false;

  final Matrix4 projectionMatrix = Matrix4.identity();

  final viewport = Rect<int>();
  final scissor = Rect<int>();
}
