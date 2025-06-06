import 'dart:math';

/// {@category Utility}
/// Calculates the next power of two greater than or equal to the given integer [v].
///
/// [v] must be a positive integer.
int nextPowerOfTwo(int v) {
  assert(v > 0, "nextPowerOfTwo: no negative value allowed");
  v--;
  v |= v >> 1;
  v |= v >> 2;
  v |= v >> 4;
  v |= v >> 8;
  v |= v >> 16;
  return (++v);
}

/// {@category Utility}
/// Calculates the angle in degrees for the point (b, a) using `atan2(a, b)`.
///
/// - [a]: The y-coordinate.
/// - [b]: The x-coordinate.
///
/// Returns the angle in degrees.
double atan2Degree(num a, num b) {
  return atan2(a, b) * (180 / pi);
}

/// {@category Utility}
/// Calculates the sine of an angle given in [degree]s.
double sinDegree(num degree) {
  return sin(degree * (pi / 180));
}

/// {@category Utility}
/// Calculates the cosine of an angle given in [degree]s.
double cosDegree(num degree) {
    return cos(degree * (pi / 180));
}

/// {@category Utility}
/// Calculates the tangent of an angle given in [degree]s.
double tanDegree(num degree) {
    return tan(degree * (pi / 180));
}

