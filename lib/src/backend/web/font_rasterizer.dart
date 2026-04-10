import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/bullseye2d.dart' show min, nextPowerOfTwo;
import 'package:web/web.dart' show CanvasRenderingContext2D, HTMLCanvasElement, FontFace, document;
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:math' show sqrt;

class WebFontRasterizerBackend implements FontRasterizerBackend {
  static const int _cellPadding = 1;

  /// Maximum texture size. On web, this depends on the GL context.
  /// We use a reasonable default; callers can override.
  int maxTextureSize;

  WebFontRasterizerBackend({this.maxTextureSize = 4096});

  @override
  Future<RasterizedFont> rasterize(Uint8List ttfBytes, double size, String characters, bool antiAlias) async {
    // Register the font via FontFace API
    final fontName = 'bullseye_font_${ttfBytes.hashCode}';
    final FontFace fontFace = FontFace(fontName, ttfBytes.buffer.toJS);
    try {
      document.fonts.add(fontFace);
    } catch (e) {
      // Firefox may throw here but the font still works
    }

    // Wait for font to be loaded
    await fontFace.load().toDart;

    final canvas = HTMLCanvasElement();
    final ctx = canvas.getContext('2d') as CanvasRenderingContext2D;

    ctx.font = '${size}px $fontName';
    ctx.textBaseline = 'alphabetic';

    // Measure all glyphs
    final spaceMetrics = ctx.measureText(" ");
    final lineHeight = spaceMetrics.fontBoundingBoxAscent + spaceMetrics.fontBoundingBoxDescent;

    int maxWidth = 0;
    int maxHeight = 0;
    final glyphMetricsMap = <int, _WebGlyphInfo>{};

    for (final char in characters.runes) {
      final charStr = String.fromCharCode(char);
      final metrics = ctx.measureText(charStr);
      if (metrics.width > 0) {
        final charWidth = 2 + metrics.actualBoundingBoxLeft.abs().ceil() + metrics.actualBoundingBoxRight.abs().ceil();
        final charHeight = 2 + metrics.fontBoundingBoxAscent.abs().ceil() + metrics.fontBoundingBoxDescent.abs().ceil();
        if (charWidth > maxWidth) maxWidth = charWidth;
        if (charHeight > maxHeight) maxHeight = charHeight;
        glyphMetricsMap[char] = _WebGlyphInfo(
          advance: metrics.width,
          boundingBoxLeft: metrics.actualBoundingBoxLeft.abs(),
          fontBoundingBoxAscent: metrics.fontBoundingBoxAscent,
        );
      }
    }

    if (maxHeight == 0) {
      return RasterizedFont(
        atlasPixels: Uint8List(0),
        atlasWidth: 0,
        atlasHeight: 0,
        glyphs: {},
        lineHeight: lineHeight,
        ascent: spaceMetrics.fontBoundingBoxAscent,
      );
    }

    final cellWidth = maxWidth + _cellPadding * 2;
    final cellHeight = maxHeight + _cellPadding * 2;

    final allCharCodes = glyphMetricsMap.keys.toList();
    final maxCols = maxTextureSize ~/ cellWidth;
    final maxRows = maxTextureSize ~/ cellHeight;

    // Pack into atlas
    int maxChars = min(allCharCodes.length, maxCols * maxRows);
    int cols = min(sqrt(maxChars * cellWidth.toDouble() / cellHeight.toDouble()).ceil(), maxCols);
    int rows = min((maxChars / cols).ceil(), maxRows);

    canvas.width = min(nextPowerOfTwo(cols * cellWidth), maxTextureSize);
    canvas.height = min(nextPowerOfTwo(rows * cellHeight), maxTextureSize);

    cols = canvas.width ~/ cellWidth;
    rows = canvas.height ~/ cellHeight;
    maxChars = min(maxChars, cols * rows);

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.font = '${size}px $fontName';
    ctx.fillStyle = '#ffffffff'.toJS;
    ctx.imageSmoothingEnabled = antiAlias;
    ctx.imageSmoothingQuality = 'high';
    ctx.textBaseline = 'alphabetic';

    final glyphs = <int, GlyphMetrics>{};
    int colIdx = 0;
    int rowIdx = 0;

    for (int i = 0; i < maxChars && i < allCharCodes.length; i++) {
      final charCode = allCharCodes[i];
      final charStr = String.fromCharCode(charCode);
      final info = glyphMetricsMap[charCode]!;

      final x = colIdx * cellWidth;
      final y = rowIdx * cellHeight;

      final drawX = (x + _cellPadding + info.boundingBoxLeft).floor();
      final drawY = (y + _cellPadding + info.fontBoundingBoxAscent).floor();

      ctx.fillText(charStr, drawX.toDouble(), drawY.toDouble());

      final u1 = (x + _cellPadding) / canvas.width;
      final v1 = (y + _cellPadding) / canvas.height;
      final u2 = (x + _cellPadding + maxWidth) / canvas.width;
      final v2 = (y + _cellPadding + maxHeight) / canvas.height;

      glyphs[charCode] = GlyphMetrics(
        u1: u1,
        v1: v1,
        u2: u2,
        v2: v2,
        width: maxWidth.toDouble(),
        height: maxHeight.toDouble(),
        xOffset: 0,
        yOffset: 0,
        advance: info.advance,
      );

      colIdx++;
      if (colIdx >= cols) {
        colIdx = 0;
        rowIdx++;
      }
    }

    final imageData = ctx.getImageData(0, 0, canvas.width, canvas.height).data.toDart;
    final pixels = imageData.buffer.asUint8List();

    return RasterizedFont(
      atlasPixels: pixels,
      atlasWidth: canvas.width,
      atlasHeight: canvas.height,
      glyphs: glyphs,
      lineHeight: lineHeight,
      ascent: spaceMetrics.fontBoundingBoxAscent,
    );
  }
}

class _WebGlyphInfo {
  final double advance;
  final double boundingBoxLeft;
  final double fontBoundingBoxAscent;

  _WebGlyphInfo({required this.advance, required this.boundingBoxLeft, required this.fontBoundingBoxAscent});
}
