import 'dart:convert';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/util/debug.dart';

/// {@category IO}
/// A utility class for persistent key-value storage.
///
/// Delegates to [StorageBackend] for platform-specific persistence
/// (browser localStorage on web, JSON file on SDL3).
///
/// Values must be JSON-serializable.
class LocalStorage {
  static StorageBackend? _backend;

  /// @nodoc
  /// Sets the storage backend. Called during App initialization.
  static void init(StorageBackend backend) {
    _backend = backend;
  }

  /// Saves a value to storage with the given [key].
  ///
  /// The [value] must be JSON-serializable.
  /// If [value] is `null`, the key is removed from storage.
  static void save<T>(String key, T value) {
    if (value == null) {
      delete(key);
      return;
    }
    try {
      _backend?.save(key, json.encode(value));
    } on JsonUnsupportedObjectError catch (e) {
      error('LocalStorage Error: Failed to save key "$key".', e);
    }
  }

  /// Loads a value of type [T] from storage.
  ///
  /// Returns the stored value, or [defaultValue] if the key is not found
  /// or the data cannot be decoded.
  static T? load<T>(String key, [T? defaultValue]) {
    final stored = _backend?.load(key);
    if (stored == null) return defaultValue;
    try {
      return json.decode(stored) as T;
    } catch (e) {
      warn('LocalStorage Warning: Failed to decode key "$key". Returning default.', e);
      return defaultValue;
    }
  }

  /// Deletes a value from storage for the given [key].
  static void delete(String key) {
    _backend?.delete(key);
  }

  /// Removes all stored keys.
  static void clear() {
    _backend?.clear();
  }

  /// Returns a list of all stored keys.
  static List<String> getAllKeys() {
    return _backend?.getAllKeys() ?? [];
  }
}
