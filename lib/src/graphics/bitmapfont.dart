import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart' show CanvasRenderingContext2D, TextMetrics, HTMLCanvasElement;
import 'dart:js_interop';

/// @nodoc
class Glyph {
  Image? image;
  final double advance;

  Glyph({required this.image, required this.advance});
}

/// {@category Graphics}
/// A font rendered from a pre-generated texture atlas.
///
/// `BitmapFont` allows for efficient text rendering
/// It handles the generation if this atlas from a
/// TrueType/OpenType font file.
///
/// Use [ResourceManager.loadFont] to create and load `BitmapFont` instances.
class BitmapFont {
  static const int _cellPadding = 1;

  /// A string containing the default set of printable ASCII characters (codes 32-126).
  ///
  /// This set is commonly used for basic text rendering.
  static const String defaultAscii = r""" !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~""";

  /// A string containing an extended set of ASCII characters.
  ///
  /// This includes the [defaultAscii] characters plus additional characters
  /// from the Latin-1 Supplement block (codes 160-255).
  /// Generated with: `"${String.fromCharCodes(Iterable.generate(127-32, (r) => r + 32))}${String.fromCharCodes(Iterable.generate(256-160, (r) => r + 160))}"`
  static const String extendedAscii = defaultAscii + r""" ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ""";

  final GL2 _gl;

  final List<Texture> _textures = [];

  /// @nodoc
  final Map<int, Glyph> glyphs = {};

/// The effective vertical spacing between lines of text, in pixels.
  ///
  /// This is calculated as `leadingBase * leadingMod`.
  double get leading => leadingBase * leadingMod;

  /// The base vertical spacing (line height) for the font, in pixels.
  ///
  /// This value is determined from the font's metrics during atlas generation
  /// (specifically, `fontBoundingBoxAscent + fontBoundingBoxDescent` of a space character).
  var leadingBase = 0.0;

  /// A multiplier applied to [leadingBase] to adjust the final line spacing.
  ///
  /// Defaults to `1.0`. Values greater than `1.0` increase spacing,
  /// while values less than `1.0` decrease it.
  var leadingMod = 1.0;

  /// A multiplier applied to the advance width of each character to adjust
  /// horizontal spacing (tracking) between characters.
  ///
  /// Defaults to `1.0`. Values greater than `1.0` increase spacing,
  /// while values less than `1.0` decrease it.
  var tracking = 1.0;

  /// Creates a new [BitmapFont] instance.
  ///
  /// Typically, you would use [ResourceManager.loadFont] instead of
  /// constructing this directly.
  ///
  /// - [_gl]: The WebGL2 rendering context.
  BitmapFont(this._gl);

  /// @nodoc
  generateAtlas(String fontName, double size, bool antiAlias, String charSet) async {
    if (glyphs.isNotEmpty) {
      throw Exception("BitmapFont Atlas already generated!");
    }

    final canvas = HTMLCanvasElement();
    final ctx = canvas.getContext('2d') as CanvasRenderingContext2D?;
    if (ctx == null) {
      throw Exception("Could not create 2D Canvas for font atlas generation");
    }

    int maxWidth = 0;
    int maxHeight = 0;

    ctx.font = '${size}px $fontName';
    ctx.textBaseline = 'alphabetic';

    final glyphMetrics = <int, TextMetrics>{};
    final spaceMetrics = ctx.measureText(" ");

    leadingBase = spaceMetrics.fontBoundingBoxAscent + spaceMetrics.fontBoundingBoxDescent;

    for (final char in charSet.runes) {
      final charStr = String.fromCharCode(char);
      final metrics = ctx.measureText(charStr);
      if (metrics.width > 0) {
        glyphMetrics[char] = metrics;

        //NOTE: I'm adding a few pixels to the width/height, because some fonts get cut on the edge. Could be that
        // there is an error in my calculations, but could also be the case that the font metrics are not
        // 100% accurate. Need to investigate furhter!
        final charWidth =  2 + metrics.actualBoundingBoxLeft.abs().ceil() + metrics.actualBoundingBoxRight.abs().ceil();
        final charHeight = 2 + metrics.fontBoundingBoxAscent.abs().ceil() + metrics.fontBoundingBoxDescent.abs().ceil();

        if (charWidth > maxWidth) maxWidth = charWidth;
        if (charHeight > maxHeight) maxHeight = charHeight;
      }
    }

    assert(maxHeight > 0);

    final pivotY = 1.0 - (spaceMetrics.fontBoundingBoxAscent / maxHeight.toDouble());
    final cellWidth = maxWidth + _cellPadding * 2;
    final cellHeight = maxHeight + _cellPadding * 2;

    final maxAtlasSize = (_gl.getParameter(GL.MAX_TEXTURE_SIZE) as JSNumber).toDartInt;

    assert(cellWidth > 0 && cellHeight > 0);
    assert(cellWidth < maxAtlasSize && cellHeight < maxAtlasSize);

    final allCharCodes = glyphMetrics.keys.toList();
    final maxCols = maxAtlasSize ~/ cellWidth;
    final maxRows = maxAtlasSize ~/ cellHeight;

    assert(maxCols > 0 && maxRows > 0);

    int charIdx = 0;

    while (charIdx < allCharCodes.length) {
      int maxChars = min(allCharCodes.length - charIdx, maxCols * maxRows);
      if (maxChars <= 0) break;

      // Trying to keep textures sizes to a minimum (in general this is often for tha last atlas)
      int cols = min(sqrt(maxChars * cellWidth.toDouble() / cellHeight.toDouble()).ceil(), maxCols);
      int rows = min((maxChars / cols).ceil(), maxRows);

      canvas.width = min(nextPowerOfTwo(cols * cellWidth), maxAtlasSize);
      canvas.height = min(nextPowerOfTwo(rows * cellHeight), maxAtlasSize);

      assert(cellWidth < canvas.width && cellHeight < canvas.height);

      cols = canvas.width ~/ cellWidth;
      rows = canvas.height ~/ cellHeight;

      maxChars = min(maxChars, cols * rows);

      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.font = '${size}px $fontName';
      ctx.fillStyle = '#ffffffff'.toJS;
      ctx.imageSmoothingEnabled = antiAlias;
      ctx.imageSmoothingQuality = 'high';
      ctx.textBaseline = 'alphabetic';

      final glyphRect = <int, Rect<int>>{};
      int colIdx = 0;
      int rowIdx = 0;

      for (int i = 0; i < maxChars; i++) {
        final charCode = allCharCodes[charIdx];
        final charStr = String.fromCharCode(charCode);
        final metrics = glyphMetrics[charCode]!;

        final x = colIdx * cellWidth;
        final y = rowIdx * cellHeight;
        final advance = metrics.width;

        final drawX = (x + _cellPadding + (metrics.actualBoundingBoxLeft).abs()).floor();
        final drawY = (y + _cellPadding + (metrics.fontBoundingBoxAscent)).floor();

        ctx.fillText(charStr, drawX.toDouble(), drawY.toDouble());

        glyphs[charCode] = Glyph(image: null, advance: advance);
        glyphRect[charCode] = Rect(x + _cellPadding, y + _cellPadding, maxWidth, maxHeight);

        charIdx++;
        colIdx++;
        if (colIdx >= cols) {
          colIdx = 0;
          rowIdx++;
        }
      }

      final imageData = ctx.getImageData(0, 0, canvas.width, canvas.height).data.toDart;
      final texture = Texture.create(
          gl: _gl,
          pixelData: imageData.buffer.asUint8List(),
          width: canvas.width,
          height: canvas.height,
          textureFlags: (antiAlias ? TextureFlags.filter : 0) | TextureFlags.mipmap | TextureFlags.clampST);
      _textures.add(texture);

      for (final entry in glyphRect.entries) {
        glyphs[entry.key]!.image = Image(
          texture: texture,
          sourceRect: entry.value,
          pivotX: 0.0,
          pivotY: pivotY,
        );
      }
    }
  }

  /// Releases all resources used by this [BitmapFont].
  ///
  /// This includes disposing of all associated [Texture] atlases and clearing
  /// the [glyphs] map. Call this when the font is no longer needed to free
  /// GPU memory.
  dispose() {
    for (final glyph in glyphs.values) {
      glyph.image?.dispose();
    }
    glyphs.clear();

    for (final texture in _textures) {
      texture.dispose();
    }
    _textures.clear();
  }
}
