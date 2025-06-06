part of 'graphics.dart';

class RenderBatchState {
  BlendMode blendMode = BlendMode.alpha;

  double lineWidth = 1.0;

  WebGLTexture? texture;

  _PrimitiveType? _primitiveType;

  bool isScissorEnabled = false;

  final Matrix4 projectionMatrix = Matrix4.identity();

  final viewport = Rect<int>();
  final scissor = Rect<int>();
}
