import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/app/app_config.dart';
import 'package:bullseye2d/bullseye2d.dart' show die;
import 'package:web/web.dart' show ErrorEvent, FocusEvent, HTMLCanvasElement, document, window;
import 'dart:js_interop';

// HTMLWindow
class WebWindowBackend implements WindowBackend {
  late final HTMLCanvasElement canvas;
  final AppConfig _config;

  void Function()? _onFocusCallback;
  void Function()? _onBlurCallback;

  WebWindowBackend(this._config);

  void init() {
    var root = document.querySelector(_config.canvasElement) as HTMLCanvasElement?;
    if (root == null) {
      die("Could not find canvas: ${_config.canvasElement}");
      return;
    }
    canvas = root;

    canvas.addEventListener(
      'focus',
      (FocusEvent e) {
        _onFocusCallback?.call();
      }.toJS,
    );

    canvas.addEventListener(
      'blur',
      (FocusEvent e) {
        _onBlurCallback?.call();
      }.toJS,
    );

    window.addEventListener(
      'error',
      (ErrorEvent event) {
        // Error events are handled by App
      }.toJS,
    );
  }

  @override
  int get width => canvas.width;

  @override
  int get height => canvas.height;

  @override
  int get displayWidth => canvas.clientWidth;

  @override
  int get displayHeight => canvas.clientHeight;

  @override
  String getPlatform() {
    final platform = window.navigator.platform.toLowerCase();
    final isIOS =
        ['ipad simulator', 'iphone simulator', 'ipod simulator', 'ipad', 'iphone', 'ipod'].contains(platform) ||
        (platform == 'macintel' && window.navigator.maxTouchPoints > 1);
    return isIOS ? 'ios' : 'web';
  }

  @override
  void setSize(int w, int h) {
    canvas.width = w;
    canvas.height = h;
  }

  @override
  void setTitle(String title) {
    document.title = title;
  }

  @override
  void focus() {
    canvas.focus();
  }

  @override
  void setCursorVisible(bool visible) {
    canvas.style.cursor = visible ? 'default' : 'none';
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
    return window.performance.now();
  }

  @override
  void requestAnimationFrame(void Function() callback) {
    window.requestAnimationFrame(FunctionToJSExportedDartFunction((num _) => callback()).toJS);
  }

  @override
  bool pumpEvents() => true;

  @override
  void dispose() {
    // Web: no explicit cleanup needed for the canvas
  }
}
