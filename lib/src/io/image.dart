import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart';
import 'dart:async';
import 'dart:js_interop';

/// {@category IO}
/// Asynchronously loads image data from the specified [path] into an [HTMLImageElement].
///
/// - [path]: The URL or path to the image file.
/// - [loadingInfo]: A [Loader] instance to report loading progress and status.
///
/// Returns a [Future] that completes with the loaded [HTMLImageElement] on success,
/// or `null` if loading fails (e.g., network error, invalid image).
Future<HTMLImageElement?> loadImageData(String path, Loader loadingInfo) async {
  String? objectUrl;

  return load<HTMLImageElement?>(
    path,
    loadingInfo,
    responseType: "blob",
    defaultValue: null,
    onError: (event) {
      if (objectUrl != null) {
        URL.revokeObjectURL(objectUrl!);
      }
    },
    onLoad: (response, completer, onError) {
      final Blob? imageBlog = response as Blob?;
      if (imageBlog != null) {
        objectUrl = URL.createObjectURL(imageBlog);
        final img = HTMLImageElement();
        img.src = objectUrl!;
        img.addEventListener(
          'load',
          (Event event) {
            URL.revokeObjectURL(objectUrl!);
            completer(img);
          }.toJS,
        );
        img.addEventListener('error', onError.toJS);
      }
    },
  );
}

/// {@category IO}
/// Encodes a specific frame from an [Images] list into a base64 Data URL string (PNG format).
///
/// This function waits for the image data to be loaded if necessary before proceeding
/// with the encoding.
///
/// - [images]: The [Images] list containing the image frames. This list should
///   not be empty and the specified [frame] index must be valid.
/// - [frame]: The index of the image frame within the [images] list to encode.
///   Defaults to 0 (the first frame).
///
/// Returns a [Future] that completes with a `String?` representing the
/// base64 encoded PNG Data URL. Returns `null` if the 2D rendering context
/// cannot be obtained, or if any other error occurs during encoding.
Future<String?> encodeImageToDataURL(Images images, [int frame = 0]) async {
  var completer = Completer<String?>();

  Function(Images images, int frame)? encodeImage;

  encodeImage = (Images images, int frame) {
    if (images.isLoading) {
      Timer(Duration(milliseconds: 500), () {
        encodeImage!(images, frame);
      });
      return;
    }

    try {
      var image = images[frame];
      final canvas = HTMLCanvasElement();
      canvas.width = image.width;
      canvas.height = image.height;
      final ctx = canvas.getContext('2d') as CanvasRenderingContext2D?;

      if (ctx == null) {
        warn("Could not retrieve 2D Context");
        completer.complete(null);
        return;
      }

      final imageData = ctx.createImageData(image.width.toJS, image.height);
      for (int y = 0; y < canvas.height; ++y) {
        for (int x = 0; x < canvas.width; ++x) {
          var offsetX = image.sourceRect.x;
          var offsetY = image.sourceRect.y;

          var srcIdx = ((y * canvas.width) + x) * 4;
          var dstIdx = (((offsetY + y) * image.texture.width) + (x + offsetX)) * 4;

          imageData.data.toDart[srcIdx++] = image.texture.pixelData[dstIdx++];
          imageData.data.toDart[srcIdx++] = image.texture.pixelData[dstIdx++];
          imageData.data.toDart[srcIdx++] = image.texture.pixelData[dstIdx++];
          imageData.data.toDart[srcIdx++] = image.texture.pixelData[dstIdx++];
        }
      }
      ctx.putImageData(imageData, 0, 0);

      completer.complete(canvas.toDataURL('image/png'));
    } catch (e) {
      error("[BullseyeApp] Error encoding image to data URL: $e");
      completer.complete(null);
    }
  };

  encodeImage(images, frame);

  return completer.future;
}
