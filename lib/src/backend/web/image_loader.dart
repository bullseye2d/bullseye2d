import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/bullseye2d.dart' show warn;
import 'package:web/web.dart';
import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

class WebImageLoaderBackend implements ImageLoaderBackend {
  @override
  Future<DecodedImage> decode(Uint8List bytes) async {
    final blob = Blob([bytes.toJS].toJS);
    final objectUrl = URL.createObjectURL(blob);
    try {
      return _loadFromUrl(objectUrl);
    } finally {
      URL.revokeObjectURL(objectUrl);
    }
  }

  @override
  Future<DecodedImage> decodeFromFile(String path) async {
    // Fetch as blob, create image element, draw to canvas to extract pixels
    final completer = Completer<DecodedImage>();
    final xhr = XMLHttpRequest();

    void error(Event event) {
      warn("Could not load image: $path (${xhr.status} : ${xhr.statusText})");
      completer.complete(DecodedImage(pixels: Uint8List(0), width: 0, height: 0));
    }

    void load(Event event) {
      if (xhr.status >= 200 && xhr.status < 300) {
        final blob = xhr.response as Blob?;
        if (blob != null) {
          final objectUrl = URL.createObjectURL(blob);
          _loadFromUrl(objectUrl).then((decoded) {
            URL.revokeObjectURL(objectUrl);
            completer.complete(decoded);
          });
        } else {
          completer.complete(DecodedImage(pixels: Uint8List(0), width: 0, height: 0));
        }
      } else {
        error(event);
      }
    }

    xhr.open('GET', path);
    xhr.responseType = 'blob';
    xhr.addEventListener('load', load.toJS);
    xhr.addEventListener('error', error.toJS);
    xhr.addEventListener('abort', error.toJS);
    xhr.send();

    return completer.future;
  }

  Future<DecodedImage> _loadFromUrl(String objectUrl) {
    final completer = Completer<DecodedImage>();
    final img = HTMLImageElement();
    img.src = objectUrl;
    img.addEventListener(
      'load',
      (Event event) {
        final canvas =
            HTMLCanvasElement()
              ..width = img.width
              ..height = img.height;
        final ctx = canvas.getContext('2d') as CanvasRenderingContext2D;
        ctx.drawImage(img, 0, 0);
        final imageData = ctx.getImageData(0, 0, img.width, img.height);
        final pixels = imageData.data.toDart.buffer.asUint8List();
        completer.complete(DecodedImage(pixels: pixels, width: img.width, height: img.height));
      }.toJS,
    );
    img.addEventListener(
      'error',
      (Event event) {
        warn("Error decoding image from URL");
        completer.complete(DecodedImage(pixels: Uint8List(0), width: 0, height: 0));
      }.toJS,
    );
    return completer.future;
  }
}
