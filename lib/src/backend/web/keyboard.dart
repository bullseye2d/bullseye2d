import 'package:bullseye2d/src/backend/backend.dart';
import 'package:web/web.dart' show HTMLCanvasElement, KeyboardEvent;
import 'dart:js_interop';

class WebKeyboardBackend implements KeyboardBackend {
  final HTMLCanvasElement _canvas;

  WebKeyboardBackend(this._canvas);

  @override
  void Function(String code, String char)? onKeyDown;

  @override
  void Function(String code)? onKeyUp;

  @override
  void attach() {
    _canvas.addEventListener('keydown', _onKeyDown.toJS);
    _canvas.addEventListener('keyup', _onKeyUp.toJS);
  }

  @override
  void detach() {
    _canvas.removeEventListener('keydown', _onKeyDown.toJS);
    _canvas.removeEventListener('keyup', _onKeyUp.toJS);
  }

  @override
  void onEndFrame() {}

  @override
  void suspend() {}

  void _onKeyDown(KeyboardEvent event) {
    final code = event.code;
    final key = event.key;
    onKeyDown?.call(code, key);
    // Prevent default for control keys to avoid browser shortcuts
    if ((event.keyCode > 0 && event.keyCode < 48) || (event.keyCode > 111 && event.keyCode < 122)) {
      event.stopPropagation();
      event.preventDefault();
    }
  }

  void _onKeyUp(KeyboardEvent event) {
    onKeyUp?.call(event.code);
  }
}
