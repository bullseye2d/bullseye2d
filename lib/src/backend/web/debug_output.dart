import 'dart:js_interop';

import 'package:web/web.dart' show console;

JSAny? _toJS(dynamic p) => (p is Object) ? p.jsify() : p as JSAny?;

void debugOutput(List<dynamic> parts, String method) {
  for (final arg in parts.map(_toJS)) {
    switch (method) {
      case 'error':
        console.error(arg);
      case 'warn':
        console.warn(arg);
      case 'info':
        console.info(arg);
      default:
        console.log(arg);
    }
  }
}
