import 'dart:io';

void debugOutput(List<dynamic> parts, String method) {
  final message = parts.map((p) => p.toString()).join(' ');
  final sink = (method == 'error' || method == 'warn') ? stderr : stdout;
  sink.writeln(message);
}
