/// {@category Utility}
/// Represents a rectangle defined by a top-left corner [left], [top]
/// and a [width] and [height].
class Rect<T extends num> {
  /// The x-coordinate of the left edge of the rectangle.
  T left;

  /// The y-coordinate of the top edge of the rectangle.
  T top;

  /// The width of the rectangle.
  T width;

  /// The height of the rectangle.
  T height;

  Rect._(this.left, this.top, this.width, this.height);

  /// Creates a new [Rect].
  ///
  /// If [left], [top], [width], or [height] are not provided, they default to `0`
  /// of type [T].
  factory Rect([T? left, T? top, T? width, T? height]) {
    var zero = 0 as T;
    return Rect<T>._(left ?? zero, top ?? zero, width ?? zero, height ?? zero);
  }

  /// The x-coordinate of the left edge of the rectangle. Alias for [left].
  T get x => left;

  /// The y-coordinate of the top edge of the rectangle. Alias for [top].
  T get y => top;

  /// Sets the x-coordinate of the left edge of the rectangle. Alias for setting [left].
  set x(x) => left = x;

  /// Sets the y-coordinate of the top edge of the rectangle. Alias for setting [top].
  set y(y) => top = y;

  /// The x-coordinate of the right edge of the rectangle.
  /// Calculated as `left + width`.
  T get right => (left + width) as T;

  /// The y-coordinate of the bottom edge of the rectangle.
  /// Calculated as `top + height`.
  T get bottom => (top + height) as T;

  /// The x-coordinate of the center of the rectangle.
  /// Calculated as `left + width / 2`.
  double get centerX => left + width / 2;

  /// The y-coordinate of the center of the rectangle.
  /// Calculated as `top + height / 2`.
  double get centerY => top + height / 2;

  /// Sets the x-coordinate of the right edge of the rectangle.
  set right(num newRight) => left = (newRight - width) as T;

  /// Sets the y-coordinate of the bottom edge of the rectangle.
  set bottom(num newBottom) => top = (newBottom - height) as T;

  /// Sets the x-coordinate of the center of the rectangle.
  set centerX(double newCenterX) => left = (newCenterX - width / 2) as T;

  /// Sets the y-coordinate of the center of the rectangle.
  set centerY(double newCenterY) => top = (newCenterY - height / 2) as T;

  /// Checks if the rectangle contains the point ([px], [py]).
  ///
  /// - [px]: The x-coordinate of the point.
  /// - [py]: The y-coordinate of the point.
  ///
  /// Returns `true` if the point is inside the rectangle, `false` otherwise.
  bool containsPoint(num px, num py) {
    return px >= left && px < right && py >= top && py < bottom;
  }

  /// Checks if this rectangle intersects with another rectangle.
  ///
  /// - [other]: The other rectangle to check intersection with.
  ///
  /// Returns `true` if the rectangles overlap, `false` otherwise.
  bool intersects(Rect<T> other) {
    return left < other.right &&
           right > other.left &&
           top < other.bottom &&
           bottom > other.top;
  }

  /// Sets the properties of this rectangle.
  ///
  /// - [left]: The new x-coordinate of the left edge.
  /// - [top]: The new y-coordinate of the top edge.
  /// - [width]: The new width.
  /// - [height]: The new height.
  set(T left, T top, T width, T height) {
    this
      ..left = left
      ..top = top
      ..width = width
      ..height = height;
  }

  @override
  String toString() {
    return 'Rect<$T>(left: $left, top: $top, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;

    final otherRect = other as Rect<T>;
    return left == otherRect.left && top == otherRect.top && width == otherRect.width && height == otherRect.height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);
}
