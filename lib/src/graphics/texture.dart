import 'package:bullseye2d/bullseye2d.dart';
import 'package:bullseye2d/src/backend/backend.dart' show TextureHandle, RendererBackend, ImageLoaderBackend;
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

  /// @nodoc
  TextureHandle? handle;

  final RendererBackend _renderer;

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

  /// @nodoc
  Texture({
    required RendererBackend renderer,
    required this.handle,
    this.width = 0,
    this.height = 0,
    this.flags = TextureFlags.defaultFlags,
    Uint8List? pixelData,
  }) : _renderer = renderer {
    this.pixelData = pixelData ?? Uint8List(0);
  }

  /// @nodoc
  static Texture createWhite(RendererBackend renderer) {
    final texture = create(renderer: renderer, pixelData: _whiteTextureData, textureFlags: TextureFlags.clampST);
    texture.isLoading = false;
    return texture;
  }

  /// @nodoc
  static Texture create({
    required RendererBackend renderer,
    Uint8List? pixelData,
    int width = 1,
    int height = 1,
    int textureFlags = TextureFlags.defaultFlags,
  }) {
    if (pixelData == null) {
      pixelData = _emptyTextureData;
      width = 1;
      height = 1;
    }

    final handle = renderer.createTexture(width, height, pixelData, textureFlags);

    final texture = Texture(
      renderer: renderer,
      handle: handle,
      width: width,
      height: height,
      flags: textureFlags,
      pixelData: pixelData,
    );

    texture.isLoading = false;

    return texture;
  }

  /// @nodoc
  static Texture load(
    RendererBackend renderer,
    ImageLoaderBackend imageLoader,
    Loader loadingInfo,
    String path, [
    int textureFlags = TextureFlags.defaultFlags,
  ]) {
    final texture = create(renderer: renderer, textureFlags: textureFlags);
    texture.isLoading = true;

    final loadingState = loadingInfo.add(path);

    imageLoader
        .decodeFromFile(path)
        .then((decoded) {
          if (decoded.width > 0 && decoded.height > 0 && texture.handle != null) {
            texture.width = decoded.width;
            texture.height = decoded.height;

            // Destroy the placeholder 1x1 texture and create the real one
            renderer.destroyTexture(texture.handle!);
            final realHandle = renderer.createTexture(decoded.width, decoded.height, decoded.pixels, textureFlags);
            texture.handle = realHandle;

            texture.pixelData = decoded.pixels;
            texture.isLoading = false;

            texture.triggerOnLoadCallback();
          }
          loadingState.completedOrFailed = true;
        })
        .catchError((e) {
          error("Error loading texture: $path", e);
          texture.isLoading = false;
          loadingState.completedOrFailed = true;
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
      if (handle != null) {
        _renderer.destroyTexture(handle!);
      }
      handle = null;
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
  /// (i.e., its reference count reaches zero and the texture is deleted).
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

    if (handle != null) {
      _renderer.updateTexture(handle!, 0, 0, width, height, data);
    }

    pixelData = Uint8List.fromList(data);
  }
}
