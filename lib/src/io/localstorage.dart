import 'package:bullseye2d/bullseye2d.dart';
import 'dart:convert';
import 'package:web/web.dart';

/// A utility class for managing state in the browser `localStorage`.
///
/// Provides a typed interface for saving and loading JSON-serializable data.
/// All keys are automatically prefixed to avoid collisions with other data
/// stored on the same domain. The prefix is generated based on the application's
/// URL path.
class LocalStorage {
  /// Generates a unique prefix for local storage keys based on the URL path.
  /// This helps namespace the data for this specific part of the web app.
  static String get _keyPrefix {
    final path = window.location.pathname.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    return 'bullseye2d_${path}_';
  }

  /// Saves a value to local storage with the given [key].
  ///
  /// The [value] must be JSON-serializable (e.g., `int`, `double`, `String`,
  /// `bool`, `List`, `Map<String, dynamic>`).
  ///
  /// If [value] is `null`, the key is removed from storage.
  /// Throws an [ArgumentError] if the [value] is not JSON-serializable.
  static void save<T>(String key, T value) {
    final prefixedKey = _keyPrefix + key;

    if (value == null) {
      delete(key);
      return;
    }

    try {
      final serializedValue = json.encode(value);
      window.localStorage.setItem(prefixedKey, serializedValue);
    } on JsonUnsupportedObjectError catch (e) {
      error('LocalStorage Error: Failed to save key "$key".', e);
    }
  }

  /// Loads a value of type [T] from local storage.
  ///
  /// Returns the stored value for the [key], or the [defaultValue] if the key
  /// is not found, or if the data is corrupted/cannot be cast to type [T].
  static T? load<T>(String key, [T? defaultValue]) {
    final prefixedKey = _keyPrefix + key;
    final storedValue = window.localStorage.getItem(prefixedKey);

    if (storedValue == null) {
      return defaultValue;
    }

    try {
      return json.decode(storedValue) as T;
    } catch (e) {
      warn('LocalStorage Warning: Failed to load/decode key "$key". Returning default value. Error:', e);
      return defaultValue;
    }
  }

  /// Deletes a value from local storage for the given [key].
  static void delete(String key) {
    final prefixedKey = _keyPrefix + key;
    window.localStorage.removeItem(prefixedKey);
  }

  /// Removes all keys associated with this application's prefix.
  ///
  /// This iterates backwards to safely remove items while iterating.
  static void clear() {
    final prefix = _keyPrefix;
    for (var i = window.localStorage.length - 1; i >= 0; i--) {
      final key = window.localStorage.key(i);
      if (key != null && key.startsWith(prefix)) {
        window.localStorage.removeItem(key);
      }
    }
  }

  /// Returns a list of all keys stored by this utility, without the prefix.
  static List<String> getAllKeys() {
    final prefix = _keyPrefix;
    final keys = <String>[];

    for (int i = 0; i < window.localStorage.length; i++) {
      final key = window.localStorage.key(i);
      if (key != null && key.startsWith(prefix)) {
        keys.add(key.substring(prefix.length));
      }
    }
    return keys;
  }
}
