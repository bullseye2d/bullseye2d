import 'dart:js_interop';
import 'dart:js_util'; // ignore: deprecated_member_use

import 'package:web/web.dart' show console;

void debugOutput(List<dynamic> parts, String method) {
  final args = parts.map((p) => p is String ? p.toJS : jsify(p)).toList();
  callMethod(console, method, args);
}
