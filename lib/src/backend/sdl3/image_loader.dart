import 'dart:ffi';
import 'dart:typed_data';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:ffi/ffi.dart';
import 'package:sdl3/sdl3.dart';

/// SDL3_image based implementation of [ImageLoaderBackend].
class Sdl3ImageLoaderBackend implements ImageLoaderBackend {
  @override
  Future<DecodedImage> decode(Uint8List bytes) async {
    final nativeBytes = calloc<Uint8>(bytes.length);
    nativeBytes.asTypedList(bytes.length).setAll(0, bytes);

    final io = sdlIoFromConstMem(nativeBytes.cast(), bytes.length);
    if (io == nullptr) {
      calloc.free(nativeBytes);
      return DecodedImage(pixels: Uint8List(0), width: 0, height: 0);
    }

    // closeio=true so the IOStream is freed after loading
    final surface = imgLoadIo(io, true);
    calloc.free(nativeBytes);

    if (surface == nullptr) {
      return DecodedImage(pixels: Uint8List(0), width: 0, height: 0);
    }

    return _extractPixels(surface);
  }

  @override
  Future<DecodedImage> decodeFromFile(String path) async {
    final surface = imgLoad(path);
    if (surface == nullptr) {
      return DecodedImage(pixels: Uint8List(0), width: 0, height: 0);
    }

    return _extractPixels(surface);
  }

  /// Convert an SDL_Surface to RGBA pixel data and free the surface.
  DecodedImage _extractPixels(Pointer<SdlSurface> surface) {
    // Convert to ABGR8888 format (which gives RGBA byte order on little-endian)
    final converted = sdlConvertSurface(surface, SDL_PIXELFORMAT_ABGR8888);
    sdlDestroySurface(surface);

    if (converted == nullptr) {
      return DecodedImage(pixels: Uint8List(0), width: 0, height: 0);
    }

    final w = converted.ref.w;
    final h = converted.ref.h;
    final pitch = converted.ref.pitch;
    final pixelsPtr = converted.ref.pixels.cast<Uint8>();

    // Copy pixel data — pitch may include padding, so copy row by row
    final rowBytes = w * 4;
    final pixels = Uint8List(w * h * 4);
    for (int y = 0; y < h; y++) {
      final srcRow = pixelsPtr + (y * pitch);
      pixels.setRange(y * rowBytes, y * rowBytes + rowBytes, srcRow.asTypedList(rowBytes));
    }

    sdlDestroySurface(converted);

    return DecodedImage(pixels: pixels, width: w, height: h);
  }
}
