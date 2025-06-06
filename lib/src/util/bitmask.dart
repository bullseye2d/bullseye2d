
/// {@category Utility}
/// Provides extension methods for bitmask operations on integers.
extension BitmaskExtension on int {
  /// Checks if the integer has a specific [flag] bit set.
  bool has(int flag) {
    return (this & flag) != 0;
  }

  /// Checks if the integer has all specified [flags] bits set.
  bool hasAll(int flags) {
    return (this & flags) == flags;
  }
}

