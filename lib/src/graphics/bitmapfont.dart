import 'package:bullseye2d/bullseye2d.dart';
import 'package:bullseye2d/src/backend/backend.dart' show RendererBackend, FontRasterizerBackend, RasterizedFont;

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
  /// A string containing the default set of printable ASCII characters (codes 32-126).
  ///
  /// This set is commonly used for basic text rendering.
  static const String defaultAscii =
      r""" !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~""";

  /// A string containing an extended set of ASCII characters.
  ///
  /// This includes the [defaultAscii] characters plus additional characters
  /// from the Latin-1 Supplement block (codes 160-255).
  /// Generated with: `"${String.fromCharCodes(Iterable.generate(127-32, (r) => r + 32))}${String.fromCharCodes(Iterable.generate(256-160, (r) => r + 160))}"`
  static const String extendedAscii =
      defaultAscii +
      r""" ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ""";

  final RendererBackend _renderer;

  final List<Texture> _textures = [];

  /// @nodoc
  final Map<int, Glyph> glyphs = {};

  /// The effective vertical spacing between lines of text, in pixels.
  ///
  /// This is calculated as `leadingBase * leadingMod`.
  double get leading => leadingBase * leadingMod;

  /// The base vertical spacing (line height) for the font, in pixels.
  ///
  /// This value is determined from the font's metrics during atlas generation.
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

  /// @nodoc
  BitmapFont(this._renderer);

  /// @nodoc
  /// Generates the font atlas from a [RasterizedFont] produced by [FontRasterizerBackend].
  generateAtlasFromRasterized(RasterizedFont rasterized, bool antiAlias) {
    if (glyphs.isNotEmpty) {
      throw Exception("BitmapFont Atlas already generated!");
    }

    leadingBase = rasterized.lineHeight;

    if (rasterized.atlasWidth == 0 || rasterized.atlasHeight == 0) return;

    final texture = Texture.create(
      renderer: _renderer,
      pixelData: rasterized.atlasPixels,
      width: rasterized.atlasWidth,
      height: rasterized.atlasHeight,
      textureFlags: (antiAlias ? TextureFlags.filter : 0) | TextureFlags.mipmap | TextureFlags.clampST,
    );
    _textures.add(texture);

    for (final entry in rasterized.glyphs.entries) {
      final metrics = entry.value;
      final rect = Rect<int>(
        (metrics.u1 * rasterized.atlasWidth).round(),
        (metrics.v1 * rasterized.atlasHeight).round(),
        metrics.width.round(),
        metrics.height.round(),
      );
      // pivotY: position baseline correctly within glyph cell.
      // ascent = distance from top of cell to baseline.
      // This matches the original formula: 1.0 - (ascent / cellHeight)
      final pivotY = 1.0 - (metrics.height > 0 ? rasterized.ascent / metrics.height : 0.0);
      glyphs[entry.key] = Glyph(
        image: Image(texture: texture, sourceRect: rect, pivotX: 0.0, pivotY: pivotY),
        advance: metrics.advance,
      );
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
