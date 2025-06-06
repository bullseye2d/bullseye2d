/// {@category Utility}
/// Extension on `List<num>` to provide utility methods for calculations.
extension SumListExtension on List<num> {
  /// Calculates the sum of all numbers in the list.
  ///
  /// Returns 0 if the list is empty.
  num sum() {
      return fold(0, (sum, element) => sum + element);
  }

  /// Calculates the average (mean) of all numbers in the list.
  ///
  /// Returns `0` if the list is empty.
  double average() {
    return (length > 0) ? sum() / length.toDouble() : 0.0;
  }
}

