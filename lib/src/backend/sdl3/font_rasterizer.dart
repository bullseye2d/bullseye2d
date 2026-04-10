import 'dart:ffi';
import 'dart:math' show sqrt;
import 'dart:typed_data';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/bullseye2d.dart' show min, nextPowerOfTwo;
import 'package:ffi/ffi.dart';
import 'package:sdl3/sdl3.dart';

/// SDL3_ttf based implementation of [FontRasterizerBackend].
class Sdl3FontRasterizerBackend implements FontRasterizerBackend {
  static const int _cellPadding = 1;
  int maxTextureSize;

  Sdl3FontRasterizerBackend({this.maxTextureSize = 4096});

  @override
  Future<RasterizedFont> rasterize(Uint8List ttfBytes, double size, String characters, bool antiAlias) async {
    // Load font from memory via IOStream
    final nativeBytes = calloc<Uint8>(ttfBytes.length);
    nativeBytes.asTypedList(ttfBytes.length).setAll(0, ttfBytes);
    final io = sdlIoFromConstMem(nativeBytes.cast(), ttfBytes.length);

    if (io == nullptr) {
      calloc.free(nativeBytes);
      return _emptyResult();
    }

    // closeio=false so we can free nativeBytes ourselves after
    final font = ttfOpenFontIo(io, false, size);
    if (font == nullptr) {
      calloc.free(nativeBytes);
      return _emptyResult();
    }

    final fontHeight = ttfGetFontHeight(font);
    final fontAscent = ttfGetFontAscent(font);
    final lineHeight = fontHeight.toDouble();

    // White foreground for glyph rendering
    final fg = calloc<SdlColor>();
    fg.ref
      ..r = 255
      ..g = 255
      ..b = 255
      ..a = 255;

    // Measure all glyphs
    final minxPtr = calloc<Int32>();
    final maxxPtr = calloc<Int32>();
    final minyPtr = calloc<Int32>();
    final maxyPtr = calloc<Int32>();
    final advancePtr = calloc<Int32>();

    int maxGlyphWidth = 0;
    int maxGlyphHeight = 0;
    final glyphInfos = <int, _GlyphInfo>{};

    for (final char in characters.runes) {
      final ok = ttfGetGlyphMetrics(font, char, minxPtr, maxxPtr, minyPtr, maxyPtr, advancePtr);
      if (!ok) continue;

      final glyphW = maxxPtr.value - minxPtr.value;
      final glyphH = maxyPtr.value - minyPtr.value;
      if (glyphW <= 0 && glyphH <= 0 && advancePtr.value <= 0) continue;

      final effectiveW = glyphW > 0 ? glyphW : advancePtr.value;
      final effectiveH = glyphH > 0 ? glyphH : fontHeight;

      if (effectiveW > maxGlyphWidth) maxGlyphWidth = effectiveW;
      if (effectiveH > maxGlyphHeight) maxGlyphHeight = effectiveH;

      glyphInfos[char] = _GlyphInfo(
        minX: minxPtr.value,
        maxX: maxxPtr.value,
        minY: minyPtr.value,
        maxY: maxyPtr.value,
        advance: advancePtr.value,
      );
    }

    calloc.free(minxPtr);
    calloc.free(maxxPtr);
    calloc.free(minyPtr);
    calloc.free(maxyPtr);
    calloc.free(advancePtr);

    if (maxGlyphHeight == 0) {
      calloc.free(fg);
      ttfCloseFont(font);
      calloc.free(nativeBytes);
      return _emptyResult();
    }

    // Calculate atlas layout — use fontHeight as cell height to match
    // the surface height returned by ttfRenderTextBlended
    final cellWidth = maxGlyphWidth + _cellPadding * 2;
    final cellHeight = fontHeight + _cellPadding * 2;

    final allCharCodes = glyphInfos.keys.toList();
    final maxCols = maxTextureSize ~/ cellWidth;
    final maxRows = maxTextureSize ~/ cellHeight;

    int maxChars = min(allCharCodes.length, maxCols * maxRows);
    int cols = min(sqrt(maxChars * cellWidth.toDouble() / cellHeight.toDouble()).ceil(), maxCols);
    int rows = min((maxChars / cols).ceil(), maxRows);

    int atlasWidth = min(nextPowerOfTwo(cols * cellWidth), maxTextureSize);
    int atlasHeight = min(nextPowerOfTwo(rows * cellHeight), maxTextureSize);

    cols = atlasWidth ~/ cellWidth;
    rows = atlasHeight ~/ cellHeight;
    maxChars = min(maxChars, cols * rows);

    // Create atlas pixel buffer (RGBA, initialized to transparent)
    final atlasPixels = Uint8List(atlasWidth * atlasHeight * 4);

    // Render each glyph and blit into atlas
    final glyphs = <int, GlyphMetrics>{};
    int colIdx = 0;
    int rowIdx = 0;

    for (int i = 0; i < maxChars && i < allCharCodes.length; i++) {
      final charCode = allCharCodes[i];
      final info = glyphInfos[charCode]!;

      // Render single character as text string
      final charStr = String.fromCharCode(charCode);
      final surface = ttfRenderTextBlended(font, charStr, 0, fg.ref);

      final cellX = colIdx * cellWidth;
      final cellY = rowIdx * cellHeight;

      if (surface != nullptr) {
        // Convert surface to ABGR8888 (RGBA byte order on little-endian)
        final converted = sdlConvertSurface(surface, SDL_PIXELFORMAT_ABGR8888);
        sdlDestroySurface(surface);

        if (converted != nullptr) {
          final sw = converted.ref.w;
          final sh = converted.ref.h;
          final pitch = converted.ref.pitch;
          final srcPixels = converted.ref.pixels.cast<Uint8>();

          // Blit glyph pixels into atlas at the cell position.
          // ttfRenderTextBlended returns a surface with height = font height
          // (ascent + descent) and the glyph already baseline-aligned within it.
          // Just blit at the cell origin — no manual Y offset needed.
          final destX = cellX + _cellPadding;
          final destY = cellY + _cellPadding;

          for (int y = 0; y < sh && (destY + y) < atlasHeight; y++) {
            if (destY + y < 0) continue;
            for (int x = 0; x < sw && (destX + x) < atlasWidth; x++) {
              final srcOffset = y * pitch + x * 4;
              final dstOffset = ((destY + y) * atlasWidth + (destX + x)) * 4;
              atlasPixels[dstOffset + 0] = srcPixels[srcOffset + 0]; // R
              atlasPixels[dstOffset + 1] = srcPixels[srcOffset + 1]; // G
              atlasPixels[dstOffset + 2] = srcPixels[srcOffset + 2]; // B
              atlasPixels[dstOffset + 3] = srcPixels[srcOffset + 3]; // A
            }
          }

          sdlDestroySurface(converted);
        }
      }

      final u1 = (cellX + _cellPadding) / atlasWidth;
      final v1 = (cellY + _cellPadding) / atlasHeight;
      final u2 = (cellX + _cellPadding + maxGlyphWidth) / atlasWidth;
      final v2 = (cellY + _cellPadding + fontHeight) / atlasHeight;

      glyphs[charCode] = GlyphMetrics(
        u1: u1,
        v1: v1,
        u2: u2,
        v2: v2,
        width: maxGlyphWidth.toDouble(),
        height: fontHeight.toDouble(),
        xOffset: 0,
        yOffset: 0,
        advance: info.advance.toDouble(),
      );

      colIdx++;
      if (colIdx >= cols) {
        colIdx = 0;
        rowIdx++;
      }
    }

    calloc.free(fg);
    ttfCloseFont(font);
    calloc.free(nativeBytes);

    return RasterizedFont(
      atlasPixels: atlasPixels,
      atlasWidth: atlasWidth,
      atlasHeight: atlasHeight,
      glyphs: glyphs,
      lineHeight: lineHeight,
      ascent: fontAscent.toDouble(),
    );
  }

  static RasterizedFont _emptyResult() {
    return RasterizedFont(
      atlasPixels: Uint8List(0),
      atlasWidth: 0,
      atlasHeight: 0,
      glyphs: {},
      lineHeight: 0,
      ascent: 0,
    );
  }
}

class _GlyphInfo {
  final int minX, maxX, minY, maxY, advance;
  _GlyphInfo({required this.minX, required this.maxX, required this.minY, required this.maxY, required this.advance});
}
