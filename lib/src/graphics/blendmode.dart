import 'package:bullseye2d/bullseye2d.dart';

/// {@category Graphics}
/// Defines how source and destination colors are blended together when rendering.
///
/// These modes are typically used to achieve various visual effects like transparency,
/// additive lighting, or color modulation.
enum BlendMode {
  /// No blending is performed. Source pixels overwrite destination pixels.
  opaque,

  /// Standard alpha blending, suitable for textures with transparency where
  /// the texture color values have been pre-multiplied by their alpha.
  alpha,

  /// Additive blending. The source color is added to the destination color.
  /// This mode is often used for effects like fire, explosions, or glows,
  /// as it tends to brighten the image.
  additive,

  /// Multiply blending that respects source alpha.
  /// Darkens the destination by multiplying it with the source color. The source's
  /// alpha channel controls the strength of this effect: opaque areas of the
  /// source fully apply the multiplication, while transparent areas leave the
  /// destination unchanged.
  multiply,

  /// A "harder" multiply blending. The resulting color is the product of the
  /// (pre-multiplied) source color and the destination color.
  /// This mode strongly darkens the image; if the source is transparent (alpha is 0),
  /// the result tends towards black.
  multiply2,

  /// Screen blending. The source and destination colors are inverted, multiplied,
  /// and then the result is inverted again. This mode is the opposite of multiply
  /// and is often used for brightening effects, like glows or lens flares.
  screen;

  /// @nodoc
  apply(GL2 gl) {
    switch (this) {
      case BlendMode.opaque:
        gl.disable(GL.BLEND);
        break;

      case BlendMode.alpha:
        gl.enable(GL.BLEND);
        gl.blendFunc(GL.ONE, GL.ONE_MINUS_SRC_ALPHA);
        break;

      case BlendMode.additive:
        gl.enable(GL.BLEND);
        gl.blendFunc(GL.ONE, GL.ONE);
        break;

      case BlendMode.multiply:
        gl.enable(GL.BLEND);
        gl.blendFunc(GL.DST_COLOR, GL.ONE_MINUS_SRC_ALPHA);
        break;

      case BlendMode.multiply2:
        gl.enable(GL.BLEND);
        gl.blendFunc(GL.DST_COLOR, GL.ZERO);
        break;

      case BlendMode.screen:
        gl.enable(GL.BLEND);
        gl.blendFunc(GL.ONE, GL.ONE_MINUS_SRC_COLOR);
        break;
    }
  }
}
