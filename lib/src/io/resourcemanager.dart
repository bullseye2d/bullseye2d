import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart' show FontFace, document;
import 'dart:collection';
import 'dart:typed_data';
import 'dart:js_interop';

/// {@category IO}
/// Manages the loading of game resources such as textures, images,
/// fonts, and sounds.
///
/// It automatically tracks loading progress.
class ResourceManager {
  final GL2 _gl;
  final Loader _loadingInfo;
  final Audio _audio;
  final _textureCache = HashMap<String, Texture>();
  final _fontCache = HashMap<int, BitmapFont>();

  /// Creates a new [ResourceManager].
  ///
  /// - [_gl]: The WebGL2 rendering context.
  /// - [_audio]: The audio system for sound playback.
  /// - [_loadingInfo]: The loader instance to track resource loading progress.
  ///
  /// Typically, you don't instantiate this class yourself. Instead, you use
  /// the `app.resources` member provided by the [App] class.
  ResourceManager(this._gl, this._audio, this._loadingInfo);

  /// Loads a [Texture] from the given [path].
  ///
  /// If the texture at [path] has already been loaded, a cached version is
  /// returned and its reference count is incremented. Otherwise, a new
  /// texture is loaded, cached, and returned.
  ///
  /// - [path]: The path to the texture file.
  /// - [textureFlags]: Optional flags to control texture parameters like
  ///   filtering and wrapping. Defaults to [TextureFlags.defaultFlags].
  ///
  /// Returns the loaded or cached [Texture].
  Texture loadTexture(String path, [int textureFlags = TextureFlags.defaultFlags]) {
    var texture = _textureCache[path];
    var newTex = texture == null;
    if (newTex) {
      texture = Texture.load(_gl, _loadingInfo, path, textureFlags);
      texture.onDispose((Texture texture) {
        _textureCache.remove(path);
      });
      _textureCache[path] = texture;
    } else {
      texture.retain();
    }

    return texture;
  }

  /// Loads an image or a sequence of image frames ([Images]) from the given [path].
  ///
  /// If [frameWidth] and [frameHeight] are specified (and greater than 0),
  /// the image is treated as a spritesheet, and multiple [Image] frames are
  /// extracted. Otherwise, a single [Image] representing the entire texture
  /// is created.
  ///
  /// - [path]: The path to the image file.
  /// - [frameWidth]: The width of each frame in the spritesheet. If 0, the
  ///   entire texture width is used.
  /// - [frameHeight]: The height of each frame in the spritesheet. If 0, the
  ///   entire texture height is used.
  /// - [paddingX]: Horizontal padding between frames in the spritesheet.
  /// - [paddingY]: Vertical padding between frames in the spritesheet.
  /// - [textureFlags]: Optional flags for the [Texture].
  /// - [pivotX]: The horizontal pivot point (0.0 to 1.0) for the image(s).
  /// - [pivotY]: The vertical pivot point (0.0 to 1.0) for the image(s).
  /// - [onLoad]: An optional callback function that is executed when the
  ///   image (and its frames) has finished loading and processing.
  ///
  /// Returns an [Images] list.
  Images loadImage(
    String path, {
    int frameWidth = 0,
    int frameHeight = 0,
    int paddingX = 0,
    int paddingY = 0,
    int textureFlags = TextureFlags.defaultFlags,
    double pivotX = 0.5,
    double pivotY = 0.5,
    void Function()? onLoad,
  }) {
    Images result = [];

    var texture = loadTexture(path, textureFlags);

    if (frameWidth == 0 && frameHeight == 0) {
      var image = Image(
        texture: texture,
        sourceRect: Rect(0, 0, texture.width, texture.height),
        pivotX: pivotX,
        pivotY: pivotY,
      );
      texture.dispose();

      texture.onLoad((Texture texture) {
        image.sourceRect.set(0, 0, texture.width, texture.height);
        onLoad?.call();
      });

      result.add(image);
    } else {
      texture.onLoad((Texture texture) {
        result.addAll(
          Image.loadFrames(
            texture: texture,
            frameWidth: frameWidth,
            frameHeight: frameHeight,
            paddingX: paddingX,
            paddingY: paddingY,
            pivotX: pivotX,
            pivotY: pivotY,
          ),
        );
        onLoad?.call();
      });
    }
    return result;
  }

  /// Loads a TrueType Font and creates [BitmapFont] out of it.
  ///
  /// - [path]: The path to the font file (e.g., `.ttf`, `.woff2`).
  /// - [size]: The desired font size in pixels.
  /// - [antiAlias]: Whether to use anti-aliasing when rendering the font atlas.
  ///   Defaults to `true`.
  /// - [containedAsciiCharacters]: A string of characters to include in the
  ///   font atlas. Defaults to [BitmapFont.extendedAscii].
  ///
  /// Returns the loaded or cached [BitmapFont].
  BitmapFont loadFont(
    String path,
    double size, {
    bool antiAlias = true,
    String containedAsciiCharacters = BitmapFont.extendedAscii,
  }) {
    var font = BitmapFont(_gl);

    var fontName = path.replaceAll("/", "").replaceAll(".", "");
    var hash = "${path}_${size}_${antiAlias}_$containedAsciiCharacters".hashCode;

    if (_fontCache.containsKey(hash)) {
      return _fontCache[hash]!;
    } else {
      _fontCache[hash] = font;
      load<ByteBuffer?>(
        path,
        _loadingInfo,
        responseType: "arraybuffer",
        onLoad: (response, complete, error) {
          var fontBytes = (response as JSArrayBuffer).toDart;
          final FontFace fontFace = FontFace(fontName, fontBytes.toJS);
          try {
            document.fonts.add(fontFace);
          } catch (e) {
            // NOTE(jochen): I don't know why but on Firefox this throws an Invalid Type
            // exception. But if we ignore it, everythings seems to work.
            // My assumptions it that firefox returns null instead of a
            // FontFaceSet Object that is defined in the standard and Dart
            // expects that return object.
          }
          font.generateAtlas(fontName, size, antiAlias, containedAsciiCharacters);
          complete(fontBytes);
        },
      );
    }

    return font;
  }

  /// Loads a [Sound] from the audio file at the given [path].
  ///
  /// - [path]: The path to the audio file.
  /// - [retriggerDelayInMs]: The minimum delay in milliseconds before this
  ///   sound can be played again. Defaults to 0 (no delay).
  ///
  /// Returns the [Sound] object, which will asynchronously load the audio data.
  Sound loadSound(String path, {int retriggerDelayInMs = 0}) {
    var sound =
        Sound()
          ..retriggerDelay = Duration(milliseconds: retriggerDelayInMs)
          ..loadFromFile(path, _loadingInfo, _audio.audioContext);

    return sound;
  }

  /// Loads the content of a text file from the given [path] as a [String].
  ///
  /// This method is asynchronous and returns a [Future].
  ///
  /// - [path]: The path to the text file.
  ///
  /// Returns a [Future<String>] that completes with the file content.
  Future<String> loadString(String path) async {
    return loadStringAsync(path, _loadingInfo);
  }
}
