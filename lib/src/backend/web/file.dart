import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/bullseye2d.dart' show warn;
import 'package:web/web.dart';
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

class WebFileBackend implements FileBackend {
  @override
  Future<Uint8List> loadBytes(String path) async {
    final completer = Completer<Uint8List>();
    final xhr = XMLHttpRequest();

    void error(Event event) {
      warn("Could not load: $path (${xhr.status} : ${xhr.statusText})");
      completer.complete(Uint8List(0));
    }

    void load(Event event) {
      if (xhr.status >= 200 && xhr.status < 300) {
        final response = xhr.response;
        if (response != null && response.isA<JSArrayBuffer>()) {
          completer.complete((response as JSArrayBuffer).toDart.asUint8List());
        } else {
          completer.complete(Uint8List(0));
        }
      } else {
        error(event);
      }
    }

    xhr.open('GET', path);
    xhr.responseType = 'arraybuffer';
    xhr.addEventListener('load', load.toJS);
    xhr.addEventListener('error', error.toJS);
    xhr.addEventListener('abort', error.toJS);
    xhr.send();

    return completer.future;
  }

  @override
  Future<String> loadString(String path) async {
    final completer = Completer<String>();
    final xhr = XMLHttpRequest();

    void error(Event event) {
      warn("Could not load: $path (${xhr.status} : ${xhr.statusText})");
      completer.complete('');
    }

    void load(Event event) {
      if (xhr.status >= 200 && xhr.status < 300) {
        final response = xhr.response;
        if (response != null && response.isA<JSString>()) {
          completer.complete((response as JSString).toDart);
        } else {
          completer.complete('');
        }
      } else {
        error(event);
      }
    }

    xhr.open('GET', path);
    xhr.responseType = 'text';
    xhr.addEventListener('load', load.toJS);
    xhr.addEventListener('error', error.toJS);
    xhr.addEventListener('abort', error.toJS);
    xhr.send();

    return completer.future;
  }

  @override
  void onProgress(String path, void Function(int loaded, int total) callback) {
    // Progress tracking is handled by the existing load<T>() function in file.dart.
    // This is available for future use when FileBackend is the primary loading path.
  }
}
