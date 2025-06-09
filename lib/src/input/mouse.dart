import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart';
import 'dart:js_interop';

String f = "";

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
/// Manages mouse and touch input.
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

  final HTMLCanvasElement _canvas;

  final List<_TouchInfo> _touchState = List.generate(_maxTouchIds, (_) => _TouchInfo(), growable: false);

  final _mouseDown = List.filled(_maxMouseButtons, false);
  final _mouseHit = List.filled(
    _maxMouseButtons,
    false,
  ); //TODO: An integer holding the number of times the button was hit is better?
  final _mouseUp = List.filled(_maxMouseButtons, false);

  /// The accumulated mouse wheel movement since the last frame.
  int mouseWheel = 0;

  /// Function that can be used when user interacts with canvas for the first time
  void Function()? onFirstClick;

  /// Creates a [Mouse] instance and attaches event listeners to the provided [_canvas].
  /// Typically, you don't instantiate this class yourself. Instead, you use
  /// the `app.mouse` member provided by the [App] class.
  Mouse(this._canvas) {
    // NOTE:
    // https://developer.mozilla.org/de/docs/Web/API/EventTarget/addEventListener
    // In Safari for wheel and touch events the passive default value is true, so
    // we force it to false, because else preventEvent doesn't work
    var opt = AddEventListenerOptions(passive: false);

    _canvas.addEventListener('wheel', _onWheel.toJS, opt);
    _canvas.addEventListener('contextmenu', _onContextMenu.toJS);
    _canvas.addEventListener('touchstart', _onTouchStart.toJS, opt);
    _canvas.addEventListener('touchmove', _onTouchMove.toJS, opt);
    _canvas.addEventListener('touchend', _onTouchEnd.toJS, opt);
    _canvas.addEventListener('fullscreenchange', _onFullscreenChange.toJS);

    window.addEventListener('resize', _onResize.toJS);

    window.addEventListener('mousedown', _onMouseDown.toJS);
    window.addEventListener('mouseup', _onMouseUp.toJS);
    window.addEventListener('mousemove', _onMouseMove.toJS);

    _canvas.addEventListener('click', _onClick.toJS);
    _updateSize();
  }

  /// Removes all event listeners previously attached by this [Mouse] instance.
  dispose() {
    _canvas.removeEventListener('wheel', _onWheel.toJS);
    _canvas.removeEventListener('click', _onClick.toJS);
    _canvas.removeEventListener('contextmenu', _onContextMenu.toJS);
    _canvas.removeEventListener('touchstart', _onTouchStart.toJS);
    _canvas.removeEventListener('touchmove', _onTouchMove.toJS);
    _canvas.removeEventListener('touchend', _onTouchEnd.toJS);
    _canvas.removeEventListener('fullscreenchange', _onFullscreenChange.toJS);

    window.removeEventListener('resize', _onResize.toJS);

    window.removeEventListener('mousedown', _onMouseDown.toJS);
    window.removeEventListener('mouseup', _onMouseUp.toJS);
    window.removeEventListener('mousemove', _onMouseMove.toJS);
  }

  /// @nodoc
  suspend() {
    for (var touch in _touchState) {
      if (touch.down = true) {
        touch.up = true;
      }
    }
  }

  /// @nodoc
  onEndFrame() {
    mouseWheel = 0;
    for (var touch in _touchState) {
      touch.hit = 0;
      touch.up = false;
    }

    _mouseHit.fillRange(0, _mouseHit.length, false);
    _mouseUp.fillRange(0, _mouseUp.length, false);
  }

  void _onWheel(WheelEvent event) {
    mouseWheel += event.deltaY.sign.toInt();
    stopEvent(event);
  }

  void _onClick(MouseEvent event) {
    _canvas.focus();

    onFirstClick?.call();
    onFirstClick = null;

    stopEvent(event);
  }

  JSAny _onContextMenu(PointerEvent event) {
    stopEvent(event);
    return false.toJS;
  }

  void _onTouchStart(TouchEvent event) {
    _canvas.focus();

    var changedTouches = event.changedTouches;
    for (var i = 0; i < changedTouches.length; i++) {
      var touch = changedTouches.item(i);
      if (touch != null) {
        var id = touch.identifier.toInt();
        for (var i = 0; i < _maxTouchIds; ++i) {
          if (_touchState[i].id != -1) continue;
          _touchState[i]
            ..id = id
            ..x = _touchX(touch)
            ..y = _touchY(touch)
            ..down = true
            ..force = touch.force
            ..hit += 1;

          if (i == 0) {
            _mouseHit[0] = true;
            _mouseDown[0] = true;
            x = _touchState[i].x;
            y = _touchState[i].y;
          }
          break;
        }
      }
    }
    if (onFirstClick == null) {
      stopEvent(event);
    }
  }

  void _onTouchMove(TouchEvent event) {
    var changedTouches = event.changedTouches;
    for (var i = 0; i < changedTouches.length; i++) {
      var touch = changedTouches.item(i);
      if (touch != null) {
        var id = touch.identifier.toInt();
        for (var i = 0; i < _maxTouchIds; ++i) {
          if (_touchState[i].id != id) continue;
          _touchState[i]
            ..x = _touchX(touch)
            ..y = _touchY(touch)
            ..down = true
            ..force = touch.force;

          if (i == 0) {
            _mouseDown[0] = true;
            x = _touchState[i].x;
            y = _touchState[i].y;
          }
          break;
        }
      }
    }

    if (onFirstClick == null) {
      stopEvent(event);
    }
  }

  void _onTouchEnd(TouchEvent event) {
    var changedTouches = event.changedTouches;
    for (var i = 0; i < changedTouches.length; i++) {
      var touch = changedTouches.item(i);
      if (touch != null) {
        var id = touch.identifier.toInt();
        for (var i = 0; i < _maxTouchIds; ++i) {
          if (_touchState[i].id != id) continue;
          _touchState[i]
            ..id = -1
            ..x = _touchX(touch)
            ..y = _touchY(touch)
            ..down = false
            ..up = true
            ..force = touch.force;

          if (i == 0) {
            _mouseUp[0] = true;
            _mouseDown[0] = false;
            x = _touchState[i].x;
            y = _touchState[i].y;
          }
          break;
        }
      }
    }

    if (onFirstClick == null) {
      stopEvent(event);
    }
  }

  void _onMouseDown(MouseEvent event) {
    if (event.button < _mouseDown.length) {
      _mouseDown[event.button] = true;
      _mouseHit[event.button] = true;
    }
    stopEvent(event);
    if (onFirstClick == null) {
      stopEvent(event);
    }
  }

  void _onMouseUp(MouseEvent event) {
    if (event.button < _mouseDown.length) {
      _mouseDown[event.button] = false;
      _mouseUp[event.button] = true;
    }

    if (onFirstClick == null) {
      stopEvent(event);
    }
  }

  void _onMouseMove(MouseEvent event) {
    x = _mouseX(event);
    y = _mouseY(event);

    if (onFirstClick == null) {
      stopEvent(event);
    }
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

  /// Checks if the finger with the specified index us currently touching the touchscreen.
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

  void _onResize(Event event) {
    _updateSize();
  }

  void _onFullscreenChange(Event event) {
    _updateSize();
  }

  _updateSize() {
    scaleX = (_canvas.clientWidth == 0) ? 1.0 : _canvas.width / _canvas.clientWidth;
    scaleY = (_canvas.clientHeight == 0) ? 1.0 : _canvas.height / _canvas.clientHeight;
  }

  double _mouseX(MouseEvent event) {
    double x = event.clientX + window.scrollX;
    Element? el = _canvas;
    while (el != null) {
      if (el.isA<HTMLElement>()) {
        x -= (el as HTMLElement).offsetLeft;
        el = el.offsetParent;
      } else {
        el = null;
      }
    }
    return x * scaleX;
  }

  double _mouseY(MouseEvent event) {
    double y = event.clientY + window.scrollY;
    Element? el = _canvas;
    while (el != null) {
      if (el.isA<HTMLElement>()) {
        y -= (el as HTMLElement).offsetTop;
        el = el.offsetParent;
      } else {
        el = null;
      }
    }
    return y * scaleY;
  }

  double _touchX(Touch touch) {
    double x = touch.pageX;
    Element? el = _canvas;
    while (el != null) {
      if (el.isA<HTMLElement>()) {
        x -= (el as HTMLElement).offsetLeft;
        el = el.offsetParent;
      } else {
        el = null;
      }
    }
    return x * scaleX;
  }

  double _touchY(Touch touch) {
    double y = touch.pageY;
    Element? el = _canvas;
    while (el != null) {
      if (el.isA<HTMLElement>()) {
        y -= (el as HTMLElement).offsetTop;
        el = el.offsetParent;
      } else {
        el = null;
      }
    }
    return y * scaleY;
  }
}
