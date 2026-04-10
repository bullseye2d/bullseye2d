import 'dart:convert';
import 'dart:io';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:path/path.dart' as p;

class Sdl3StorageBackend implements StorageBackend {
  final Map<String, String> _data = {};
  late final String _filePath;

  Sdl3StorageBackend({String appName = 'bullseye2d'}) {
    _filePath = p.join(_getStorageDir(appName), 'storage.json');
    _loadFromDisk();
  }

  static String _getStorageDir(String appName) {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'] ?? '';
      return p.join(appData, 'bullseye2d', appName);
    } else if (Platform.isMacOS) {
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, 'Library', 'Application Support', 'bullseye2d', appName);
    } else {
      final home = Platform.environment['HOME'] ?? '';
      return p.join(home, '.local', 'share', 'bullseye2d', appName);
    }
  }

  void _loadFromDisk() {
    try {
      final file = File(_filePath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        final Map<String, dynamic> decoded = json.decode(content);
        for (final entry in decoded.entries) {
          _data[entry.key] = entry.value.toString();
        }
      }
    } catch (_) {
      // Ignore errors; start with empty data
    }
  }

  void _saveToDisk() {
    try {
      final file = File(_filePath);
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(json.encode(_data));
    } catch (_) {
      // Ignore write errors
    }
  }

  @override
  void save(String key, String value) {
    _data[key] = value;
    _saveToDisk();
  }

  @override
  String? load(String key) {
    return _data[key];
  }

  @override
  void delete(String key) {
    _data.remove(key);
    _saveToDisk();
  }

  @override
  void clear() {
    _data.clear();
    _saveToDisk();
  }

  @override
  List<String> getAllKeys() {
    return _data.keys.toList();
  }
}
