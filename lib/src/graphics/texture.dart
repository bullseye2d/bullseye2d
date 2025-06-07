import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart';
import 'dart:js_interop';
import 'dart:typed_data';

/// {@category Graphics}
/// Defines bitmask flags to control [Texture] behavior, such as filtering,
class TextureFlags {
  /// No flags set.
  static const int none = 0;

  /// Enables bilinear filtering for magnification and minification.
  static const int filter = 0x1;

  /// Enables mipmapping. Often used with [filter] for better quality at smaller sizes.
  static const int mipmap = 0x2;

  /// Clamps texture coordinates to the edge in the S (U) direction.
  static const int clampS = 0x4;

  /// Clamps texture coordinates to the edge in the T (V) direction.
  static const int clampT = 0x8;

  /// Clamps texture coordinates to the edge in both S (U) and T (V) directions.
  static const int clampST = clampS | clampT;

  /// Repeats the texture in the S (U) direction.
  static const int repeatS = 0x10;

  /// Repeats the texture in the T (V) direction.
  static const int repeatT = 0x20;

  /// Repeats the texture in both S (U) and T (V) directions.
  static const int repeatST = repeatS | repeatT;

  /// Repeats the texture with mirroring in the S (U) direction.
  static const int mirroredRepeatS = 0x40;

  /// Repeats the texture with mirroring in the T (V) direction.
  static const int mirroredRepeatT = 0x80;

  /// Repeats the texture with mirroring in both S (U) and T (V) directions.
  static const int mirroredRepeatST = mirroredRepeatS | mirroredRepeatT;

  /// Default texture flags: enables [filter] and [mipmap].
  static const int defaultFlags = filter | mipmap;
}

/// {@category Graphics}
/// Represents a Texture.
/// Textures are reference-counted; use [retain] and [dispose] to manage their lifecycle.
class Texture {
  /// A statically available 1x1 white [Texture]. Useful as a default or placeholder.
  /// Initialized by the graphics system.
  static late Texture white;

  WebGLTexture? texture;

  final GL2 _gl;

  final List<void Function(Texture texture)> _onDispose = [];
  final List<void Function(Texture texture)> _onLoad = [];

  static final _emptyTextureData = Uint8List.fromList([0, 0, 0, 0]);
  static final _whiteTextureData = Uint8List.fromList([255, 255, 255, 255]);

  int _refCount = 1;

  /// The width of the texture in pixels.
  int width;

  /// The height of the texture in pixels.
  int height;

  /// The bitmask [TextureFlags] applied to this texture.
  late int flags;

  /// `true` if the texture is currently loading its data, `false` otherwise.
  bool isLoading = true;

  /// The raw pixel data of the texture as a `Uint8List`.
  /// This data is available after the texture has loaded.
  late Uint8List pixelData;

  /// Creates a [Texture] instance, usually internally by static factory methods.
  ///
  /// - [gl]: The WebGL2 rendering context.
  /// - [texture]: The WebGL texture object.
  /// - [width]: Initial width (defaults to 0).
  /// - [height]: Initial height (defaults to 0).
  /// - [flags]: Texture flags (defaults to [TextureFlags.defaultFlags]).
  /// - [pixelData]: Optional initial pixel data.
  Texture({
    required GL2 gl,
    required this.texture,
    this.width = 0,
    this.height = 0,
    this.flags = TextureFlags.defaultFlags,
    Uint8List? pixelData,
  }) : _gl = gl {
    this.pixelData = pixelData ?? Uint8List(0);
  }

  /// Creates and returns a 1x1 opaque white [Texture].
  static Texture createWhite(GL2 gl) {
    final texture = create(gl: gl, pixelData: _whiteTextureData, textureFlags: TextureFlags.clampST);
    texture.isLoading = false;
    return texture;
  }

  /// Creates a [Texture] from raw pixel data or as an empty texture.
  ///
  /// - [gl]: The WebGL2 rendering context.
  /// - [pixelData]: Optional `Uint8List` of pixel data (RGBA). If `null`, a 1x1 transparent black texture is created.
  /// - [width]: Width of the texture. Defaults to 1 if [pixelData] is `null`.
  /// - [height]: Height of the texture. Defaults to 1 if [pixelData] is `null`.
  /// - [textureFlags]: Bitmask of [TextureFlags] to apply.
  static Texture create({
    required GL2 gl,
    Uint8List? pixelData,
    int width = 1,
    int height = 1,
    int textureFlags = TextureFlags.defaultFlags,
  }) {
    var flags = textureFlags;
    final tex = gl.createTexture();
    if (tex == null) {
      throw Exception("Could not create texture!");
    }

    gl.bindTexture(GL.TEXTURE_2D, tex);
    if (pixelData == null) {
      pixelData = _emptyTextureData;
      width = 1;
      height = 1;
    }
    gl.texImage2D(
      GL.TEXTURE_2D,
      0,
      GL.RGBA,
      width.toJS,
      height.toJS,
      0.toJS,
      GL.RGBA,
      GL.UNSIGNED_BYTE,
      pixelData.toJS,
    );

    if (flags.has(TextureFlags.filter)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
    } else {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.NEAREST);
    }

    if (flags.hasAll(TextureFlags.mipmap | TextureFlags.filter)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_LINEAR);
    } else if (flags.has(TextureFlags.mipmap)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST_MIPMAP_NEAREST);
    } else if (flags.has(TextureFlags.filter)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
    } else {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.NEAREST);
    }

    if (flags.has(TextureFlags.clampS)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
    } else if (flags.has(TextureFlags.repeatS)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.REPEAT);
    } else if (flags.has(TextureFlags.mirroredRepeatS)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.MIRRORED_REPEAT);
    } else {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
    }

    if (flags.has(TextureFlags.clampT)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
    } else if (flags.has(TextureFlags.repeatT)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.REPEAT);
    } else if (flags.has(TextureFlags.mirroredRepeatT)) {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.MIRRORED_REPEAT);
    } else {
      gl.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);
    }

    final texture = Texture(
      gl: gl,
      texture: tex,
      width: width,
      height: height,
      flags: textureFlags,
      pixelData: pixelData,
    );

    texture.isLoading = false;

    if (flags.has(TextureFlags.mipmap)) {
      gl.generateMipmap(GL.TEXTURE_2D);
    }

    return texture;
  }

  /// Asynchronously loads a [Texture] from the specified [path].
  ///
  /// - [gl]: The WebGL2 rendering context.
  /// - [loadingInfo]: A [Loader] instance to track loading progress.
  /// - [path]: The URL or path to the image file.
  /// - [textureFlags]: Optional [TextureFlags] to apply.
  ///
  /// Returns a [Texture] instance.
  /// Use [onLoad] to register a callback for when loading completes.
  static Texture load(GL2 gl, Loader loadingInfo, path, [int textureFlags = TextureFlags.defaultFlags]) {
    final texture = create(gl: gl, textureFlags: textureFlags);
    texture.isLoading = true;

    loadImageData(path, loadingInfo)
        .then((img) {
          if (img != null && texture.texture != null) {
            texture.width = img.width;
            texture.height = img.height;
            gl.bindTexture(GL.TEXTURE_2D, texture.texture);
            final canvas =
                HTMLCanvasElement()
                  ..width = texture.width
                  ..height = texture.height;
            final ctx = canvas.getContext('2d') as CanvasRenderingContext2D;
            ctx.drawImage(img, 0, 0);
            final pixelData = ctx.getImageData(0, 0, texture.width, texture.height).data.toDart;
            gl.texImage2D(
              GL.TEXTURE_2D,
              0,
              GL.RGBA,
              texture.width.toJS,
              texture.height.toJS,
              0.toJS,
              GL.RGBA,
              GL.UNSIGNED_BYTE,
              pixelData.buffer.asUint8List().toJS,
            );
            texture.pixelData = pixelData.buffer.asUint8List();
            texture.isLoading = false;

            if (texture.flags.has(TextureFlags.mipmap)) {
              gl.generateMipmap(GL.TEXTURE_2D);
            }

            texture.triggerOnLoadCallback();
          }
        })
        .catchError((e) {
          error("catchError", e);
          texture.isLoading = false;
        });

    return texture;
  }

  /// Increments the reference count of this texture.
  /// Call this if you are keeping an additional reference to the texture elsewhere
  /// to prevent premature disposal.
  void retain() {
    _refCount++;
  }

  /// Decrements the reference count of this texture.
  /// If the reference count reaches zero, the texture is deleted,
  /// and any [onDispose] callbacks are triggered.
  /// Logs an error if the reference count is already zero or less.
  void dispose() {
    if (_refCount < 1) {
      die("Refcount of Texture cannot be less than zero.");
    }

    _refCount--;

    if (_refCount == 0) {
      _gl.deleteTexture(texture);
      // TODO: It is possible that we still have draw commands issued with this texture.
      // we should either flush the draw commands
      // or draw commands should retain the texture (maybe complex)
      // or we should delay it on frame boundaries???
      texture = null;
      for (var func in _onDispose) {
        func(this);
      }
      _onDispose.clear();
    }
  }

  /// Registers a callback function to be executed when the texture has finished loading.
  /// If the texture is already loaded ([isLoading] is `false`), the callback is executed immediately.
  ///
  /// - [func]: The function to call, receiving the loaded [Texture] as an argument.
  void onLoad(Function(Texture texture) func) {
    if (isLoading) {
      _onLoad.add(func);
    } else {
      func(this);
    }
  }

  /// Registers a callback function to be executed when the texture is disposed
  /// (i.e., its reference count reaches zero and the WebGL texture is deleted).
  ///
  /// - [func]: The function to call, receiving the disposed [Texture] as an argument.
  void onDispose(Function(Texture texture) func) {
    _onDispose.add(func);
  }

  /// @nodoc
  void triggerOnLoadCallback() {
    for (var func in _onLoad) {
      func(this);
    }
    _onLoad.clear();
  }

  /// Updates the texture's pixel data on the GPU with the provided [data].
  ///
  /// - [data]: The new `Uint8List` of pixel data (RGBA format).
  ///
  /// This method should only be called when [isLoading] is `false`.
  /// If [TextureFlags.mipmap] is set, mipmaps are regenerated.
  void updateTextureData(Uint8List data) {
    if (isLoading) {
      error('Cannot update texture data while the texture is still loading.');
      return;
    }

    final expectedLength = width * height * 4;
    if (data.length != expectedLength) {
      die(
        'Provided data length (${data.length}) does not match expected length ($expectedLength) for texture dimensions ${width}x$height.',
      );
    }

    _gl.bindTexture(GL.TEXTURE_2D, texture);

    _gl.texSubImage2D(GL.TEXTURE_2D, 0, 0, 0, width.toJS, height.toJS, GL.RGBA.toJS, GL.UNSIGNED_BYTE, data.toJS);

    if (flags.has(TextureFlags.mipmap)) {
      _gl.generateMipmap(GL.TEXTURE_2D);
    }

    pixelData = Uint8List.fromList(data);
  }
}
