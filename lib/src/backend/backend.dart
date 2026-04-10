import 'dart:typed_data';

import 'package:bullseye2d/src/app/app_config.dart';
import 'package:bullseye2d/src/graphics/blendmode.dart';

export 'stub.dart'
  if (dart.library.io) 'sdl3/platform_factory.dart'
  if (dart.library.js_interop) 'web/platform_factory.dart';

// ---------------------------------------------------------------------------
// Primitive types for draw calls
// ---------------------------------------------------------------------------

enum PrimitiveType { points, lines, lineStrip, triangles, triangleFan }

// ---------------------------------------------------------------------------
// Window / platform management
// ---------------------------------------------------------------------------

abstract class WindowBackend {
  int get width;
  int get height;

  /// The display/screen size of the window surface.
  /// Web: canvas.clientWidth/clientHeight (CSS layout size).
  /// SDL3: same as width/height.
  int get displayWidth => width;
  int get displayHeight => height;

  /// Set the rendering surface size.
  /// Web: sets canvas.width/canvas.height (pixel resolution).
  /// SDL3: resizes the window via SDL.
  void setSize(int w, int h) {}

  /// Returns the platform identifier string (e.g. "web", "windows", "macos", "linux").
  String getPlatform();

  void setTitle(String title);
  void focus();
  void setCursorVisible(bool visible);
  void onFocus(void Function() callback);
  void onBlur(void Function() callback);
  void onResize(void Function(int w, int h) callback);

  /// High-resolution timestamp in milliseconds (replaces performance.now()).
  double now();

  /// Schedules a callback for the next frame.
  /// Web: requestAnimationFrame. SDL3: called from the SDL event loop.
  void requestAnimationFrame(void Function() callback);

  /// Process pending platform events.
  /// Web: no-op (DOM events fire on the event loop).
  /// SDL3: polls SDL events and dispatches to input backends.
  /// Returns false if the application should quit.
  bool pumpEvents() => true;

  void dispose();
}

// ---------------------------------------------------------------------------
// 2D Renderer
// ---------------------------------------------------------------------------

/// 2D rendering backend.
///
/// Web: WebGL2 (shaders, VAO/VBO, drawElements).
/// SDL3: SDL_Renderer (SDL_RenderGeometry — no direct OpenGL).
///
/// bullseye2d transforms vertices on the CPU (matrix stack). The backend
/// receives pre-transformed, colored, textured vertex batches.
abstract class RendererBackend {
  void init();
  void present();
  void dispose();

  // State
  void setViewport(int x, int y, int w, int h);
  void setScissor(int x, int y, int w, int h);
  void resetScissor();
  void clear(double r, double g, double b, double a);
  void setBlendMode(BlendMode mode);
  void setLineWidth(double w);

  // Textures
  TextureHandle createTexture(int width, int height, Uint8List pixels, int flags);
  void updateTexture(TextureHandle texture, int x, int y, int w, int h, Uint8List pixels, int flags);
  void destroyTexture(TextureHandle texture);

  /// Draw a batch of pre-transformed geometry.
  ///
  /// [vertices] contains interleaved vertex data. The layout per vertex is:
  ///   float x, float y, float u, float v, uint8 r, g, b, a  (20 bytes)
  ///
  /// [indices] contains Uint16 index data for indexed drawing.
  void drawGeometry({
    required TextureHandle? texture,
    required Float32List vertices,
    required int vertexCount,
    required Uint16List indices,
    required int indexCount,
    required PrimitiveType primitiveType,
  });

  /// Set the 2D projection matrix (4x4, column-major).
  /// Web/WebGL: uploaded as a uniform. SDL3/SDL_Renderer: typically a no-op.
  void setProjection(Float32List matrix4);
}

/// Opaque handle to a GPU texture.
/// Web: wraps WebGLTexture. SDL3: wraps `Pointer<SDL_Texture>`.
abstract class TextureHandle {
  int get width;
  int get height;
}

// ---------------------------------------------------------------------------
// Audio
// ---------------------------------------------------------------------------

abstract class AudioBackend {
  void init();

  // Sound effects
  int playSound(
    AudioBufferHandle buffer, {
    int channel = -1,
    bool loop = false,
    double volume = 1.0,
    double pan = 0.0,
    double rate = 1.0,
    double loopStart = -1,
    double loopEnd = -1,
  });
  void stopChannel(int channel);
  void pauseChannel(int channel);
  void resumeChannel(int channel);
  void setChannelVolume(int channel, double volume);
  void setChannelPan(int channel, double pan);
  void setChannelRate(int channel, double rate);
  int obtainFreeChannel(List<int>? targets);

  // Music (streamed)
  void playMusic(String path, bool loop, [double loopStart = -1, double loopEnd = -1]);
  void stopMusic();
  void pauseMusic();
  void resumeMusic();
  double get musicPosition;
  double get musicDuration;
  double get musicVolume;
  set musicVolume(double v);

  // Lifecycle
  void suspend();
  void resume();
  void dispose();

  // Decoding
  Future<AudioBufferHandle> decodeAudio(Uint8List bytes);
  Future<AudioBufferHandle> decodeAudioFromFile(String path);

  // Visualizer
  AudioVisualizerBackend createVisualizer(int fftSize);
}

/// Opaque handle to a decoded audio buffer.
/// Web: wraps AudioBuffer. SDL3: wraps Mix_Chunk pointer.
abstract class AudioBufferHandle {
  double get duration;
  void dispose();
}

// ---------------------------------------------------------------------------
// Audio Visualizer
// ---------------------------------------------------------------------------

/// Backend for audio visualization (waveform capture).
///
/// Web: wraps AnalyserNode. SDL3: captures PCM via post-mix callback.
abstract class AudioVisualizerBackend {
  /// Whether this backend provides real visualization data.
  bool get isSupported;

  /// Update and return the current waveform data (0-255, centered at 128).
  Uint8List updateWaveformData();

  /// The number of frequency bins available.
  int get frequencyBinCount;

  /// Set the FFT size. Must be a power of 2 between 32 and 32768.
  set fftSize(int size);

  /// Disconnect and release resources.
  void disconnect();
}

// ---------------------------------------------------------------------------
// Input — Accelerometer
// ---------------------------------------------------------------------------

/// Accelerometer backend.
///
/// Web: DeviceMotion API. SDL3: no-op (desktop has no accelerometer).
abstract class AccelerometerBackend {
  double get x;
  double get y;
  double get z;

  void attach();
  void detach();
  Future<bool> requestPermission();
}

// ---------------------------------------------------------------------------
// Input — Keyboard
// ---------------------------------------------------------------------------

abstract class KeyboardBackend {
  void attach();
  void detach();
  void onEndFrame();
  void suspend();

  /// Called by the backend when a key is pressed.
  void Function(String code, String char)? onKeyDown;

  /// Called by the backend when a key is released.
  void Function(String code)? onKeyUp;
}

// ---------------------------------------------------------------------------
// Input — Mouse / Touch
// ---------------------------------------------------------------------------

abstract class MouseBackend {
  void attach();
  void detach();
  void onEndFrame();
  void suspend();

  void Function(double x, double y)? onMove;
  void Function(int button)? onButtonDown;
  void Function(int button)? onButtonUp;
  void Function(int delta)? onWheel;

  // Touch
  void Function(int id, double x, double y, double force)? onTouchStart;
  void Function(int id, double x, double y, double force)? onTouchMove;
  void Function(int id)? onTouchEnd;
  void Function()? onFirstClick;
}

// ---------------------------------------------------------------------------
// Input — Gamepad
// ---------------------------------------------------------------------------

abstract class GamepadBackend {
  void poll();
  int get connectedCount;
  double axisValue(int port, int axis);
  bool buttonPressed(int port, int button);

  void Function(int port)? onConnected;
  void Function(int port)? onDisconnected;
}

// ---------------------------------------------------------------------------
// File / asset loading
// ---------------------------------------------------------------------------

abstract class FileBackend {
  Future<Uint8List> loadBytes(String path);
  Future<String> loadString(String path);
  void onProgress(String path, void Function(int loaded, int total) callback);
}

// ---------------------------------------------------------------------------
// Image decoding
// ---------------------------------------------------------------------------

abstract class ImageLoaderBackend {
  Future<DecodedImage> decode(Uint8List bytes);
  Future<DecodedImage> decodeFromFile(String path);
}

class DecodedImage {
  final Uint8List pixels;
  final int width;
  final int height;

  DecodedImage({required this.pixels, required this.width, required this.height});
}

// ---------------------------------------------------------------------------
// Font rasterization
// ---------------------------------------------------------------------------

abstract class FontRasterizerBackend {
  Future<RasterizedFont> rasterize(Uint8List ttfBytes, double size, String characters, bool antiAlias);
}

class RasterizedFont {
  final Uint8List atlasPixels;
  final int atlasWidth;
  final int atlasHeight;
  final Map<int, GlyphMetrics> glyphs;
  final double lineHeight;
  final double ascent;

  RasterizedFont({
    required this.atlasPixels,
    required this.atlasWidth,
    required this.atlasHeight,
    required this.glyphs,
    required this.lineHeight,
    required this.ascent,
  });
}

class GlyphMetrics {
  final double u1, v1, u2, v2;
  final double width, height;
  final double xOffset, yOffset;
  final double advance;

  GlyphMetrics({
    required this.u1,
    required this.v1,
    required this.u2,
    required this.v2,
    required this.width,
    required this.height,
    required this.xOffset,
    required this.yOffset,
    required this.advance,
  });
}

// ---------------------------------------------------------------------------
// Persistent key-value storage
// ---------------------------------------------------------------------------

abstract class StorageBackend {
  void save(String key, String value);
  String? load(String key);
  void delete(String key);
  void clear();
  List<String> getAllKeys();
}

// ---------------------------------------------------------------------------
// Platform factory
// ---------------------------------------------------------------------------

/// Creates the correct backend set for the current platform.
abstract class PlatformFactory {
  WindowBackend createWindow(AppConfig config);
  RendererBackend createRenderer(WindowBackend window);
  AudioBackend createAudio();
  KeyboardBackend createKeyboard(WindowBackend window);
  MouseBackend createMouse(WindowBackend window);
  GamepadBackend createGamepad();
  AccelerometerBackend createAccelerometer();
  FileBackend createFileLoader();
  ImageLoaderBackend createImageLoader();
  FontRasterizerBackend createFontRasterizer();
  StorageBackend createStorage();
}
