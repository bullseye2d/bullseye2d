import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart';
import 'dart:collection';
import 'dart:js_interop';

/// {@category Input}
enum _KeyEvent { keyDown, keyChar, keyUp }

/// {@category Input}
/// Represents a single character input event, including the character symbol
/// and the physical key code that produced it.
class Char {
  /// The string representation of the character (e.g., "a", "!", "?").
  final String symbol;

  /// The [KeyCodes] enum value representing the physical key pressed
  /// to generate this character.
  final KeyCodes physicalKey;

  /// A pre-defined empty `Char` instance, representing no character input.
  /// Useful for returning from methods like [Keyboard.getChar] when the
  /// character queue is empty.
  static final Char empty = Char("", KeyCodes.Unknown);

  /// Creates a new [Char] instance.
  ///
  /// - [symbol]: The character symbol.
  /// - [physicalKey]: The [KeyCodes] of the physical key.
  Char(this.symbol, this.physicalKey);

  @override
  String toString() => 'Char(symbol: "$symbol", physicalKey: ${physicalKey.code})';
}

/// {@category Input}
/// Manages keyboard input, tracking key states (down, up, hit) and
/// buffering character input.
class Keyboard {
  static const _maxCharQueuePerFrame = 32;

  final Map<KeyCodes, bool> _keyDown = {};
  final Map<KeyCodes, bool> _keyUp = {};
  final Map<KeyCodes, int> _keyHit = {};

  final Queue<Char> _charQueue = Queue<Char>();

  /// Creates a new [Keyboard] instance.
  ///
  /// Typically, you don't instantiate this class yourself. Instead, you use
  /// the `app.keyboard` member provided by the [App] class.
  ///
  /// - [canvas]: The [HTMLCanvasElement] to listen for keyboard events on.
  ///   The canvas should be focusable to receive keyboard input.
  Keyboard(HTMLCanvasElement canvas) {
    canvas.addEventListener(
      'keydown',
      (KeyboardEvent event) {
        _onKeyEvent(_KeyEvent.keyDown, event);
        _onKeyEvent(_KeyEvent.keyChar, event);
        if ((event.keyCode > 0 && event.keyCode < 48) || (event.keyCode > 111 && event.keyCode < 122)) {
          stopEvent(event);
        }
      }.toJS,
    );

    canvas.addEventListener(
      'keyup',
      (KeyboardEvent event) {
        _onKeyEvent(_KeyEvent.keyUp, event);
      }.toJS,
    );
  }

  /// @nodoc
  onEndFrame() {
    _keyUp.clear();
    _keyHit.clear();
  }

  /// @nodoc
  suspend() {
    for (var item in _keyDown.entries) {
      if (item.value) {
        _keyUp[item.key] = true;
      }
    }
  }

  /// Checks if a specific [key] is currently held down.
  ///
  /// - [key]: The [KeyCodes] value to check.
  ///
  /// Returns `true` if the [key] is down, `false` otherwise.
  /// Returns `false` if [key] is [KeyCodes.Unknown].
  bool keyDown(KeyCodes key) {
    return (key == KeyCodes.Unknown) ? false : _keyDown[key] ?? false;
  }

  /// Checks if a specific [key] was released during the current frame.
  ///
  /// - [key]: The [KeyCodes] value to check.
  ///
  /// Returns `true` if the [key] was released in this frame, `false` otherwise.
  /// Returns `false` if [key] is [KeyCodes.Unknown].
  bool keyUp(KeyCodes key) {
    return (key == KeyCodes.Unknown) ? false : _keyUp[key] ?? false;
  }

  /// Checks if a specific [key] was pressed (hit) during the current frame.
  ///
  /// "Hit" means the key transitioned from an "up" state to a "down" state
  /// in this frame. A key can be "hit" multiple times if it's pressed rapidly,
  /// see [keyHitCountSinceLastFrame].
  ///
  /// - [key]: The [KeyCodes] value to check.
  ///
  /// Returns `true` if the [key] was pressed in this frame at least once, `false` otherwise.
  /// Returns `false` if [key] is [KeyCodes.Unknown].
  bool keyHit(KeyCodes key) {
    return (key == KeyCodes.Unknown) ? false : (_keyHit[key] ?? 0) > 0;
  }

  /// Gets the number of times a specific [key] was pressed (hit) during the current frame.
  ///
  /// This can be greater than 1 if the key was pressed multiple times rapidly
  /// within the same frame (e.g., due to browser key repeat or very fast tapping).
  ///
  /// - [key]: The [KeyCodes] value to check.
  ///
  /// Returns the number of times the [key] was hit in this frame.
  /// Returns `0` if [key] is [KeyCodes.Unknown].
  int keyHitCountSinceLastFrame(KeyCodes key) {
    return (key == KeyCodes.Unknown) ? 0 : _keyHit[key] ?? 0;
  }

  /// Retrieves all characters currently in the input buffer as a single string.
  ///
  /// This does *not* remove the characters from the buffer.
  /// Use [getChar] to consume characters.
  /// The buffer holds characters entered since the last calls to [getChar]
  /// or since the buffer was last full (oldest characters are discarded if full).
  ///
  /// Returns a string containing all buffered characters.
  String getCharBuffer() {
    var result = StringBuffer();
    for (var char in _charQueue) {
      result.write(char.symbol);
    }
    return result.toString();
  }

  /// Retrieves and removes the next character from the input queue.
  ///
  /// The queue is populated by `keypress` or equivalent events, typically
  /// filtering out control keys.
  ///
  /// Returns the oldest [Char] in the queue.
  /// If the queue is empty, returns [Char.empty].
  Char getChar() {
    if (_charQueue.isEmpty) return Char.empty;
    return _charQueue.removeFirst();
  }

  /// Peeks at a character in the input queue at a specific [index]
  /// without removing it.
  ///
  /// Returns the [Char] at the given [index].
  /// If [index] is out of bounds or the queue is empty, returns [Char.empty].
  Char peekChar(int index) {
    return (index >= 0 && index < _charQueue.length) ? _charQueue.elementAt(index) : Char.empty;
  }

  _onKeyEvent(_KeyEvent type, KeyboardEvent keyEvent) {
    final String code = keyEvent.code;
    final String keyString = keyEvent.key;

    final KeyCodes keyEnum = KeyCodes.fromCode(code);

    if (keyEnum != KeyCodes.Unknown) {
      switch (type) {
        case _KeyEvent.keyDown:
          if (_keyDown[keyEnum] != true) {
            _keyDown[keyEnum] = true;
            _keyHit[keyEnum] = (_keyHit[keyEnum] ?? 0) + 1;
          }
          break;

        case _KeyEvent.keyUp:
          _keyUp[keyEnum] = true;
          _keyDown.remove(keyEnum);
          break;

        case _KeyEvent.keyChar:
          break;
      }
    }

    if (type == _KeyEvent.keyChar) {
      if (keyString.length == 1 && !keyEvent.ctrlKey && !keyEvent.altKey && !keyEvent.metaKey) {
        if (_charQueue.length >= _maxCharQueuePerFrame) {
          _charQueue.removeFirst();
        }
        _charQueue.addLast(Char(keyString, keyEnum));
      }
    }
  }
}
