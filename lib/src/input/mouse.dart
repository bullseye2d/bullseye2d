import 'package:bullseye2d/src/backend/backend.dart';

/// @nodoc
/// {@category Input}
class _TouchInfo {
  int id = -1;
  int hit = 0;
  bool down = false;
  bool up = false;
  double x = 0.0;
  double y = 0.0;
  double force = 0.0;
}

/// {@category Input}
/// Represents the buttons on a mouse.
enum MouseButton {
  // ignore: constant_identifier_names
  Left,

  // ignore: constant_identifier_names
  Middle,

  // ignore: constant_identifier_names
  Right,
}

/// {@category Input}
/// Manages mouse, touch, and pointer input.
class Mouse {
  static const _maxTouchIds = 32;
  static const _maxMouseButtons = 5;

  /// The current X-coordinate of the mouse cursor, relative to the canvas.
  double x = -double.maxFinite;

  /// The current Y-coordinate of the mouse cursor, relative to the canvas.
  double y = -double.maxFinite;

  /// The horizontal scaling factor applied to mouse coordinates.
  double scaleX = 1.0;

  /// The vertical scaling factor applied to mouse coordinates.
  double scaleY = 1.0;

  final List<_TouchInfo> _touchState = List.generate(_maxTouchIds, (_) => _TouchInfo(), growable: false);

  final _mouseDown = List.filled(_maxMouseButtons, false);
  final _mouseHit = List.filled(_maxMouseButtons, false);
  final _mouseUp = List.filled(_maxMouseButtons, false);

  /// The accumulated mouse wheel movement since the last frame.
  int mouseWheel = 0;

  /// Function that can be used when user interacts with canvas for the first time.
  void Function()? onFirstClick;

  /// @nodoc
  Mouse(MouseBackend backend) {
    backend.onMove = (double mx, double my) {
      x = mx;
      y = my;
    };

    backend.onButtonDown = (int button) {
      if (button < _mouseDown.length) {
        _mouseDown[button] = true;
        _mouseHit[button] = true;
      }
    };

    backend.onButtonUp = (int button) {
      if (button < _mouseDown.length) {
        _mouseDown[button] = false;
        _mouseUp[button] = true;
      }
    };

    backend.onWheel = (int delta) {
      mouseWheel += delta;
    };

    backend.onTouchStart = (int id, double tx, double ty, double force) {
      for (var i = 0; i < _maxTouchIds; ++i) {
        if (_touchState[i].id != -1) continue;
        _touchState[i]
          ..id = id
          ..x = tx
          ..y = ty
          ..down = true
          ..force = force
          ..hit += 1;

        if (i == 0) {
          _mouseHit[0] = true;
          _mouseDown[0] = true;
          x = _touchState[i].x;
          y = _touchState[i].y;
        }
        break;
      }
    };

    backend.onTouchMove = (int id, double tx, double ty, double force) {
      for (var i = 0; i < _maxTouchIds; ++i) {
        if (_touchState[i].id != id) continue;
        _touchState[i]
          ..x = tx
          ..y = ty
          ..down = true
          ..force = force;

        if (i == 0) {
          _mouseDown[0] = true;
          x = _touchState[i].x;
          y = _touchState[i].y;
        }
        break;
      }
    };

    backend.onTouchEnd = (int id) {
      for (var i = 0; i < _maxTouchIds; ++i) {
        if (_touchState[i].id != id) continue;
        _touchState[i]
          ..id = -1
          ..down = false
          ..up = true;

        if (i == 0) {
          _mouseUp[0] = true;
          _mouseDown[0] = false;
          x = _touchState[i].x;
          y = _touchState[i].y;
        }
        break;
      }
    };

    backend.onFirstClick = () {
      onFirstClick?.call();
      onFirstClick = null;
    };

    backend.attach();
  }

  /// @nodoc
  void suspend() {
    for (var touch in _touchState) {
      if (touch.down == true) {
        touch.up = true;
      }
    }
  }

  /// @nodoc
  void onEndFrame() {
    mouseWheel = 0;
    for (var touch in _touchState) {
      touch.hit = 0;
      touch.up = false;
    }

    _mouseHit.fillRange(0, _mouseHit.length, false);
    _mouseUp.fillRange(0, _mouseUp.length, false);
  }

  /// Checks if the specified mouse [button] is currently held down.
  ///
  /// Returns `true` if the button is down, `false` otherwise.
  bool mouseDown(MouseButton button) {
    return _mouseDown[button.index];
  }

  /// Checks if the specified mouse [button] was pressed in the current frame.
  ///
  /// Returns `true` if the button was hit, `false` otherwise.
  bool mouseHit(MouseButton button) {
    return _mouseHit[button.index];
  }

  /// Checks if the specified mouse [button] was released in the current frame.
  ///
  /// Returns `true` if the button was released, `false` otherwise.
  bool mouseUp(MouseButton button) {
    return _mouseUp[button.index];
  }

  /// Checks if the finger with the specified index is currently touching the touchscreen.
  bool touchDown(int index) {
    if (index < 0 || index >= _touchState.length) {
      return false;
    }
    return _touchState[index].down;
  }

  /// Returns the number of times the specified finger has made contact with
  /// the touchscreen since the last OnUpdate
  ///
  /// The index is the order of the touches that have been made.
  /// The first finger that touches the screen will be assigned index 0. The next finger
  /// will be assigned 1 and so on.
  int touchHit(int index) {
    if (index < 0 || index >= _touchState.length) {
      return 0;
    }
    return _touchState[index].hit;
  }

  /// Returns true if the finger has left the touch screen device.
  ///
  /// The index is the order of the touches that have been made.
  /// The first finger that touches the screen will be assigned index 0. The next finger
  /// will be assigned 1 and so on.
  bool touchUp(int index) {
    if (index < 0 || index >= _touchState.length) {
      return false;
    }
    return _touchState[index].up;
  }

  /// Returns the x coordinate of the finger on a touch screen device.
  ///
  /// The index is the order of the touches that have been made.
  /// The first finger that touches the screen will be assigned index 0. The next finger
  /// will be assigned 1 and so on.
  double touchX(int index) {
    if (index == 0 && _touchState.isEmpty) {
      return x;
    }

    if (index < 0 || index >= _touchState.length) {
      return 0;
    }

    return _touchState[index].x;
  }

  /// Returns the y coordinate of the finger on a touch screen device.
  ///
  /// The index is the order of the touches that have been made.
  /// The first finger that touches the screen will be assigned index 0. The next finger
  /// will be assigned 1 and so on.
  double touchY(int index) {
    if (index == 0 && _touchState.isEmpty) {
      return y;
    }

    if (index < 0 || index >= _touchState.length) {
      return 0;
    }

    return _touchState[index].y;
  }
}
