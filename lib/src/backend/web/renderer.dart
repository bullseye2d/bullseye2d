import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart'
    show
        HTMLCanvasElement,
        WebGL2RenderingContext,
        WebGLBuffer,
        WebGLProgram,
        WebGLRenderingContext,
        WebGLShader,
        WebGLUniformLocation,
        WebGLVertexArrayObject;

import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/graphics/blendmode.dart';
import 'package:bullseye2d/src/backend/web/shaders.dart';
import 'package:bullseye2d/src/util/debug.dart';
import 'package:web/web.dart' show WebGLTexture;

/// WebGL implementation of [TextureHandle].
class WebTextureHandle implements TextureHandle {
  final WebGLTexture glTexture;
  @override
  int width;
  @override
  int height;

  WebTextureHandle(this.glTexture, this.width, this.height);
}

typedef _GL = WebGLRenderingContext;

class WebRendererBackend implements RendererBackend {
  final HTMLCanvasElement _canvas;
  final int _batchCapacityInBytes;

  /// The WebGL2 rendering context. Used internally by this backend.
  late final WebGL2RenderingContext gl;

  late final WebGLProgram _program;
  late final int _positionAttributeLocation;
  late final int _texcoordAttributeLocation;
  late final int _colorAttributeLocation;

  late final WebGLUniformLocation _projectionMatrixLocation;
  late final WebGLUniformLocation _textureLocation;

  late final WebGLVertexArrayObject _vao;
  late final WebGLBuffer _interleavedBuffer;
  late final WebGLBuffer _quadIndexBuffer;

  static const int _vertexSizeInBytes = 20;

  double lineWidthMin = 1.0;
  double lineWidthMax = 1.0;

  WebRendererBackend(this._canvas, {int batchCapacityInBytes = 65536}) : _batchCapacityInBytes = batchCapacityInBytes;

  @override
  void init() {
    var glContext = _canvas.getContext("webgl2", {"alpha": false} as dynamic);
    if (glContext == null) throw Exception("Can't create WEBGL!");
    gl = glContext as WebGL2RenderingContext;

    _program = _createProgramFromSources(gl, vertexShaderSource, fragmentShaderSource)!;

    _positionAttributeLocation = gl.getAttribLocation(_program, 'a_position');
    _texcoordAttributeLocation = gl.getAttribLocation(_program, 'a_texcoord');
    _colorAttributeLocation = gl.getAttribLocation(_program, 'a_color');

    if (_positionAttributeLocation < 0 || _texcoordAttributeLocation < 0 || _colorAttributeLocation < 0) {
      die('One or more attributes not found in the shader program.');
    }

    _projectionMatrixLocation = gl.getUniformLocation(_program, 'u_projectionMatrix')!;
    _textureLocation = gl.getUniformLocation(_program, 'u_texture')!;

    _vao = gl.createVertexArray()!;
    gl.bindVertexArray(_vao);

    _interleavedBuffer = gl.createBuffer()!;
    gl.bindBuffer(_GL.ARRAY_BUFFER, _interleavedBuffer);

    final int maxVertices = _batchCapacityInBytes ~/ _vertexSizeInBytes;
    gl.bufferData(_GL.ARRAY_BUFFER, (maxVertices * _vertexSizeInBytes).toJS, _GL.STREAM_DRAW);

    _quadIndexBuffer = gl.createBuffer()!;
    gl.bindBuffer(_GL.ELEMENT_ARRAY_BUFFER, _quadIndexBuffer);

    final int maxQuads = maxVertices ~/ 4;
    final int maxIndices = maxQuads * 6;
    final Uint16List quadIndices = Uint16List(maxIndices);
    for (int i = 0; i < maxQuads; ++i) {
      final int vIndex = i * 4;
      quadIndices
        ..[i * 6 + 0] = (vIndex + 0)
        ..[i * 6 + 1] = (vIndex + 1)
        ..[i * 6 + 2] = (vIndex + 2)
        ..[i * 6 + 3] = (vIndex + 2)
        ..[i * 6 + 4] = (vIndex + 1)
        ..[i * 6 + 5] = (vIndex + 3);
    }

    gl
      ..bufferData(_GL.ELEMENT_ARRAY_BUFFER, quadIndices.buffer.asUint8List().toJS, _GL.STATIC_DRAW)
      ..enableVertexAttribArray(_positionAttributeLocation)
      ..vertexAttribPointer(_positionAttributeLocation, 2, _GL.FLOAT, false, _vertexSizeInBytes, 0)
      ..enableVertexAttribArray(_texcoordAttributeLocation)
      ..vertexAttribPointer(
        _texcoordAttributeLocation,
        2,
        _GL.FLOAT,
        false,
        _vertexSizeInBytes,
        2 * Float32List.bytesPerElement,
      )
      ..enableVertexAttribArray(_colorAttributeLocation)
      ..vertexAttribPointer(
        _colorAttributeLocation,
        4,
        _GL.UNSIGNED_BYTE,
        true,
        _vertexSizeInBytes,
        4 * Float32List.bytesPerElement,
      )
      ..useProgram(_program)
      ..disable(_GL.SCISSOR_TEST);

    final JSAny? param = gl.getParameter(_GL.ALIASED_LINE_WIDTH_RANGE);
    final Float32List lineWidthRange =
        param.isA<JSFloat32Array>() ? (param as JSFloat32Array).toDart : Float32List.fromList([1.0, 1.0]);

    lineWidthMin = lineWidthRange[0];
    lineWidthMax = lineWidthRange[1];
  }

  @override
  void present() {
    // Web: browser auto-presents after the frame callback returns.
  }

  @override
  void dispose() {
    gl
      ..deleteProgram(_program)
      ..deleteVertexArray(_vao)
      ..deleteBuffer(_interleavedBuffer)
      ..deleteBuffer(_quadIndexBuffer);
  }

  @override
  void setViewport(int x, int y, int w, int h) {
    // WebGL origin is bottom-left; flip Y for top-left convention.
    final glY = _canvas.height - h - y;
    gl.viewport(x, glY, w, h);
  }

  @override
  void setScissor(int x, int y, int w, int h) {
    gl.enable(_GL.SCISSOR_TEST);
    final glY = _canvas.height - (y + h);
    gl.scissor(x, glY, w, h);
  }

  @override
  void resetScissor() {
    gl.disable(_GL.SCISSOR_TEST);
  }

  @override
  void clear(double r, double g, double b, double a) {
    gl
      ..clearColor(r, g, b, a)
      ..clear(_GL.COLOR_BUFFER_BIT);
  }

  @override
  void setBlendMode(BlendMode mode) {
    switch (mode) {
      case BlendMode.opaque:
        gl.disable(_GL.BLEND);
      case BlendMode.alpha:
        gl.enable(_GL.BLEND);
        gl.blendFunc(_GL.ONE, _GL.ONE_MINUS_SRC_ALPHA);
      case BlendMode.additive:
        gl.enable(_GL.BLEND);
        gl.blendFunc(_GL.ONE, _GL.ONE);
      case BlendMode.multiply:
        gl.enable(_GL.BLEND);
        gl.blendFunc(_GL.DST_COLOR, _GL.ONE_MINUS_SRC_ALPHA);
      case BlendMode.multiply2:
        gl.enable(_GL.BLEND);
        gl.blendFunc(_GL.DST_COLOR, _GL.ZERO);
      case BlendMode.screen:
        gl.enable(_GL.BLEND);
        gl.blendFunc(_GL.ONE, _GL.ONE_MINUS_SRC_COLOR);
    }
  }

  @override
  void setLineWidth(double w) {
    gl.lineWidth(w);
  }

  @override
  void setProjection(Float32List matrix4) {
    gl.uniformMatrix4fv(_projectionMatrixLocation, false, matrix4.toJS);
  }

  @override
  TextureHandle createTexture(int width, int height, Uint8List pixels, int flags) {
    final tex = gl.createTexture();
    if (tex == null) throw Exception("Could not create texture!");

    gl.bindTexture(_GL.TEXTURE_2D, tex);
    gl.texImage2D(
      _GL.TEXTURE_2D,
      0,
      _GL.RGBA,
      width.toJS,
      height.toJS,
      0.toJS,
      _GL.RGBA,
      _GL.UNSIGNED_BYTE,
      pixels.toJS,
    );

    _applyTextureFlags(flags);

    if (_hasFlag(flags, 0x2 /* mipmap */)) {
      gl.generateMipmap(_GL.TEXTURE_2D);
    }

    return WebTextureHandle(tex, width, height);
  }

  @override
  void updateTexture(TextureHandle texture, int x, int y, int w, int h, Uint8List pixels, int flags) {
    final webTex = texture as WebTextureHandle;
    gl.bindTexture(_GL.TEXTURE_2D, webTex.glTexture);
    gl.texSubImage2D(_GL.TEXTURE_2D, 0, x, y, w.toJS, h.toJS, _GL.RGBA.toJS, _GL.UNSIGNED_BYTE, pixels.toJS);

    if (_hasFlag(flags, 0x2 /* mipmap */)) {
      gl.generateMipmap(_GL.TEXTURE_2D);
    }
  }

  @override
  void destroyTexture(TextureHandle texture) {
    final webTex = texture as WebTextureHandle;
    gl.deleteTexture(webTex.glTexture);
  }

  static bool _hasFlag(int flags, int flag) => (flags & flag) != 0;

  void _applyTextureFlags(int flags) {
    // TextureFlags constants (from texture.dart):
    // filter = 0x1, mipmap = 0x2, clampS = 0x4, clampT = 0x8
    // repeatS = 0x10, repeatT = 0x20, mirroredRepeatS = 0x40, mirroredRepeatT = 0x80
    const filter = 0x1;
    const mipmap = 0x2;
    const clampS = 0x4;
    const clampT = 0x8;
    const repeatS = 0x10;
    const repeatT = 0x20;
    const mirroredRepeatS = 0x40;
    const mirroredRepeatT = 0x80;

    if (_hasFlag(flags, filter)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_MAG_FILTER, _GL.LINEAR);
    } else {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_MAG_FILTER, _GL.NEAREST);
    }

    if (_hasFlag(flags, mipmap) && _hasFlag(flags, filter)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_MIN_FILTER, _GL.LINEAR_MIPMAP_LINEAR);
    } else if (_hasFlag(flags, mipmap)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_MIN_FILTER, _GL.NEAREST_MIPMAP_NEAREST);
    } else if (_hasFlag(flags, filter)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_MIN_FILTER, _GL.LINEAR);
    } else {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_MIN_FILTER, _GL.NEAREST);
    }

    if (_hasFlag(flags, clampS)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_WRAP_S, _GL.CLAMP_TO_EDGE);
    } else if (_hasFlag(flags, repeatS)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_WRAP_S, _GL.REPEAT);
    } else if (_hasFlag(flags, mirroredRepeatS)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_WRAP_S, _GL.MIRRORED_REPEAT);
    } else {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_WRAP_S, _GL.CLAMP_TO_EDGE);
    }

    if (_hasFlag(flags, clampT)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_WRAP_T, _GL.CLAMP_TO_EDGE);
    } else if (_hasFlag(flags, repeatT)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_WRAP_T, _GL.REPEAT);
    } else if (_hasFlag(flags, mirroredRepeatT)) {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_WRAP_T, _GL.MIRRORED_REPEAT);
    } else {
      gl.texParameteri(_GL.TEXTURE_2D, _GL.TEXTURE_WRAP_T, _GL.CLAMP_TO_EDGE);
    }
  }

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

    final int dataSizeInBytes = vertexCount * _vertexSizeInBytes;

    gl
      ..useProgram(_program)
      ..bindVertexArray(_vao)
      ..bindBuffer(_GL.ARRAY_BUFFER, _interleavedBuffer)
      ..bufferData(_GL.ARRAY_BUFFER, _batchCapacityInBytes.toJS, _GL.STREAM_DRAW)
      ..bufferSubData(_GL.ARRAY_BUFFER, 0, vertices.buffer.asUint8List(0, dataSizeInBytes).toJS);

    // Bind texture
    if (texture != null) {
      final webTex = texture as WebTextureHandle;
      gl
        ..activeTexture(_GL.TEXTURE0)
        ..bindTexture(_GL.TEXTURE_2D, webTex.glTexture)
        ..uniform1i(_textureLocation, 0);
    }

    if (indexCount > 0) {
      // Indexed draw (quads → triangles via pre-uploaded index buffer)
      gl
        ..bindBuffer(_GL.ELEMENT_ARRAY_BUFFER, _quadIndexBuffer)
        ..drawElements(_GL.TRIANGLES, indexCount, _GL.UNSIGNED_SHORT, 0)
        ..bindBuffer(_GL.ELEMENT_ARRAY_BUFFER, null);
    } else {
      gl.drawArrays(_toGLPrimitive(primitiveType), 0, vertexCount);
    }
  }

  static int _toGLPrimitive(PrimitiveType type) {
    switch (type) {
      case PrimitiveType.points:
        return _GL.POINTS;
      case PrimitiveType.lines:
        return _GL.LINES;
      case PrimitiveType.lineStrip:
        return _GL.LINE_STRIP;
      case PrimitiveType.triangles:
        return _GL.TRIANGLES;
      case PrimitiveType.triangleFan:
        return _GL.TRIANGLE_FAN;
    }
  }
}

// ---------------------------------------------------------------------------
// Shader compilation helpers (moved from glutil.dart)
// ---------------------------------------------------------------------------

WebGLShader? _compileShader(WebGL2RenderingContext gl, String source, int type) {
  final shader = gl.createShader(type);
  if (shader == null) {
    error('Could not create shader.');
    return null;
  }

  gl.shaderSource(shader, source);
  gl.compileShader(shader);

  if (gl.getShaderParameter(shader, _GL.COMPILE_STATUS) == false.toJS) {
    error('Could not compile shader: ${gl.getShaderInfoLog(shader)}');
    gl.deleteShader(shader);
    return null;
  }
  return shader;
}

WebGLProgram? _createProgramFromSources(
  WebGL2RenderingContext gl,
  String vertexShaderSource,
  String fragmentShaderSource,
) {
  final vertexShader = _compileShader(gl, vertexShaderSource, _GL.VERTEX_SHADER);
  final fragmentShader = _compileShader(gl, fragmentShaderSource, _GL.FRAGMENT_SHADER);

  if (vertexShader == null || fragmentShader == null) {
    return null;
  }

  final program = gl.createProgram();
  if (program == null) {
    error('Could not create program.');
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
    return null;
  }

  gl.attachShader(program, vertexShader);
  gl.attachShader(program, fragmentShader);
  gl.linkProgram(program);

  if (gl.getProgramParameter(program, _GL.LINK_STATUS) == false.toJS) {
    error('Could not link program: ${gl.getProgramInfoLog(program)}');
    gl.deleteProgram(program);
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);
    return null;
  }

  gl.deleteShader(vertexShader);
  gl.deleteShader(fragmentShader);

  return program;
}
