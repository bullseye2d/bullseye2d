import 'package:bullseye2d/src/backend/backend.dart';
import 'package:sdl3/sdl3.dart';
import 'dart:ffi';

class Sdl3KeyboardBackend implements KeyboardBackend {
  @override
  void Function(String code, String char)? onKeyDown;
  @override
  void Function(String code)? onKeyUp;

  @override
  void attach() {
    // Event processing happens in the SDL3 game loop.
    // Text input is started there as well.
  }

  @override
  void detach() {}

  @override
  void onEndFrame() {}

  @override
  void suspend() {}

  /// Called by the SDL3 event loop when a key event is received.
  void handleKeyEvent(Pointer<SdlEvent> event) {
    final keyEvent = event.key.ref;
    final scancode = keyEvent.scancode;
    final code = _scancodeToCode(scancode);

    if (keyEvent.down != 0) {
      final keyName = sdlGetKeyName(keyEvent.key) ?? '';
      final char = keyName.length == 1 ? keyName : '';
      onKeyDown?.call(code, char);
    } else {
      onKeyUp?.call(code);
    }
  }

  /// Called by the SDL3 event loop when a text input event is received.
  void handleTextInput(String text) {
    // Text input is forwarded as key-down with the character.
    // The Keyboard class will handle char buffering.
    for (final char in text.runes) {
      onKeyDown?.call('', String.fromCharCode(char));
    }
  }

  /// Maps SDL scancode to web-style key code string (e.g., "KeyA", "Space").
  static String _scancodeToCode(int scancode) {
    final name = sdlGetScancodeName(scancode);
    if (name == null || name.isEmpty) return 'Unknown';

    // SDL scancode names map reasonably to web KeyboardEvent.code values
    // with some transformations
    return _scancodeMap[scancode] ?? name;
  }

  static final Map<int, String> _scancodeMap = {
    SDL_SCANCODE_A: 'KeyA', SDL_SCANCODE_B: 'KeyB', SDL_SCANCODE_C: 'KeyC',
    SDL_SCANCODE_D: 'KeyD', SDL_SCANCODE_E: 'KeyE', SDL_SCANCODE_F: 'KeyF',
    SDL_SCANCODE_G: 'KeyG', SDL_SCANCODE_H: 'KeyH', SDL_SCANCODE_I: 'KeyI',
    SDL_SCANCODE_J: 'KeyJ', SDL_SCANCODE_K: 'KeyK', SDL_SCANCODE_L: 'KeyL',
    SDL_SCANCODE_M: 'KeyM', SDL_SCANCODE_N: 'KeyN', SDL_SCANCODE_O: 'KeyO',
    SDL_SCANCODE_P: 'KeyP', SDL_SCANCODE_Q: 'KeyQ', SDL_SCANCODE_R: 'KeyR',
    SDL_SCANCODE_S: 'KeyS', SDL_SCANCODE_T: 'KeyT', SDL_SCANCODE_U: 'KeyU',
    SDL_SCANCODE_V: 'KeyV', SDL_SCANCODE_W: 'KeyW', SDL_SCANCODE_X: 'KeyX',
    SDL_SCANCODE_Y: 'KeyY', SDL_SCANCODE_Z: 'KeyZ',
    SDL_SCANCODE_1: 'Digit1', SDL_SCANCODE_2: 'Digit2', SDL_SCANCODE_3: 'Digit3',
    SDL_SCANCODE_4: 'Digit4', SDL_SCANCODE_5: 'Digit5', SDL_SCANCODE_6: 'Digit6',
    SDL_SCANCODE_7: 'Digit7', SDL_SCANCODE_8: 'Digit8', SDL_SCANCODE_9: 'Digit9',
    SDL_SCANCODE_0: 'Digit0',
    SDL_SCANCODE_RETURN: 'Enter', SDL_SCANCODE_ESCAPE: 'Escape',
    SDL_SCANCODE_BACKSPACE: 'Backspace', SDL_SCANCODE_TAB: 'Tab',
    SDL_SCANCODE_SPACE: 'Space',
    SDL_SCANCODE_MINUS: 'Minus', SDL_SCANCODE_EQUALS: 'Equal',
    SDL_SCANCODE_LEFTBRACKET: 'BracketLeft', SDL_SCANCODE_RIGHTBRACKET: 'BracketRight',
    SDL_SCANCODE_BACKSLASH: 'Backslash', SDL_SCANCODE_SEMICOLON: 'Semicolon',
    SDL_SCANCODE_APOSTROPHE: 'Quote', SDL_SCANCODE_GRAVE: 'Backquote',
    SDL_SCANCODE_COMMA: 'Comma', SDL_SCANCODE_PERIOD: 'Period',
    SDL_SCANCODE_SLASH: 'Slash',
    SDL_SCANCODE_CAPSLOCK: 'CapsLock',
    SDL_SCANCODE_F1: 'F1', SDL_SCANCODE_F2: 'F2', SDL_SCANCODE_F3: 'F3',
    SDL_SCANCODE_F4: 'F4', SDL_SCANCODE_F5: 'F5', SDL_SCANCODE_F6: 'F6',
    SDL_SCANCODE_F7: 'F7', SDL_SCANCODE_F8: 'F8', SDL_SCANCODE_F9: 'F9',
    SDL_SCANCODE_F10: 'F10', SDL_SCANCODE_F11: 'F11', SDL_SCANCODE_F12: 'F12',
    SDL_SCANCODE_PRINTSCREEN: 'PrintScreen', SDL_SCANCODE_SCROLLLOCK: 'ScrollLock',
    SDL_SCANCODE_PAUSE: 'Pause', SDL_SCANCODE_INSERT: 'Insert',
    SDL_SCANCODE_HOME: 'Home', SDL_SCANCODE_PAGEUP: 'PageUp',
    SDL_SCANCODE_DELETE: 'Delete', SDL_SCANCODE_END: 'End',
    SDL_SCANCODE_PAGEDOWN: 'PageDown',
    SDL_SCANCODE_RIGHT: 'ArrowRight', SDL_SCANCODE_LEFT: 'ArrowLeft',
    SDL_SCANCODE_DOWN: 'ArrowDown', SDL_SCANCODE_UP: 'ArrowUp',
    SDL_SCANCODE_NUMLOCKCLEAR: 'NumLock',
    SDL_SCANCODE_LCTRL: 'ControlLeft', SDL_SCANCODE_LSHIFT: 'ShiftLeft',
    SDL_SCANCODE_LALT: 'AltLeft', SDL_SCANCODE_LGUI: 'MetaLeft',
    SDL_SCANCODE_RCTRL: 'ControlRight', SDL_SCANCODE_RSHIFT: 'ShiftRight',
    SDL_SCANCODE_RALT: 'AltRight', SDL_SCANCODE_RGUI: 'MetaRight',
  };
}
