import 'dart:io';
import 'dart:typed_data';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:path/path.dart' as p;

class Sdl3FileBackend implements FileBackend {
  /// Base directory for resolving relative asset paths.
  /// Tries the current working directory first, then the executable directory.
  late final String _cwdBase;
  late final String _exeBase;

  Sdl3FileBackend() {
    _cwdBase = Directory.current.path;
    _exeBase = p.dirname(Platform.resolvedExecutable);
  }

  String _resolvePath(String path) {
    if (p.isAbsolute(path)) return path;
    // Try current working directory first (useful for `dart run`)
    final cwdPath = p.join(_cwdBase, path);
    if (File(cwdPath).existsSync()) return cwdPath;
    // Fall back to executable directory (useful for compiled binaries)
    return p.join(_exeBase, path);
  }

  @override
  Future<Uint8List> loadBytes(String path) async {
    final file = File(_resolvePath(path));
    if (!await file.exists()) {
      return Uint8List(0);
    }
    return file.readAsBytes();
  }

  @override
  Future<String> loadString(String path) async {
    final file = File(_resolvePath(path));
    if (!await file.exists()) {
      return '';
    }
    return file.readAsString();
  }

  @override
  void onProgress(String path, void Function(int loaded, int total) callback) {
    // For SDL3, we could report progress for large files, but for simplicity
    // we report 0 -> total once complete. This can be enhanced later.
  }
}
