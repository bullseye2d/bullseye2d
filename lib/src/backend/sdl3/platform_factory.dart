import 'package:bullseye2d/src/app/app_config.dart';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/backend/sdl3/accelerometer.dart';
import 'package:bullseye2d/src/backend/sdl3/audio.dart';
import 'package:bullseye2d/src/backend/sdl3/file.dart';
import 'package:bullseye2d/src/backend/sdl3/font_rasterizer.dart';
import 'package:bullseye2d/src/backend/sdl3/gamepad.dart';
import 'package:bullseye2d/src/backend/sdl3/image_loader.dart';
import 'package:bullseye2d/src/backend/sdl3/keyboard.dart';
import 'package:bullseye2d/src/backend/sdl3/mouse.dart';
import 'package:bullseye2d/src/backend/sdl3/renderer.dart';
import 'package:bullseye2d/src/backend/sdl3/sdl3.dart';
import 'package:bullseye2d/src/backend/sdl3/storage.dart';
import 'package:bullseye2d/src/backend/sdl3/window.dart';
import 'package:sdl3/sdl3.dart';

class PlatformFactoryImpl extends PlatformFactory {
  bool _sdlInitialized = false;

  void _ensureSDLInit() {
    if (_sdlInitialized) return;
    loadSDL3();
    if (!sdlInit(SDL_INIT_VIDEO | SDL_INIT_AUDIO | SDL_INIT_GAMEPAD)) {
      throw Exception('Failed to initialize SDL3: ${sdlGetError()}');
    }
    ttfInit();
    _sdlInitialized = true;
  }

  @override
  WindowBackend createWindow(AppConfig config) {
    _ensureSDLInit();
    final window = Sdl3WindowBackend(config);
    window.init();
    return window;
  }

  @override
  RendererBackend createRenderer(WindowBackend window) {
    final nativeWindow = window as Sdl3WindowBackend;
    return Sdl3RendererBackend(nativeWindow.sdlWindow, batchCapacityInBytes: 65536);
  }

  @override
  AudioBackend createAudio() {
    _ensureSDLInit();
    final audio = Sdl3AudioBackend();
    audio.init();
    return audio;
  }

  @override
  KeyboardBackend createKeyboard(WindowBackend window) {
    final kb = Sdl3KeyboardBackend();
    if (window is Sdl3WindowBackend) {
      window.keyboardBackend = kb;
    }
    return kb;
  }

  @override
  MouseBackend createMouse(WindowBackend window) {
    final mb = Sdl3MouseBackend();
    if (window is Sdl3WindowBackend) {
      window.mouseBackend = mb;
    }
    return mb;
  }

  @override
  GamepadBackend createGamepad() {
    final gb = Sdl3GamepadBackend();
    return gb;
  }

  @override
  AccelerometerBackend createAccelerometer() {
    return Sdl3AccelerometerBackend();
  }

  @override
  FileBackend createFileLoader() {
    return Sdl3FileBackend();
  }

  @override
  ImageLoaderBackend createImageLoader() {
    return Sdl3ImageLoaderBackend();
  }

  @override
  FontRasterizerBackend createFontRasterizer() {
    return Sdl3FontRasterizerBackend();
  }

  @override
  StorageBackend createStorage() {
    return Sdl3StorageBackend();
  }
}
