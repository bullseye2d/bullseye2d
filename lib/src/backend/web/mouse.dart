import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/backend/web/event_helper.dart';
import 'package:web/web.dart'
    show
        AddEventListenerOptions,
        Element,
        Event,
        HTMLCanvasElement,
        HTMLElement,
        MouseEvent,
        PointerEvent,
        Touch,
        TouchEvent,
        WheelEvent,
        window;
import 'dart:js_interop';

class WebMouseBackend implements MouseBackend {
  final HTMLCanvasElement _canvas;

  double _scaleX = 1.0;
  double _scaleY = 1.0;

  WebMouseBackend(this._canvas);

  @override
  void Function(double x, double y)? onMove;
  @override
  void Function(int button)? onButtonDown;
  @override
  void Function(int button)? onButtonUp;
  @override
  void Function(int delta)? onWheel;
  @override
  void Function(int id, double x, double y, double force)? onTouchStart;
  @override
  void Function(int id, double x, double y, double force)? onTouchMove;
  @override
  void Function(int id)? onTouchEnd;
  @override
  void Function()? onFirstClick;

  @override
  void attach() {
    var opt = AddEventListenerOptions(passive: false);

    _canvas.addEventListener('wheel', _onWheel.toJS, opt);
    _canvas.addEventListener('contextmenu', _onContextMenu.toJS);
    _canvas.addEventListener('touchstart', _onTouchStart.toJS, opt);
    _canvas.addEventListener('touchmove', _onTouchMove.toJS, opt);
    _canvas.addEventListener('touchend', _onTouchEnd.toJS, opt);
    _canvas.addEventListener('fullscreenchange', _onFullscreenChange.toJS);
    _canvas.addEventListener('click', _onClick.toJS);

    window.addEventListener('resize', _onResize.toJS);
    window.addEventListener('mousedown', _onMouseDown.toJS);
    window.addEventListener('mouseup', _onMouseUp.toJS);
    window.addEventListener('mousemove', _onMouseMove.toJS);

    _updateSize();
  }

  @override
  void detach() {
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

  @override
  void onEndFrame() {}

  @override
  void suspend() {}

  void _onWheel(WheelEvent event) {
    onWheel?.call(event.deltaY.sign.toInt());
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
        onTouchStart?.call(id, _touchX(touch), _touchY(touch), touch.force);
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
        onTouchMove?.call(id, _touchX(touch), _touchY(touch), touch.force);
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
        onTouchEnd?.call(id);
      }
    }
    if (onFirstClick == null) {
      stopEvent(event);
    }
  }

  void _onMouseDown(MouseEvent event) {
    onButtonDown?.call(event.button);
    stopEvent(event);
  }

  void _onMouseUp(MouseEvent event) {
    onButtonUp?.call(event.button);
    if (onFirstClick == null) {
      stopEvent(event);
    }
  }

  void _onMouseMove(MouseEvent event) {
    onMove?.call(_mouseX(event), _mouseY(event));
    if (onFirstClick == null) {
      stopEvent(event);
    }
  }

  void _onResize(Event event) {
    _updateSize();
  }

  void _onFullscreenChange(Event event) {
    _updateSize();
  }

  void _updateSize() {
    _scaleX = (_canvas.clientWidth == 0) ? 1.0 : _canvas.width / _canvas.clientWidth;
    _scaleY = (_canvas.clientHeight == 0) ? 1.0 : _canvas.height / _canvas.clientHeight;
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
    return x * _scaleX;
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
    return y * _scaleY;
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
    return x * _scaleX;
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
    return y * _scaleY;
  }
}
