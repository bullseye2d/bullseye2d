import 'dart:async';
import 'dart:ffi';
import 'dart:io' show Platform, exit;
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/app/app_config.dart';
import 'package:bullseye2d/src/backend/sdl3/keyboard.dart';
import 'package:bullseye2d/src/backend/sdl3/mouse.dart';
import 'package:bullseye2d/src/backend/sdl3/gamepad.dart';
import 'package:ffi/ffi.dart';
import 'package:sdl3/sdl3.dart';

// ==> SDLWindow
class Sdl3WindowBackend implements WindowBackend {
  late final Pointer<SdlWindow> sdlWindow;
  final AppConfig _config;

  @override
  String getPlatform() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'native';
  }

  void Function()? _onFocusCallback;
  void Function()? _onBlurCallback;

  bool _running = true;

  // High-res timer
  late final int _perfFrequency;

  // Input backends — assigned after construction for event dispatch
  Sdl3KeyboardBackend? keyboardBackend;
  Sdl3MouseBackend? mouseBackend;
  Sdl3GamepadBackend? gamepadBackend;

  Sdl3WindowBackend(this._config);

  void init() {
    int flags = 0;
    if (_config.resizable) flags |= SDL_WINDOW_RESIZABLE;
    if (_config.fullscreen) flags |= SDL_WINDOW_FULLSCREEN;

    sdlWindow = sdlCreateWindow(_config.title, _config.width, _config.height, flags);
    if (sdlWindow == nullptr) {
      throw Exception('Failed to create SDL window: ${sdlGetError()}');
    }

    _perfFrequency = sdlGetPerformanceFrequency();

    sdlStartTextInput(sdlWindow);
  }

  @override
  int get width {
    final w = calloc<Int32>();
    final h = calloc<Int32>();
    sdlGetWindowSize(sdlWindow, w, h);
    final result = w.value;
    calloc.free(w);
    calloc.free(h);
    return result;
  }

  @override
  int get height {
    final w = calloc<Int32>();
    final h = calloc<Int32>();
    sdlGetWindowSize(sdlWindow, w, h);
    final result = h.value;
    calloc.free(w);
    calloc.free(h);
    return result;
  }

  @override
  int get displayWidth => width;

  @override
  int get displayHeight => height;

  @override
  void setSize(int w, int h) {
    sdlSetWindowSize(sdlWindow, w, h);
  }

  @override
  void setTitle(String title) {
    sdlSetWindowTitle(sdlWindow, title);
  }

  @override
  void focus() {
    sdlRaiseWindow(sdlWindow);
  }

  @override
  void setCursorVisible(bool visible) {
    if (visible) {
      sdlShowCursor();
    } else {
      sdlHideCursor();
    }
  }

  @override
  void onFocus(void Function() callback) {
    _onFocusCallback = callback;
  }

  @override
  void onBlur(void Function() callback) {
    _onBlurCallback = callback;
  }

  @override
  double now() {
    return (sdlGetPerformanceCounter() / _perfFrequency) * 1000.0;
  }

  @override
  bool pumpEvents() {
    if (!_running) return false;
    if (!processEvents()) {
      _running = false;
      return false;
    }
    return true;
  }

  @override
  void requestAnimationFrame(void Function() callback) {
    Timer(Duration.zero, callback);
  }

  /// Process all pending SDL events. Called once per frame from the game loop.
  /// Returns false if the application should quit.
  bool processEvents() {
    final event = calloc<SdlEvent>();
    try {
      while (sdlPollEvent(event)) {
        final type = event.type;
        switch (type) {
          case SDL_EVENT_QUIT:
            return false;

          case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
            return false;

          case SDL_EVENT_WINDOW_FOCUS_GAINED:
            _onFocusCallback?.call();

          case SDL_EVENT_WINDOW_FOCUS_LOST:
            _onBlurCallback?.call();

          case SDL_EVENT_KEY_DOWN:
          case SDL_EVENT_KEY_UP:
            keyboardBackend?.handleKeyEvent(event);

          case SDL_EVENT_TEXT_INPUT:
            final textEvent = event.text.ref;
            final textPtr = textEvent.text;
            if (textPtr != nullptr) {
              final textStr = textPtr.toDartString();
              if (textStr.isNotEmpty) {
                keyboardBackend?.handleTextInput(textStr);
              }
            }

          case SDL_EVENT_MOUSE_MOTION:
            mouseBackend?.handleMotion(event);

          case SDL_EVENT_MOUSE_BUTTON_DOWN:
          case SDL_EVENT_MOUSE_BUTTON_UP:
            mouseBackend?.handleButton(event);

          case SDL_EVENT_MOUSE_WHEEL:
            mouseBackend?.handleWheel(event);

          case SDL_EVENT_FINGER_DOWN:
            final finger = event.tfinger.ref;
            mouseBackend?.onTouchStart?.call(finger.fingerId.hashCode, finger.x.toDouble(), finger.y.toDouble(), finger.pressure.toDouble());

          case SDL_EVENT_FINGER_MOTION:
            final finger = event.tfinger.ref;
            mouseBackend?.onTouchMove?.call(finger.fingerId.hashCode, finger.x.toDouble(), finger.y.toDouble(), finger.pressure.toDouble());

          case SDL_EVENT_FINGER_UP:
            final finger = event.tfinger.ref;
            mouseBackend?.onTouchEnd?.call(finger.fingerId.hashCode);

          case SDL_EVENT_GAMEPAD_ADDED:
            final devEvent = event.gdevice.ref;
            gamepadBackend?.handleDeviceAdded(devEvent.which);

          case SDL_EVENT_GAMEPAD_REMOVED:
            final devEvent = event.gdevice.ref;
            gamepadBackend?.handleDeviceRemoved(devEvent.which);
        }
      }
    } finally {
      calloc.free(event);
    }
    return true;
  }

  /// Run the SDL3 synchronous game loop.
  /// This blocks until the application exits.
  void runLoop(void Function() onFrame) {
    _running = true;
    while (_running) {
      if (!processEvents()) {
        _running = false;
        break;
      }
      onFrame();
    }
  }

  void stopLoop() {
    _running = false;
  }

  @override
  void dispose() {
    sdlStopTextInput(sdlWindow);
    sdlDestroyWindow(sdlWindow);
    sdlQuit();
    exit(0);
  }
}
