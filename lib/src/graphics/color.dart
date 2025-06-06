import 'package:vector_math/vector_math_64.dart';

/// {@category Graphics}
/// Represents a color.
typedef Color = Vector4;

/// {@category Graphics}
/// A list of [Color] objects.
///
/// This can be used, for example, to define gradient colors for drawing primitives.
typedef ColorList = List<Color>;

/// {@category Graphics}
/// Provides utility methods for [Color] (Vector4) objects.
extension ColorExtension on Color {

  /// Converts this [Color] to a 32-bit unsigned integer representation (ABGR).
  ///
  /// For example, opaque red (1.0, 0.0, 0.0, 1.0) would become `0xFFFF0000`.
  /// Transparent black (0.0, 0.0, 0.0, 0.0) would become `0x00000000`.
  ///
  /// Returns:
  ///   An integer representing the color in ABGR format.
  int toUint8() {
    return (((a.clamp(0.0, 1.0) * 255).round().toInt() & 0xFF) << 24 | ((b.clamp(0.0, 1.0) * 255).round().toInt() & 0xFF) << 16 | ((g.clamp(0.0, 1.0) * 255).round().toInt() & 0xFF) << 8 | ((r.clamp(0.0, 1.0) * 255).round().toInt() & 0xFF) << 0);
  }
}

Color colorFromInt(int vol) {
  return Color(1.0, 1.0, 1.0, 1.0);
}

/// @nodoc
int getColorFromList(ColorList? colors, int idx, int defaultColor) {
  if (colors == null || colors.isEmpty) {
    return defaultColor;
  }
  return colors[idx % colors.length].toUint8();
}
