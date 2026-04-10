import 'package:bullseye2d/src/backend/backend.dart';
import 'package:web/web.dart' show window;

class WebStorageBackend implements StorageBackend {
  final String _keyPrefix;

  WebStorageBackend() : _keyPrefix = 'bullseye2d_${window.location.pathname.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_';

  @override
  void save(String key, String value) {
    window.localStorage.setItem(_keyPrefix + key, value);
  }

  @override
  String? load(String key) {
    return window.localStorage.getItem(_keyPrefix + key);
  }

  @override
  void delete(String key) {
    window.localStorage.removeItem(_keyPrefix + key);
  }

  @override
  void clear() {
    for (var i = window.localStorage.length - 1; i >= 0; i--) {
      final key = window.localStorage.key(i);
      if (key != null && key.startsWith(_keyPrefix)) {
        window.localStorage.removeItem(key);
      }
    }
  }

  @override
  List<String> getAllKeys() {
    final keys = <String>[];
    for (int i = 0; i < window.localStorage.length; i++) {
      final key = window.localStorage.key(i);
      if (key != null && key.startsWith(_keyPrefix)) {
        keys.add(key.substring(_keyPrefix.length));
      }
    }
    return keys;
  }
}
