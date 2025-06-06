import 'package:bullseye2d/bullseye2d.dart';


/// {@category IO}
/// An individual item being tracked by the [Loader].
class LoaderItem {
  /// The source identifier for this loading item, typically a path or URL.
  String source;

  /// The number of bytes currently loaded for this item.
  int loaded = 0;

  /// The total number of bytes expected for this item.
  /// May be 0 if the total size is not yet known.
  int total = 0;

  /// A flag indicating whether the loading of this item has
  /// completed (successfully or with an error).
  bool completedOrFailed = false;

  /// Creates a [LoaderItem] with the given [source].
  LoaderItem(this.source);

  @override
  String toString() {
    return 'LoaderItem($source, $loaded/$total bytes, completedOrFailed: $completedOrFailed)';
  }
}

/// {@category IO}
/// Manages and tracks the progress of multiple asynchronous loading operations.
///
/// The `Loader` keeps a list of [LoaderItem]s and provides overall
/// progress information, such as total bytes loaded, total bytes expected,
/// and an overall percentage. This is useful for implementing loading screens
/// or progress indicators in an application.
///
/// The [App] instance uses this to determine if it should show the loading
/// screen [App.onLoading].
///
/// If you dont want to call the [App.onLoading] method automatically you can
/// disabled it by setting [Loader.isEnabled] to false.
class Loader {
  /// Set this to false if you don't want your [App] instance automatically
  /// calling [App.onLoading] if loading sequence is in progress.
bool isEnabled = true;

  /// Indicates whether the initial sequence of adding items to the loader
  /// is considered finished.
  bool loadingSequenceFinished = true;

  final List<LoaderItem> _items = [];

  /// The total number of bytes loaded across all tracked items.
  int get loaded => _items.fold(0, (sum, item) => sum + item.loaded);

  /// The total number of bytes expected across all tracked items.
  /// This sum only includes items where the total size is known.
  int get total => _items.fold(0, (sum, item) => sum + item.total);

  /// Indicates whether the entire loading process is considered complete.
  bool get done => !isEnabled || (loadingSequenceFinished && allItemsFinished);

  /// Indicates whether all individual [LoaderItem]s have completed loading
  /// (either successfully or with an error).
  bool get allItemsFinished => _items.every((item) => item.completedOrFailed);

  /// The number of items currently being tracked by the loader.
  int get length => _items.length;

  /// Returns the overall loading percentage (on a scale from 0.0 to 1.0).
  ///
  /// This percentage is calulated as the avarage progress of all tracked _items.
  /// This approach ensures:
  ///   1. It handles cases where the total size of _items are not (yet) known.
  ///   2. It prevents percantage rollbacks that can occur when we just
  ///      calulcate it based on loaded / totalBytes when the size only becomes
  ///      known during the loading process (which is the default case, because
  ///      when you, for example, initialize a Http Request you dont know
  ///      the size yet.
  double get percent {
    if (_items.isEmpty) {
      return 1.0;
    }

    if (total == 0) {
      return (allItemsFinished) ? 1.0 : 0.0;
    }

    List<double> itemProgress = [];
    for (var item in _items) {
      if (item.completedOrFailed) {
        itemProgress.add(1.0);
      } else if (item.total == 0) {
        itemProgress.add(0.0);
      } else {
        itemProgress.add((item.loaded / item.total.toDouble()).clamp(0.0, 1.0));
      }
    }

    return itemProgress.average().clamp(0.0, 1.0);
  }

  /// Adds a new item to be tracked by the loader.
  ///
  /// Sets [loadingSequenceFinished] to `false` as a new item is being added.
  ///
  /// - [source]: A string identifying the source of the item (e.g., URL, path).
  /// Returns the created [LoaderItem] instance.
  LoaderItem add(String source) {
    loadingSequenceFinished = false;
    var result = LoaderItem(source);
    _items.add(result);
    return result;
  }

  /// Clears all tracked items from the loader.
  reset() {
    _items.clear();
  }

  @override
  String toString() {
    return 'Loader(isEnabled: $isEnabled, $loaded/$total bytes (${(100.0 * percent).floor()}%), $length _items, allItemsFinished: $allItemsFinished';
  }
}
