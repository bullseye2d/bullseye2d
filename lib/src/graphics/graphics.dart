// ignore_for_file: lines_longer_than_80_chars
import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart'
    show
        ElementEventGetters,
        Event,
        HTMLCanvasElement,
        WebGL2RenderingContext,
        WebGLBuffer,
        WebGLProgram,
        WebGLRenderingContext,
        WebGLShader,
        WebGLUniformLocation,
        WebGLVertexArrayObject,
        WebGLTexture;
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:vector_math/vector_math_64.dart';

export 'dart:math' show min, Point, sqrt, sin, cos, pi;

part 'glutil.dart';
part 'primitivetype.dart';
part 'renderbatchstate.dart';

// TODO: Error Handling is still missing (especially lostGLContext and restoreGLContext Events)

/// A simple object pool for Matrix3 instances to reduce GC pressure.
///
/// Manages a list of reusable [Matrix3] objects. When the pool is exhausted,
/// it automatically expands by doubling its total capacity.
class _MatrixPool {
  final List<Matrix3> _pool = [];
  int _totalCreated = 0;
  final int _initialSize;

  _MatrixPool({int initialSize = 10}) : _initialSize = initialSize {
    _expandPool(_initialSize);
  }

  void _expandPool(int amount) {
    for (var i = 0; i < amount; i++) {
      _pool.add(Matrix3.identity());
    }
    _totalCreated += amount;
  }

  /// Gets a [Matrix3] from the pool.
  ///
  /// If the pool is empty, it doubles the total number of created matrices,
  /// adds them to the pool, and returns one.
  Matrix3 get() {
    if (_pool.isEmpty) {
      final amountToCreate = _totalCreated > 0 ? _totalCreated : _initialSize;
      warn('[Graphics] Matrix pool exhausted. Expanding by $amountToCreate matrices.');
      _expandPool(amountToCreate);
    }
    return _pool.removeLast();
  }

  /// Returns a [Matrix3] to the pool for reuse.
  void put(Matrix3 matrix) {
    _pool.add(matrix);
  }
}

/// {@category Graphics}
/// Provides the core 2D rendering capabilities for the Bullseye2D engine.
///
/// Most applications will interact with this class through the `app.gfx`
/// instance provided by the [App] class.
class Graphics {
  /// A 2D rendering module.
  ///
  /// This class provides easy to use commands to render images and draw
  /// primitives.
  late final GL2 gl;

  final HTMLCanvasElement _canvas;

  final _renderState = RenderBatchState();

  late final WebGLProgram _program;
  late final int _positionAttributeLocation;
  late final int _texcoordAttributeLocation;
  late final int _colorAttributeLocation;

  late final WebGLUniformLocation _projectionMatrixLocation;
  late final WebGLUniformLocation _textureLocation;

  late final WebGLVertexArrayObject _vao;
  late final WebGLBuffer _interleavedBuffer;
  late final WebGLBuffer _quadIndexBuffer;

  var _vertexCount = 0;

  late final int _currentBatchCapacityVertices;
  late final int _batchCapacityInBytes;
  late final int _initialBatchCapacityQuads;

  static const int _vertexSizeInBytes = 20;
  static const int _floatsPerVertex = _vertexSizeInBytes ~/ Float32List.bytesPerElement;

  late final Float32List _batchedInterleavedData;
  late final ByteData _byteDataView;

  var _lineWidthMin = 1.0;
  var _lineWidthMax = 1.0;

  late final _MatrixPool _matrixPool;
  late Matrix3 _currentMatrix;
  final List<Matrix3> _matrixStack = [];

  final _tempVector = Vector3.zero();
  final _tempMatrix = Matrix3.identity();

  final _currentColor = Color(1.0, 1.0, 1.0, 1.0);
  int _encodedColor = 0xffffffff;

  /// Initializes the graphics system with the given HTML canvas element.
  ///
  /// - [_canvas]: The [HTMLCanvasElement] to render to.
  /// - [batchCapacityInBytes]: The initial capacity of the vertex buffer for
  ///   batched rendering, in bytes. Larger values can improve performance by
  ///   reducing draw calls but will consume more memory. Defaults to 65536 bytes (64KB).
  ///
  /// Typically, you don't instantiate this class yourself. Instead, you use
  /// the `app.gfx` member provided by the [App] class.
  Graphics(this._canvas, {int batchCapacityInBytes = 65536}) {
    _batchCapacityInBytes = batchCapacityInBytes;
    _initialBatchCapacityQuads = _batchCapacityInBytes ~/ (_vertexSizeInBytes * 4);
    _currentBatchCapacityVertices = _initialBatchCapacityQuads * 4;
    _batchedInterleavedData = Float32List(_initialBatchCapacityQuads * 4 * _floatsPerVertex);

    _canvas
      ..onWebGlContextLost.listen((Event event) {
        event.preventDefault();
        warn("[webgl] :: context lost");
      })
      ..onWebGlContextRestored.listen((_) {
        warn("[webgl] :: context restored");
      });

    var glContext = _canvas.getContext("webgl2", {"alpha": false} as dynamic);
    if (glContext == null) throw Exception("Can't create WEBGL!");
    gl = glContext as WebGL2RenderingContext;

    _byteDataView = _batchedInterleavedData.buffer.asByteData();

    _matrixPool = _MatrixPool(initialSize: 10);
    _currentMatrix = _matrixPool.get()..setIdentity();

    _program = _createProgramFromSources(gl, vertexShaderSource, fragmentShaderSource)!;

    _positionAttributeLocation = gl.getAttribLocation(_program, 'a_position');
    _texcoordAttributeLocation = gl.getAttribLocation(_program, 'a_texcoord');
    _colorAttributeLocation = gl.getAttribLocation(_program, 'a_color');

    if (_positionAttributeLocation < 0 || _texcoordAttributeLocation < 0 || _colorAttributeLocation < 0) {
      die('One or more attributes not found in the _program.');
    }

    _projectionMatrixLocation = gl.getUniformLocation(_program, 'u_projectionMatrix')!;
    _textureLocation = gl.getUniformLocation(_program, 'u_texture')!;

    _vao = gl.createVertexArray()!;
    gl.bindVertexArray(_vao);

    _interleavedBuffer = gl.createBuffer()!;
    gl.bindBuffer(GL.ARRAY_BUFFER, _interleavedBuffer);

    gl.bufferData(GL.ARRAY_BUFFER, (_batchedInterleavedData.lengthInBytes).toJS, GL.STREAM_DRAW);

    _quadIndexBuffer = gl.createBuffer()!;
    gl.bindBuffer(GL.ELEMENT_ARRAY_BUFFER, _quadIndexBuffer);

    final int maxQuads = _currentBatchCapacityVertices ~/ 4;
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
      ..bufferData(GL.ELEMENT_ARRAY_BUFFER, quadIndices.buffer.asUint8List().toJS, GL.STATIC_DRAW)
      ..enableVertexAttribArray(_positionAttributeLocation)
      ..vertexAttribPointer(_positionAttributeLocation, 2, GL.FLOAT, false, _vertexSizeInBytes, 0)
      ..enableVertexAttribArray(_texcoordAttributeLocation)
      ..vertexAttribPointer(
        _texcoordAttributeLocation,
        2,
        GL.FLOAT,
        false,
        _vertexSizeInBytes,
        2 * Float32List.bytesPerElement,
      )
      ..enableVertexAttribArray(_colorAttributeLocation)
      ..vertexAttribPointer(
        _colorAttributeLocation,
        4,
        GL.UNSIGNED_BYTE,
        true,
        _vertexSizeInBytes,
        4 * Float32List.bytesPerElement,
      )
      ..useProgram(_program)
      ..disable(GL.SCISSOR_TEST)
      ..lineWidth(_renderState.lineWidth);

    final JSAny? param = gl.getParameter(GL.ALIASED_LINE_WIDTH_RANGE);
    final Float32List lineWidthRange =
        param.isA<JSFloat32Array>() ? (param as JSFloat32Array).toDart : Float32List.fromList([1.0, 1.0]);

    _lineWidthMin = lineWidthRange[0];
    _lineWidthMax = lineWidthRange[1];

    set2DProjection(width: _canvas.clientWidth.toDouble(), height: _canvas.clientHeight.toDouble());

    _renderState
      ..isScissorEnabled = false
      ..blendMode.apply(gl);
    Texture.white = Texture.createWhite(gl);
  }

  /// Releases WebGL resources used by the graphics system.
  void dispose() {
    flush();
    gl
      ..deleteProgram(_program)
      ..deleteVertexArray(_vao)
      ..deleteBuffer(_interleavedBuffer)
      ..deleteBuffer(_quadIndexBuffer);
  }

  /// Clears the drawing canvas with the specified color.
  ///
  /// If no color components are provided, it uses the current color set by
  /// [setColor] or [setColorFrom].
  ///
  /// - [r]: Red component (0.0 to 1.0).
  /// - [g]: Green component (0.0 to 1.0).
  /// - [b]: Blue component (0.0 to 1.0).
  /// - [a]: Alpha component (0.0 to 1.0).
  void clear([double? r, double? g, double? b, double? a]) {
    flush();
    gl
      ..clearColor(r ?? _currentColor.r, g ?? _currentColor.g, b ?? _currentColor.b, a ?? _currentColor.a)
      ..clear(GL.COLOR_BUFFER_BIT);
  }

  /// Sets the current drawing color using individual RGBA components.
  ///
  /// This color will be used for subsequent drawing operations that don't
  /// specify per-vertex colors or use textures that override it.
  ///
  /// - [r]: Red component (0.0 to 1.0). Defaults to 1.0.
  /// - [g]: Green component (0.0 to 1.0). Defaults to 1.0.
  /// - [b]: Blue component (0.0 to 1.0). Defaults to 1.0.
  /// - [a]: Alpha component (0.0 to 1.0). Defaults to 1.0.
  void setColor([double r = 1.0, double g = 1.0, double b = 1.0, double a = 1.0]) {
    _currentColor.setValues(r, g, b, a);
    _encodedColor = _currentColor.toUint8();
  }

  /// Sets the current drawing color using a [Color] object.
  ///
  /// This color will be used for subsequent drawing operations.
  ///
  /// - [color]: The [Color] to set.
  void setColorFrom(Color color) {
    setColor(color.r, color.g, color.b, color.a);
  }

  /// Sets the blend mode for subsequent drawing operations.
  ///
  /// If the new [mode] is different from the current blend mode, this method
  /// will [flush] any pending draw calls before applying the new mode.
  ///
  /// - [mode]: The [BlendMode] to apply.
  void setBlendMode(BlendMode mode) {
    if (_renderState.blendMode != mode) {
      flush();
      _renderState
        ..blendMode = mode
        ..blendMode.apply(gl);
    }
  }

  /// Sets the width for lines drawn by [drawLine] and [drawLines].
  ///
  /// The [width] is clamped to the range supported by the WebGL implementation.
  ///
  /// - [width]: The desired line width in pixels.
  void setLineWidth(double width) {
    if (_renderState.lineWidth != width) {
      if (width < _lineWidthMin || width > _lineWidthMax) {
        warn("LineWidth of $width not supported, Allowed ranges goes from $_lineWidthMin to $_lineWidthMax");
      }

      _renderState.lineWidth = width.clamp(_lineWidthMin, _lineWidthMax);
      flush();
      gl.lineWidth(_renderState.lineWidth);
    }
  }

  /// Sets the viewport.
  ///
  /// The viewport defines the area of the canvas where rendering will occur.
  ///
  /// - [x]: The x-coordinate of the lower-left corner of the viewport.
  /// - [y]: The y-coordinate of the lower-left corner of the viewport.
  /// - [width]: The width of the viewport.
  /// - [height]: The height of the viewport.
  void setViewport(int x, int y, int width, int height) {
    final glY = _canvas.height - height - y;

    if (_renderState.viewport.x != x ||
        _renderState.viewport.y != glY ||
        _renderState.viewport.width != width ||
        _renderState.viewport.height != height) {
      _renderState.viewport.set(x, glY, width, height);
      gl.viewport(
        _renderState.viewport.x,
        _renderState.viewport.y,
        _renderState.viewport.width,
        _renderState.viewport.height,
      );
      if (_renderState.isScissorEnabled) {
        gl.scissor(
          _renderState.scissor.x,
          _renderState.scissor.y,
          _renderState.scissor.width,
          _renderState.scissor.height,
        );
      }
    }
  }

  /// Configures an orthographic 2D projection matrix.
  ///
  /// This is commonly used for 2D games. The projection maps world coordinates
  /// directly to screen coordinates.
  ///
  /// - [x]: The left edge of the view. Defaults to 0.0.
  /// - [y]: The top edge of the view. Defaults to 0.0.
  /// - [width]: The width of the view. Defaults to the canvas client width.
  /// - [height]: The height of the view. Defaults to the canvas client height.
  ///
  /// After calculating the matrix, it calls [setProjectionMatrix].
  void set2DProjection({double x = 0.0, double y = 0.0, double? width, double? height}) {
    final double w = width ?? _canvas.clientWidth.toDouble();
    final double h = height ?? _canvas.clientHeight.toDouble();
    setProjectionMatrix(makeOrthographicMatrix(x, x + w, y + h, y, -1, 1));
  }

  /// Sets the projection matrix used by the shaders.
  ///
  /// - [matrix]: The [Matrix4] to use as the projection matrix.
  void setProjectionMatrix(Matrix4 matrix) {
    flush();
    _renderState.projectionMatrix.setFrom(matrix);
    gl.uniformMatrix4fv(_projectionMatrixLocation, false, _renderState.projectionMatrix.storage.toJS);
  }

  /// Enables and defines a scissor rectangle for clipping rendering.
  ///
  /// When scissor testing is enabled, rendering is confined to the specified
  /// rectangular area of the canvas.
  ///
  /// - [x]: The x-coordinate of the lower-left corner of the scissor box.
  /// - [y]: The y-coordinate of the lower-left corner of the scissor box (origin at top-left of canvas).
  /// - [width]: The width of the scissor box.
  /// - [height]: The height of the scissor box.
  void setScissor(int x, int y, int width, int height) {
    flush();

    if (!_renderState.isScissorEnabled) {
      gl.enable(GL.SCISSOR_TEST);
      _renderState.isScissorEnabled = true;
    }

    final glY = _canvas.height - (y + height);
    gl.scissor(x, glY, width, height);
    _renderState.scissor.set(x, glY, width, height);
  }

  /// Disables scissor testing.
  ///
  /// Subsequent rendering will not be clipped by a scissor rectangle.
  void resetScissor() {
    flush();

    if (_renderState.isScissorEnabled) {
      gl.disable(GL.SCISSOR_TEST);
      _renderState.isScissorEnabled = false;
    }

    _renderState.scissor.set(0, 0, 0, 0);
  }

  /// Resets the current transformation matrix to the identity matrix.
  ///
  /// All subsequent drawing operations will be performed without any prior
  /// transformations until new transformations are applied.
  void resetMatrix() {
    _currentMatrix.setIdentity();
  }

  /// Pushes a copy of the current transformation matrix onto the matrix stack.
  void pushMatrix() {
    final newCurrentMatrix = _matrixPool.get();
    newCurrentMatrix.setFrom(_currentMatrix);
    _matrixStack.add(_currentMatrix);
    _currentMatrix = newCurrentMatrix;
  }

  /// Pops the top transformation matrix from the stack and makes it current.
  void popMatrix() {
    if (_matrixStack.isEmpty) {
      die('Matrix stack is empty, cannot pop. Resetting matrix to identity.');
      return;
    }
    _matrixPool.put(_currentMatrix);
    _currentMatrix = _matrixStack.removeLast();
  }

  /// Applies a 2D affine transformation to the current matrix.
  ///
  /// - [ix], [iy]: Components of the transformed x-axis.
  /// - [jx], [jy]: Components of the transformed y-axis.
  /// - [tx], [ty]: Translation components.
  void transform(double ix, double iy, double jx, double jy, double tx, double ty) {
    _tempMatrix.setValues(ix, iy, 0.0, jx, jy, 0.0, tx, ty, 1.0);
    _currentMatrix *= _tempMatrix;
  }

  /// Translates the current transformation matrix by the given offsets.
  ///
  /// - [tx]: The translation amount along the x-axis.
  /// - [ty]: The translation amount along the y-axis.
  void translate(double tx, double ty) {
    transform(1.0, 0.0, 0.0, 1.0, tx, ty);
  }

  /// Rotates the current transformation matrix by the given angle in degrees.
  ///
  /// Rotation is performed around the current origin (0,0) of the
  /// transformed coordinate system.
  ///
  /// - [degrees]: The angle of rotation in degrees.
  void rotate(double degrees) {
    final c = cosDegree(degrees);
    final s = sinDegree(degrees);
    transform(c, s, -s, c, 0.0, 0.0);
  }

  /// Scales the current transformation matrix by the given factors.
  ///
  /// Scaling is performed relative to the current origin (0,0) of the
  /// transformed coordinate system.
  ///
  /// - [sx]: The scaling factor along the x-axis.
  /// - [sy]: The scaling factor along the y-axis.
  void scale(double sx, double sy) {
    transform(sx, 0.0, 0.0, sy, 0.0, 0.0);
  }

  void _ensureBatchCapacity(int numVerticesNeeded) {
    final requiredVertices = _vertexCount + numVerticesNeeded;

    if (requiredVertices > _currentBatchCapacityVertices) {
      warn("vbo_buffer is full. consider enlarge it for better performance");
      flush();

      if (numVerticesNeeded > _currentBatchCapacityVertices) {
        die(
          "Error: Primitive requires $numVerticesNeeded vertices, which exceeds total buffer capacity $_currentBatchCapacityVertices. Increase initial buffer size.",
        );
      }
    }
  }

  void _prepareRenderState(_PrimitiveType type, {Texture? texture}) {
    final requestedTexture = texture ?? Texture.white;
    if ((_renderState.texture != requestedTexture.texture ||
        _renderState._primitiveType != type ||
        _renderState._primitiveType == _PrimitiveType.triangleFan ||
        _renderState._primitiveType == _PrimitiveType.lineStrip)) {
      flush();
    }

    if (_vertexCount == 0) {
      _renderState
        ..texture = requestedTexture.texture
        .._primitiveType = type;

      gl
        ..activeTexture(GL.TEXTURE0)
        ..bindTexture(GL.TEXTURE_2D, _renderState.texture!)
        ..uniform1i(_textureLocation, 0);
    }
  }

  void _addVertices(double x, double y, double u, double v, int color) {
    _ensureBatchCapacity(1);

    final baseFloatOffset = _vertexCount * _floatsPerVertex;
    final baseByteOffset = _vertexCount * _vertexSizeInBytes;

    _batchedInterleavedData
      ..[baseFloatOffset + 0] = x
      ..[baseFloatOffset + 1] = y
      ..[baseFloatOffset + 2] = u
      ..[baseFloatOffset + 3] = v;

    _byteDataView.setUint32(baseByteOffset + 4 * Float32List.bytesPerElement, color, Endian.little);

    _vertexCount++;
  }

  void _transfromAndAddVertices(double x, double y, double u, double v, int color) {
    _tempVector.setValues(x, y, 1.0);
    _currentMatrix.transform(_tempVector);
    _addVertices(_tempVector.x, _tempVector.y, u, v, color);
  }

  /// Draws a single point at the specified coordinates `(x, y)`.
  ///
  /// - [x]: The x-coordinate of the point.
  /// - [y]: The y-coordinate of the point.
  void drawPoint(double x, double y) {
    _prepareRenderState(_PrimitiveType.points, texture: Texture.white);

    _transfromAndAddVertices(x, y, 0, 0, _encodedColor);
  }

  /// Draws a line segment between `(x1, y1)` and `(x2, y2)`.
  ///
  /// - [x1]: The x-coordinate of the starting point.
  /// - [y1]: The y-coordinate of the starting point.
  /// - [x2]: The x-coordinate of the ending point.
  /// - [y2]: The y-coordinate of the ending point.
  /// - [colors]: An optional list of [Color] objects for per-vertex coloring.
  void drawLine(double x1, double y1, double x2, double y2, {ColorList? colors}) {
    _prepareRenderState(_PrimitiveType.lines, texture: Texture.white);

    _transfromAndAddVertices(x1, y1, 0.0, 0.0, getColorFromList(colors, 0, _encodedColor));
    _transfromAndAddVertices(x2, y2, 0.0, 0.0, getColorFromList(colors, 1, _encodedColor));
  }

  /// Draws a series of connected line segments (a line strip).
  ///
  /// The [vertices] list should contain pairs of (x, y) coordinates.
  /// For `n` points, `n-1` line segments will be drawn.
  /// Requires at least 2 points (4 values in `vertices`).
  ///
  /// - [vertices]: A list of `[x1, y1, x2, y2, ..., xn, yn]` coordinates.
  /// - [colors]: An optional list of [Color] objects. If provided, the first color
  ///   `colors[0]` is applied to all vertices.
  void drawLines(List<double> vertices, {ColorList? colors}) {
    _prepareRenderState(_PrimitiveType.lineStrip, texture: Texture.white);
    assert(vertices.length >= 4);

    for (var i = 0; i < vertices.length; i += 2) {
      var x1 = vertices[i];
      var y1 = vertices[i + 1];
      _transfromAndAddVertices(x1, y1, 0.0, 0.0, getColorFromList(colors, i ~/ 2, _encodedColor));
    }
  }

  /// Draws a filled rectangle at `(x, y)` with the given [width] and [height].
  ///
  /// If a [texture] is provided, it will be mapped to the rectangle.
  /// Otherwise, it's filled with the current color (or [colors] if specified).
  ///
  /// - [x]: The x-coordinate of the top-left corner.
  /// - [y]: The y-coordinate of the top-left corner.
  /// - [width]: The width of the rectangle.
  /// - [height]: The height of the rectangle.
  /// - [texture]: An optional [Texture] to apply. Defaults to a white texture.
  /// - [colors]: An optional list of [Color] objects for per-vertex coloring.
  ///   Colors are applied in order: top-left, bottom-left, top-right, bottom-right.
  void drawRect(double x, double y, double width, double height, {Texture? texture, ColorList? colors}) {
    texture ??= Texture.white;
    drawTexture(texture, x: x, y: y, width: width, height: height, colors: colors);
  }

  /// Draws a filled oval (ellipse) centered at `(x, y)`.
  ///
  /// - [x]: The x-coordinate of the center of the oval.
  /// - [y]: The y-coordinate of the center of the oval.
  /// - [radiusX]: The radius along the x-axis.
  /// - [radiusY]: The radius along the y-axis.
  /// - [segments]: The number of line segments to use to approximate the oval.
  ///   More segments result in a smoother oval. Defaults to 32.
  /// - [colors]: An optional list of [Color] objects. `colors[0]` is for the center,
  ///   subsequent colors apply to the perimeter vertices.
  void drawOval(double x, double y, double radiusX, double radiusY, {int segments = 32, ColorList? colors}) {
    _prepareRenderState(_PrimitiveType.triangleFan, texture: Texture.white);

    _transfromAndAddVertices(x, y, 0.5, 0.5, getColorFromList(colors, 0, _encodedColor));

    for (int i = 0; i <= segments; ++i) {
      final angle = i * (2 * pi / segments);
      final vx = x + radiusX * cos(angle);
      final vy = y + radiusY * sin(angle);

      final uvX = 0.5 + 0.5 * cos(angle);
      final uvY = 0.5 + 0.5 * sin(angle);

      _transfromAndAddVertices(vx, vy, uvX, uvY, getColorFromList(colors, 1 + i, _encodedColor));
    }
  }

  /// Draws a filled circle centered at `(x, y)` with the given [radius].
  ///
  /// - [x]: The x-coordinate of the center of the circle.
  /// - [y]: The y-coordinate of the center of the circle.
  /// - [radius]: The radius of the circle.
  /// - [segments]: The number of line segments to use. Defaults to 32.
  /// - [colors]: An optional list of [Color] objects for coloring (see [drawOval]).
  void drawCircle(double x, double y, double radius, {int segments = 32, ColorList? colors}) {
    drawOval(x, y, radius, radius, segments: segments, colors: colors);
  }

  /// Draws a filled polygon defined by a list of vertices.
  ///
  /// The polygon is rendered as a sequence of triangles.
  /// Requires at least 3 vertices.
  ///
  /// - [vertices]: A list of `[x1, y1, x2, y2, ..., xn, yn]` coordinates.
  /// - [uvs]: An optional list of `[u1, v1, u2, v2, ..., un, vn]` texture coordinates,
  ///   matching the number of vertices. If `null`, UVs default to (0,0).
  /// - [texture]: An optional [Texture] to apply. Defaults to a white texture.
  /// - [colors]: An optional list of [Color] objects. If provided, `colors[0]`
  ///   is applied to all vertices.
  void drawPoly(List<double> vertices, {List<double>? uvs, Texture? texture, ColorList? colors}) {
    int vCount = vertices.length ~/ 2;
    if (vCount < 3) {
      warn("Can't render polygon. At least 3 vertices required.");
      return;
    }

    if (uvs != null && uvs.length != vertices.length) {
      warn("Can't render Polygon. UVs and Vertices have to be of same length.");
      return;
    }

    _prepareRenderState(_PrimitiveType.triangles, texture: texture);

    for (var i = 0; i < vCount; i++) {
      var x = vertices[i * 2];
      var y = vertices[i * 2 + 1];
      var u = uvs?[i * 2] ?? 0.0;
      var v = uvs?[i * 2 + 1] ?? 0.0;
      _transfromAndAddVertices(x, y, u, v, getColorFromList(colors, 0, _encodedColor));
    }
  }

  /// Draws a filled triangle with the specified vertex coordinates and texture coordinates.
  ///
  /// - [x1],[y1], [x2],[y2], [x3],[y3]: Coordinates of the three triangle vertices.
  /// - [u1],[v1], [u2],[v2], [u3],[v3]: Texture coordinates for each corresponding vertex.
  /// - [texture]: An optional [Texture] to apply. Defaults to a white texture.
  /// - [colors]: An optional list of [Color] objects for per-vertex coloring.
  ///   `colors[0]` for first vertex, `colors[1]` for second, `colors[2]` for third.
  void drawTriangle(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
    double u1,
    double v1,
    double u2,
    double v2,
    double u3,
    double v3, {
    Texture? texture,
    ColorList? colors,
  }) {
    _prepareRenderState(_PrimitiveType.triangles, texture: texture);

    _transfromAndAddVertices(x1, y1, u1, v1, getColorFromList(colors, 0, _encodedColor));
    _transfromAndAddVertices(x2, y2, u2, v2, getColorFromList(colors, 1, _encodedColor));
    _transfromAndAddVertices(x3, y3, u3, v3, getColorFromList(colors, 2, _encodedColor));
  }

  /// Draws a [Texture] or a portion of it onto a quad.
  ///
  /// - [tex]: The [Texture] to draw.
  /// - [srcX], [srcY]: Top-left x,y coordinates of the source rectangle within the texture. Defaults to (0,0).
  /// - [srcWidth], [srcHeight]: Width and height of the source rectangle. Defaults to texture dimensions.
  /// - [x], [y]: Top-left x,y coordinates of the destination rectangle on the canvas. Defaults to (0,0).
  /// - [width], [height]: Width and height of the destination rectangle. Defaults to source dimensions.
  /// - [colors]: An optional list of [Color] objects for per-vertex coloring (tinting).
  ///   Colors are applied in order: top-left, bottom-left, top-right, bottom-right of the quad.
  void drawTexture(
    Texture tex, {
    double? srcX,
    double? srcY,
    double? srcWidth,
    double? srcHeight,
    double? x,
    double? y,
    double? width,
    double? height,
    ColorList? colors,
  }) {
    _prepareRenderState(_PrimitiveType.quads, texture: tex);

    final texW = tex.width.toDouble();
    final texH = tex.height.toDouble();

    srcX ??= 0;
    srcY ??= 0;
    srcWidth ??= texW;
    srcHeight ??= texH;
    x ??= 0;
    y ??= 0;
    width ??= texW;
    height ??= texH;

    final u1 = srcX / texW;
    final v1 = srcY / texH;
    final u2 = (srcX + srcWidth) / texW;
    final v2 = (srcY + srcHeight) / texH;

    final v0x = x, v0y = y;
    final v1x = x, v1y = y + height;
    final v2x = x + width, v2y = y;
    final v3x = x + width, v3y = y + height;

    _transfromAndAddVertices(v0x, v0y, u1, v1, getColorFromList(colors, 0, _encodedColor));
    _transfromAndAddVertices(v1x, v1y, u1, v2, getColorFromList(colors, 1, _encodedColor));
    _transfromAndAddVertices(v2x, v2y, u2, v1, getColorFromList(colors, 2, _encodedColor));
    _transfromAndAddVertices(v3x, v3y, u2, v2, getColorFromList(colors, 3, _encodedColor));
  }

  /// Measures the bounding box of a given [text] string when rendered with the specified [BitmapFont].
  ///
  /// This method accounts for character advances, tracking, and line breaks (`\n`).
  ///
  /// - [font]: The [BitmapFont] to use for measurement.
  /// - [text]: The string to measure.
  ///
  /// Returns a [Point] where `x` is the total width and `y` is the total height.
  Point measureText(BitmapFont font, String text) {
    var x = 0.0;
    var w = 0.0;
    var h = font.leading;
    for (int charCode in text.runes) {
      var glyph = font.glyphs[charCode];
      if (glyph != null) {
        x += glyph.advance * font.tracking;
        if (x > w) w = x;
      }
      if (charCode == 10) {
        h += font.leading;
        x = 0;
      }
    }
    return Point(w, h);
  }

  /// Draws [text] using the specified [BitmapFont] and rendering parameters.
  ///
  /// - [font]: The [BitmapFont] to use for rendering.
  /// - [text]: The string to draw. Supports newline characters (`\n`).
  /// - [x], [y]: The base coordinates for drawing the text. Defaults to (0,0).
  ///   How these are interpreted depends on [alignX] and [alignY].
  /// - [alignX]: Horizontal alignment. 0.0 for left, 0.5 for center, 1.0 for right. Defaults to 0.0.
  /// - [alignY]: Vertical alignment. 0.0 for top, 0.5 for middle, 1.0 for bottom. Defaults to 0.0.
  /// - [scaleX], [scaleY]: Scaling factors for the rendered text. Defaults to 1.0.
  /// - [alignXByLine]: If `true` (default), horizontal alignment is applied per line.
  ///   If `false`, it's applied to the entire text block based on the widest line.
  /// - [colors]: An optional [ColorList]. If provided, `colors[0]` tints the entire text.
  ///
  /// Returns a [Point] representing the width and height of the drawn text block,
  /// after scaling.
  Point drawText(
    BitmapFont font,
    String text, {
    x = 0.0,
    y = 0.0,
    alignX = 0.0,
    alignY = 0.0,
    scaleX = 1.0,
    scaleY = 1.0,
    alignXByLine = true,
    ColorList? colors,
  }) {
    var lines = text.split("\n");
    var h = font.leading * lines.length * scaleY;
    var w = measureText(font, text).x * scaleX;
    var startX = x;
    var startY = y;

    pushMatrix();
    translate(x - w * alignX, y - h * alignY);
    x = 0.0;
    y = 0.0;

    for (var line in lines) {
      if (alignXByLine) {
        popMatrix();
        w = measureText(font, line).x * scaleX;

        pushMatrix();
        translate(startX - w * alignX, startY - h * alignY);
      }
      for (int charCode in line.runes) {
        var glyph = font.glyphs[charCode];
        if (glyph != null) {
          if (glyph.image != null) {
            drawImage([glyph.image!], 0, x, y, 0, scaleX, scaleY, colors);
          }
          x += glyph.advance * font.tracking * scaleX;
        }
      }
      y += font.leading * scaleY;
      x = 0;
    }
    popMatrix();
    return Point(w, h);
  }

  /// Draws a specific [frame] from an [Images] sequence (sprite sheet or animation).
  ///
  /// - [frames]: The [Images] object containing the frame(s) to draw.
  /// - [frame]: The index of the frame to draw. Defaults to 0.
  /// - [x], [y]: The position to draw the image at (considers image's pivot). Defaults to (0,0).
  /// - [rotation]: Rotation angle in degrees. Defaults to 0.0.
  /// - [scaleX], [scaleY]: Scaling factors. Defaults to 1.0.
  /// - [colors]: An optional [ColorList] for tinting the image. `colors[0]` is used.
  ///
  /// If the [frames] are still loading this method does nothing.
  void drawImage(
    Images frames, [
    int frame = 0,
    double x = 0.0,
    double y = 0.0,
    double rotation = 0.0,
    double scaleX = 1.0,
    double scaleY = 1.0,
    ColorList? colors,
  ]) {
    if (frame < 0 || frame >= frames.length) {
      die("Image has ${frames.length} frames, you requested frame: $frame");
    }

    var image = frames[frame];

    pushMatrix();
    translate(x, y);
    scale(scaleX, scaleY);
    rotate(rotation);
    translate(-image.pivotX * image.width, -image.pivotY * image.height);
    drawTexture(
      image.texture,
      srcX: image.sourceRect.x.toDouble(),
      srcY: image.sourceRect.y.toDouble(),
      srcWidth: image.width.toDouble(),
      srcHeight: image.height.toDouble(),
      x: 0,
      y: 0,
      width: image.width.toDouble(),
      height: image.height.toDouble(),
      colors: colors,
    );
    popMatrix();
  }

  /// Draws a rectangular section from a specific [frame] of an [Images] sequence.
  /// The image will be streteched to the destination rectangle.
  ///
  /// - [frames]: The [Images] object containing the frame(s) to draw from.
  /// - [frame]: The index of the frame to draw from.
  /// - [srcX], [srcY]: Top-left coordinates of the source rectangle within the image frame.
  /// - [srcWidth], [srcHeight]: Width and height of the source rectangle to extract.
  /// - [x], [y]: Top-left coordinates of the destination rectangle on the canvas.
  /// - [width], [height]: Width and height of the destination rectangle.
  /// - [colors]: An optional [ColorList] for tinting the image. `colors[0]` is used if provided.
  ///
  /// If the [frame] index is out of bounds, this method will terminate the application
  /// with an error message.
  ///
  /// Note: Unlike [drawImage], this method does not apply pivot point transformations
  /// or additional matrix transformations - it draws the specified rectangle directly.
  void drawImageRect(
    Images frames,
    int frame,
    double srcX,
    double srcY,
    double srcWidth,
    double srcHeight,
    double x,
    double y,
    double width,
    double height, [
    ColorList? colors,
  ]) {
    if (frame < 0 || frame >= frames.length) {
      die("Image has ${frames.length} frames, you requested frame: $frame");
    }

    var image = frames[frame];

    drawTexture(
      image.texture,
      srcX: srcX,
      srcY: srcY,
      srcWidth: srcWidth,
      srcHeight: srcHeight,
      x: x,
      y: y,
      width: width,
      height: height,
      colors: colors,
    );
  }

  /// Flushes all batched drawing commands to the GPU.
  ///
  /// This method sends all data to WebGL for rendering.
  /// It is called automatically when necessary (e.g., when changing blend modes,
  /// textures, or when the batch buffer is full), but can also be called
  /// manually to ensure all pending draw operations are executed.
  ///
  /// The application loop in [App] typically calls this once per frame
  /// after `onRender`.
  void flush() {
    if (_vertexCount == 0) {
      return;
    }

    if (_renderState._primitiveType == null) {
      die("State error: Batch started without a _PrimitiveType set!");
    }

    final int dataSizeInBytes = _vertexCount * _vertexSizeInBytes;

    gl
      ..useProgram(_program)
      ..bindVertexArray(_vao)
      ..bindBuffer(GL.ARRAY_BUFFER, _interleavedBuffer)
      ..bufferData(GL.ARRAY_BUFFER, _batchCapacityInBytes.toJS, GL.STREAM_DRAW)
      ..bufferSubData(GL.ARRAY_BUFFER, 0, _batchedInterleavedData.buffer.asUint8List(0, dataSizeInBytes).toJS);

    switch (_renderState._primitiveType) {
      case _PrimitiveType.quads:
        final numQuadsInBatch = _vertexCount ~/ 4;
        if (_vertexCount % 4 != 0) {
          die("Warning: Drawing QUAD batch with vertex count $_vertexCount not divisible by 4.");
          return;
        }
        final numIndicesToDraw = numQuadsInBatch * 6;

        gl
          ..bindBuffer(GL.ELEMENT_ARRAY_BUFFER, _quadIndexBuffer)
          ..drawElements(GL.TRIANGLES, numIndicesToDraw, GL.UNSIGNED_SHORT, 0)
          ..bindBuffer(GL.ELEMENT_ARRAY_BUFFER, null);
        break;

      case _PrimitiveType.points:
      case _PrimitiveType.lines:
      case _PrimitiveType.lineStrip:
      case _PrimitiveType.triangles:
      case _PrimitiveType.triangleFan:
        gl.drawArrays(_renderState._primitiveType!.toGLPrimitive(), 0, _vertexCount);
        break;

      default:
        die("Unknown batch primitive type: $_renderState.primitiveType");
    }

    _vertexCount = 0;
  }
}
