import 'package:bullseye2d/bullseye2d.dart';

/// {@category Graphics}
/// A type alias for a list of [Image] objects.
/// Represents a collection of images, often used for animations or sprite sheets.
///
/// This type is used even for single images as it simplifies api calls.
typedef Images = List<Image>;

/// {@category Graphics}
/// Provides extension methods for lists of [Image] objects ([Images]).
extension ImageListExtension on Images {
  /// Indicates if any image in the list is still loading.
  ///
  /// Returns `true` if the list is empty or if any [Image] in the list
  /// has `isLoading` set to `true`. Otherwise, returns `false`.
  bool get isLoading {
    return length == 0 || any((img) => img.isLoading);
  }

  /// Gets a list of unique [Texture] objects used by the images in this list.
  List<Texture> get textures => fold<Set<Texture>>({}, (textures, item) => textures..add(item.texture)).toList();

  /// Gets the [Texture] of the first image in the list.
  Texture get texture => elementAt(0).texture;

  /// Disposes all images in the list.
  void dispose() {
    forEach((image) => image.dispose());
  }

  /// Sets the horizontal pivot point for all images in the list.
  /// Please not that if the image is still loading, it might get overwritten
  /// by the loader again when the image loading is completed.
  ///
  /// The [value] is typically between 0.0 (left edge) and 1.0 (right edge).
  set pivotX(double value) => forEach((image) => image.pivotX = value);

  /// Sets the vertical pivot point for all images in the list.
  /// Please not that if the image is still loading, it might get overwritten
  /// by the loader again when the image loading is completed.
  ///
  /// The [value] is typically between 0.0 (left edge) and 1.0 (right edge).
  set pivotY(double value) => forEach((image) => image.pivotY = value);

  /// Gets the first [Image] in the list.
  Image get first => elementAt(0);
}

/// {@category Graphics}
/// A drawable image, typically a sub-region of a [Texture].
///
/// An `Image` defines a specific rectangular area (`sourceRect`) within a larger
/// [Texture], along with pivot points for rotation and scaling.
class Image {
  /// The [Texture] that this image uses.
  final Texture texture;

  /// The rectangular region within the [texture] of this image.
  final Rect<int> sourceRect;

  /// The horizontal pivot point of the image, normalized (0.0 to 1.0).
  ///
  /// 0.0 is the left edge, 0.5 is the center, 1.0 is the right edge.
  /// Defaults to 0.5.
  double pivotX;

  /// The vertical pivot point of the image, normalized (0.0 to 1.0).
  ///
  /// 0.0 is the top edge, 0.5 is the center, 1.0 is the bottom edge.
  /// Defaults to 0.5.
  double pivotY;

  /// Creates an [Image] instance.
  ///
  /// - [texture]: The source [Texture].
  /// - [sourceRect]: The rectangle defining the portion of the [texture] to use.
  /// - [pivotX]: The normalized horizontal pivot point (defaults to 0.5).
  /// - [pivotY]: The normalized vertical pivot point (defaults to 0.5).
  Image({required this.texture, required this.sourceRect, this.pivotX = 0.5, this.pivotY = 0.5}) {
    texture.retain();
  }

  /// The width of the image, derived from [sourceRect].
  int get width => sourceRect.width;

  /// The height of the image, derived from [sourceRect].
  int get height => sourceRect.height;

  /// The flags associated with the [texture]. See [TextureFlags].
  int get flags => texture.flags;

  /// Indicates if the [texture] is still loading.
  bool get isLoading => texture.isLoading;

  /// Disposes the image [texture].
  dispose() => texture.dispose();

  /// Loads multiple frames from a single [Texture] (sprite sheet).
  ///
  /// This method divides the [texture] into a grid of frames based on the
  /// provided [frameWidth], [frameHeight], and optional [paddingX] and [paddingY].
  /// Each valid frame is created as an [Image] instance.
  ///
  /// - [texture]: The sprite sheet [Texture].
  /// - [frameWidth]: The width of each individual frame.
  /// - [frameHeight]: The height of each individual frame.
  /// - [paddingX]: Horizontal padding between frames (defaults to 0).
  /// - [paddingY]: Vertical padding between frames (defaults to 0).
  /// - [pivotX]: The default horizontal pivot for all loaded frames (defaults to 0.5).
  /// - [pivotY]: The default vertical pivot for all loaded frames (defaults to 0.5).
  ///
  /// If the [texture] is still loading, frame extraction is deferred until the
  /// texture has finished loading.
  ///
  /// Returns an [Images] list (a `List<Image>`) containing all extracted frames.
  static Images loadFrames({
    required Texture texture,
    required int frameWidth,
    required int frameHeight,
    int paddingX = 0,
    int paddingY = 0,
    double pivotX = 0.5,
    double pivotY = 0.5,
  }) {
    final Images images = [];

    grabFrames(Texture texture) {
      final maxFramesX = (texture.width + paddingX) ~/ (frameWidth + paddingX);
      final maxFramesY = (texture.height + paddingY) ~/ (frameHeight + paddingY);

      if (maxFramesX <= 0 || maxFramesY <= 0) {
        return images;
      }

      for (int row = 0; row < maxFramesY; row++) {
        for (int col = 0; col < maxFramesX; col++) {
          final currentX = (col * (frameWidth + paddingX));
          final currentY = (row * (frameHeight + paddingY));

          if (currentX + frameWidth <= texture.width && currentY + frameHeight <= texture.height) {
            final sourceRect = Rect(currentX, currentY, frameWidth, frameHeight);
            images.add(Image(texture: texture, sourceRect: sourceRect, pivotX: pivotX, pivotY: pivotY));
          }
        }
      }
    }

    if (!texture.isLoading) {
      grabFrames(texture);
    } else {
      texture.onLoad((Texture texture) {
        grabFrames(texture);
      });
    }

    return images;
  }
}
