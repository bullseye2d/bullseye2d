import 'package:bullseye2d/src/app/app_config.dart';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/backend/web/accelerometer.dart';
import 'package:bullseye2d/src/backend/web/audio.dart';
import 'package:bullseye2d/src/backend/web/file.dart';
import 'package:bullseye2d/src/backend/web/font_rasterizer.dart';
import 'package:bullseye2d/src/backend/web/gamepad.dart';
import 'package:bullseye2d/src/backend/web/image_loader.dart';
import 'package:bullseye2d/src/backend/web/keyboard.dart';
import 'package:bullseye2d/src/backend/web/mouse.dart';
import 'package:bullseye2d/src/backend/web/renderer.dart';
import 'package:bullseye2d/src/backend/web/storage.dart';
import 'package:bullseye2d/src/backend/web/window.dart';

class PlatformFactoryImpl extends PlatformFactory {
  @override
  WindowBackend createWindow(AppConfig config) {
    final window = WebWindowBackend(config);
    window.init();
    return window;
  }

  @override
  RendererBackend createRenderer(WindowBackend window) {
    final webWindow = window as WebWindowBackend;
    return WebRendererBackend(webWindow.canvas);
  }

  @override
  AudioBackend createAudio() {
    final audio = WebAudioBackend();
    audio.init();
    return audio;
  }

  @override
  KeyboardBackend createKeyboard(WindowBackend window) {
    final webWindow = window as WebWindowBackend;
    return WebKeyboardBackend(webWindow.canvas);
  }

  @override
  MouseBackend createMouse(WindowBackend window) {
    final webWindow = window as WebWindowBackend;
    return WebMouseBackend(webWindow.canvas);
  }

  @override
  GamepadBackend createGamepad() {
    return WebGamepadBackend();
  }

  @override
  AccelerometerBackend createAccelerometer() {
    return WebAccelerometerBackend();
  }

  @override
  FileBackend createFileLoader() {
    return WebFileBackend();
  }

  @override
  ImageLoaderBackend createImageLoader() {
    return WebImageLoaderBackend();
  }

  @override
  FontRasterizerBackend createFontRasterizer() {
    return WebFontRasterizerBackend();
  }

  @override
  StorageBackend createStorage() {
    return WebStorageBackend();
  }
}
