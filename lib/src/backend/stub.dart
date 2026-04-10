import 'package:bullseye2d/src/app/app_config.dart';
import 'package:bullseye2d/src/backend/backend.dart';

/// Stub factory used by the analyzer when neither dart:io nor dart:js_interop
/// is available. All methods throw at runtime.
class PlatformFactoryImpl extends PlatformFactory {
  @override
  WindowBackend createWindow(AppConfig config) => throw _unsupported();

  @override
  RendererBackend createRenderer(WindowBackend window) => throw _unsupported();

  @override
  AudioBackend createAudio() => throw _unsupported();

  @override
  KeyboardBackend createKeyboard(WindowBackend window) => throw _unsupported();

  @override
  MouseBackend createMouse(WindowBackend window) => throw _unsupported();

  @override
  GamepadBackend createGamepad() => throw _unsupported();

  @override
  AccelerometerBackend createAccelerometer() => throw _unsupported();

  @override
  FileBackend createFileLoader() => throw _unsupported();

  @override
  ImageLoaderBackend createImageLoader() => throw _unsupported();

  @override
  FontRasterizerBackend createFontRasterizer() => throw _unsupported();

  @override
  StorageBackend createStorage() => throw _unsupported();
}

UnsupportedError _unsupported() => UnsupportedError('No platform implementation available.');
