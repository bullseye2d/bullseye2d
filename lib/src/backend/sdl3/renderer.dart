import 'dart:ffi';
import 'dart:typed_data';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/graphics/blendmode.dart';
import 'package:ffi/ffi.dart';
import 'package:sdl3/sdl3.dart';

/// SDL3 [TextureHandle] wrapping an SDL_Texture pointer.
class Sdl3TextureHandle implements TextureHandle {
  final Pointer<SdlTexture> sdlTexture;
  @override
  int width;
  @override
  int height;

  Sdl3TextureHandle(this.sdlTexture, this.width, this.height);
}

/// SDL_Renderer-based implementation of [RendererBackend].
///
/// Uses SDL_RenderGeometryRaw for triangle batches and
/// SDL_RenderLine / SDL_RenderPoint for line/point primitives.
class Sdl3RendererBackend implements RendererBackend {
  final Pointer<SdlWindow> _window;
  final int _batchCapacityInBytes;
  late final Pointer<SdlRenderer> renderer;

  // Pre-allocated native buffers for vertex data transfer
  static const int _vertexSizeInBytes = 20;
  late final int _maxVertices;
  late final Pointer<Uint8> _nativeVertexBuf;
  late final Pointer<SdlFColor> _nativeColorBuf;
  late final Pointer<Uint16> _nativeIndexBuf;

  bool _lineWidthWarned = false;

  // Projection matrix (orthographic) — applied CPU-side since SDL_Renderer has no shaders
  // Initialized to identity
  Float32List _projMatrix = Float32List(16)
    ..[0] = 1.0
    ..[5] = 1.0
    ..[10] = 1.0
    ..[15] = 1.0;
  int _viewportW = 0;
  int _viewportH = 0;

  // Lookup table for uint8 → float color conversion
  static final Float64List _u8ToFloat = Float64List.fromList(
    List.generate(256, (i) => i / 255.0),
  );

  Sdl3RendererBackend(this._window, {int batchCapacityInBytes = 65536})
      : _batchCapacityInBytes = batchCapacityInBytes;

  @override
  void init() {
    renderer = sdlCreateRenderer(_window, null);
    if (renderer == nullptr) {
      throw Exception('Failed to create SDL renderer: ${sdlGetError()}');
    }

    _maxVertices = _batchCapacityInBytes ~/ _vertexSizeInBytes;
    final maxQuads = _maxVertices ~/ 4;
    final maxIndices = maxQuads * 6;

    _nativeVertexBuf = calloc<Uint8>(_maxVertices * _vertexSizeInBytes);
    _nativeColorBuf = calloc<SdlFColor>(_maxVertices);
    _nativeIndexBuf = calloc<Uint16>(maxIndices);
  }

  @override
  void present() {
    sdlRenderPresent(renderer);
  }

  @override
  void dispose() {
    calloc.free(_nativeVertexBuf);
    calloc.free(_nativeColorBuf);
    calloc.free(_nativeIndexBuf);
    sdlDestroyRenderer(renderer);
  }

  @override
  void setViewport(int x, int y, int w, int h) {
    _viewportW = w;
    _viewportH = h;
    final rect = calloc<SdlRect>();
    rect.ref
      ..x = x
      ..y = y
      ..w = w
      ..h = h;
    sdlSetRenderViewport(renderer, rect);
    calloc.free(rect);
  }

  @override
  void setScissor(int x, int y, int w, int h) {
    final rect = calloc<SdlRect>();
    rect.ref
      ..x = x
      ..y = y
      ..w = w
      ..h = h;
    sdlSetRenderClipRect(renderer, rect);
    calloc.free(rect);
  }

  @override
  void resetScissor() {
    sdlSetRenderClipRect(renderer, nullptr);
  }

  @override
  void clear(double r, double g, double b, double a) {
    sdlSetRenderDrawColorFloat(renderer, r, g, b, a);
    sdlRenderClear(renderer);
  }

  @override
  void setBlendMode(BlendMode mode) {
    final int sdlMode;
    switch (mode) {
      case BlendMode.opaque:
        sdlMode = SDL_BLENDMODE_NONE;
      case BlendMode.alpha:
        sdlMode = SDL_BLENDMODE_BLEND_PREMULTIPLIED;
      case BlendMode.additive:
        sdlMode = SDL_BLENDMODE_ADD;
      case BlendMode.multiply:
        sdlMode = SDL_BLENDMODE_MUL;
      case BlendMode.multiply2:
        sdlMode = SDL_BLENDMODE_MOD;
      case BlendMode.screen:
        // SDL3 has no direct screen blend mode; approximate with ADD_PREMULTIPLIED
        sdlMode = SDL_BLENDMODE_ADD_PREMULTIPLIED;
    }
    sdlSetRenderDrawBlendMode(renderer, sdlMode);
  }

  @override
  void setLineWidth(double w) {
    if (w != 1.0 && !_lineWidthWarned) {
      _lineWidthWarned = true;
      print('[bullseye2d] Warning: setLineWidth() is not supported on SDL3 (Dart bindings lack SDL_SetRenderDrawLineWidth)');
    }
  }

  @override
  void setProjection(Float32List matrix4) {
    _projMatrix = Float32List.fromList(matrix4);
  }

  /// Apply the projection matrix to a vertex position and map to viewport pixels.
  /// The orthographic projection maps virtual coords → NDC (-1..1),
  /// then we map NDC → viewport pixel coords for SDL_Renderer.
  void _projectVertex(Float32List vertices, int floatIndex) {
    final x = vertices[floatIndex];
    final y = vertices[floatIndex + 1];
    // Column-major 4x4: clipX = m[0]*x + m[4]*y + m[12], clipY = m[1]*x + m[5]*y + m[13]
    final clipX = _projMatrix[0] * x + _projMatrix[4] * y + _projMatrix[12];
    final clipY = _projMatrix[1] * x + _projMatrix[5] * y + _projMatrix[13];
    // NDC to viewport pixels (Y flipped: NDC +1=top but SDL +Y=down)
    vertices[floatIndex] = (clipX + 1.0) * 0.5 * _viewportW;
    vertices[floatIndex + 1] = (1.0 - clipY) * 0.5 * _viewportH;
  }

  @override
  TextureHandle createTexture(int width, int height, Uint8List pixels, int flags) {
    final tex = sdlCreateTexture(renderer, SDL_PIXELFORMAT_ABGR8888, SDL_TEXTUREACCESS_STATIC, width, height);
    if (tex == nullptr) {
      throw Exception('Failed to create texture: ${sdlGetError()}');
    }

    // Upload pixel data
    final nativePixels = calloc<Uint8>(pixels.length);
    nativePixels.asTypedList(pixels.length).setAll(0, pixels);
    sdlUpdateTexture(tex, nullptr, nativePixels.cast(), width * 4);
    calloc.free(nativePixels);

    // Apply texture flags
    _applyTextureFlags(tex, flags);

    return Sdl3TextureHandle(tex, width, height);
  }

  @override
  void updateTexture(TextureHandle texture, int x, int y, int w, int h, Uint8List pixels, int flags) {
    final nativeTex = texture as Sdl3TextureHandle;
    final rect = calloc<SdlRect>();
    rect.ref
      ..x = x
      ..y = y
      ..w = w
      ..h = h;

    final nativePixels = calloc<Uint8>(pixels.length);
    nativePixels.asTypedList(pixels.length).setAll(0, pixels);
    sdlUpdateTexture(nativeTex.sdlTexture, rect, nativePixels.cast(), w * 4);
    calloc.free(nativePixels);
    calloc.free(rect);
  }

  @override
  void destroyTexture(TextureHandle texture) {
    final nativeTex = texture as Sdl3TextureHandle;
    sdlDestroyTexture(nativeTex.sdlTexture);
  }

  void _applyTextureFlags(Pointer<SdlTexture> tex, int flags) {
    const filter = 0x1;
    const mipmap = 0x2;

    if (_hasFlag(flags, filter) || _hasFlag(flags, mipmap)) {
      sdlSetTextureScaleMode(tex, SDL_SCALEMODE_LINEAR);
    } else {
      sdlSetTextureScaleMode(tex, SDL_SCALEMODE_NEAREST);
    }

    // SDL_Renderer handles wrap modes internally; no per-texture wrap mode API.
    // Blend mode for textures — enable alpha blending by default.
    sdlSetTextureBlendMode(tex, SDL_BLENDMODE_BLEND);
  }

  static bool _hasFlag(int flags, int flag) => (flags & flag) != 0;

  @override
  void drawGeometry({
    required TextureHandle? texture,
    required Float32List vertices,
    required int vertexCount,
    required Uint16List indices,
    required int indexCount,
    required PrimitiveType primitiveType,
  }) {
    if (vertexCount == 0) return;

    switch (primitiveType) {
      case PrimitiveType.triangles:
        _drawTriangles(texture, vertices, vertexCount, indices, indexCount);
      case PrimitiveType.triangleFan:
        _drawTriangleFan(texture, vertices, vertexCount);
      case PrimitiveType.lines:
        _drawLines(vertices, vertexCount);
      case PrimitiveType.lineStrip:
        _drawLineStrip(vertices, vertexCount);
      case PrimitiveType.points:
        _drawPoints(vertices, vertexCount);
    }
  }

  void _drawTriangles(
    TextureHandle? texture,
    Float32List vertices,
    int vertexCount,
    Uint16List indices,
    int indexCount,
  ) {
    // Apply projection matrix to vertex positions (in-place on the source buffer,
    // which is the Graphics batch buffer — it gets reset after flush anyway)
    const floatsPerVertex = 5; // x, y, u, v, color(as float bits)
    for (int i = 0; i < vertexCount; i++) {
      _projectVertex(vertices, i * floatsPerVertex);
    }

    final dataSizeInBytes = vertexCount * _vertexSizeInBytes;
    final vertexBytes = vertices.buffer.asUint8List(0, dataSizeInBytes);

    // Copy vertex position+UV data to native buffer
    _nativeVertexBuf.asTypedList(dataSizeInBytes).setAll(0, vertexBytes);

    // Convert colors: extract RGBA bytes from each vertex and write as SdlFColor floats
    final byteData = vertices.buffer.asByteData();
    for (int i = 0; i < vertexCount; i++) {
      final colorByteOffset = i * _vertexSizeInBytes + 16;
      final r = byteData.getUint8(colorByteOffset + 0);
      final g = byteData.getUint8(colorByteOffset + 1);
      final b = byteData.getUint8(colorByteOffset + 2);
      final a = byteData.getUint8(colorByteOffset + 3);

      final colorPtr = _nativeColorBuf + i;
      colorPtr.ref
        ..r = _u8ToFloat[r]
        ..g = _u8ToFloat[g]
        ..b = _u8ToFloat[b]
        ..a = _u8ToFloat[a];
    }

    // Copy indices to native buffer
    if (indexCount > 0) {
      _nativeIndexBuf.asTypedList(indexCount).setAll(0, indices.buffer.asUint16List(0, indexCount));
    }

    final Pointer<SdlTexture> sdlTex;
    if (texture != null) {
      sdlTex = (texture as Sdl3TextureHandle).sdlTexture;
    } else {
      sdlTex = nullptr;
    }

    // xy pointer: first float pair at offset 0, stride 20 bytes
    final xyPtr = _nativeVertexBuf.cast<Float>();
    // uv pointer: float pair at offset 8 bytes, stride 20 bytes
    final uvPtr = (_nativeVertexBuf + 8).cast<Float>();

    if (indexCount > 0) {
      sdlRenderGeometryRaw(
        renderer,
        sdlTex,
        xyPtr,
        _vertexSizeInBytes,
        _nativeColorBuf,
        sizeOf<SdlFColor>(),
        uvPtr,
        _vertexSizeInBytes,
        vertexCount,
        _nativeIndexBuf.cast(),
        indexCount,
        2, // sizeIndices = 2 for Uint16
      );
    } else {
      sdlRenderGeometryRaw(
        renderer,
        sdlTex,
        xyPtr,
        _vertexSizeInBytes,
        _nativeColorBuf,
        sizeOf<SdlFColor>(),
        uvPtr,
        _vertexSizeInBytes,
        vertexCount,
        nullptr,
        0,
        0,
      );
    }
  }

  void _drawTriangleFan(TextureHandle? texture, Float32List vertices, int vertexCount) {
    if (vertexCount < 3) return;
    // Convert fan to triangles: (0,1,2), (0,2,3), (0,3,4), ...
    final numTriangles = vertexCount - 2;
    final indexCount = numTriangles * 3;
    final fanIndices = Uint16List(indexCount);
    for (int i = 0; i < numTriangles; i++) {
      fanIndices[i * 3 + 0] = 0;
      fanIndices[i * 3 + 1] = i + 1;
      fanIndices[i * 3 + 2] = i + 2;
    }
    _drawTriangles(texture, vertices, vertexCount, fanIndices, indexCount);
  }

  void _drawLines(Float32List vertices, int vertexCount) {
    const fpv = 5;
    for (int i = 0; i < vertexCount; i++) {
      _projectVertex(vertices, i * fpv);
    }
    final byteData = vertices.buffer.asByteData();
    for (int i = 0; i + 1 < vertexCount; i += 2) {
      _setDrawColorFromVertex(byteData, i);
      sdlRenderLine(renderer, vertices[i * fpv], vertices[i * fpv + 1], vertices[(i + 1) * fpv], vertices[(i + 1) * fpv + 1]);
    }
  }

  void _drawLineStrip(Float32List vertices, int vertexCount) {
    if (vertexCount < 2) return;
    const fpv = 5;
    for (int i = 0; i < vertexCount; i++) {
      _projectVertex(vertices, i * fpv);
    }
    final byteData = vertices.buffer.asByteData();
    for (int i = 0; i + 1 < vertexCount; i++) {
      _setDrawColorFromVertex(byteData, i);
      sdlRenderLine(renderer, vertices[i * fpv], vertices[i * fpv + 1], vertices[(i + 1) * fpv], vertices[(i + 1) * fpv + 1]);
    }
  }

  void _drawPoints(Float32List vertices, int vertexCount) {
    const fpv = 5;
    for (int i = 0; i < vertexCount; i++) {
      _projectVertex(vertices, i * fpv);
    }
    final byteData = vertices.buffer.asByteData();
    for (int i = 0; i < vertexCount; i++) {
      _setDrawColorFromVertex(byteData, i);
      sdlRenderPoint(renderer, vertices[i * fpv], vertices[i * fpv + 1]);
    }
  }

  void _setDrawColorFromVertex(ByteData byteData, int vertexIndex) {
    final offset = vertexIndex * _vertexSizeInBytes + 16;
    sdlSetRenderDrawColor(
      renderer,
      byteData.getUint8(offset + 0),
      byteData.getUint8(offset + 1),
      byteData.getUint8(offset + 2),
      byteData.getUint8(offset + 3),
    );
  }
}
