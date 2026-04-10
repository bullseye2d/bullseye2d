import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:sdl3/sdl3.dart';

/// Locates and registers SDL3 shared libraries before SDL initialization.
///
/// Search order:
/// 1. Next to the executable or in a `lib/` subdirectory (for compiled builds)
/// 2. From the bullseye2d package's `lib/sdl3/{platform}/` directory (for development)
///
/// On Linux during development, the caller should also set `LD_LIBRARY_PATH`
/// to cover inter-library dependencies (e.g., SDL3_image depending on SDL3).
void loadSDL3() {
  final service = SdlDynamicLibraryService();
  final searchDirs = _getLibSearchDirs();

  for (final key in ['sdl', 'image', 'mixer', 'ttf']) {
    final defaultName = service.entries[key]!;
    for (final dir in searchDirs) {
      final fullPath = p.join(dir, defaultName);
      if (File(fullPath).existsSync()) {
        service.set(key, fullPath);
        break;
      }
    }
  }
}

/// Returns the path to the bundled SDL3 libraries for the current platform,
/// resolved from the bullseye2d package directory.
/// Returns null if the package directory cannot be resolved.
String? getBundledLibDir() {
  try {
    final uri = Isolate.resolvePackageUriSync(Uri.parse('package:bullseye2d/bullseye2d.dart'));
    if (uri != null) {
      final packageRoot = p.dirname(p.dirname(uri.toFilePath()));
      return p.join(packageRoot, 'lib', 'sdl3', _platformDirName());
    }
  } catch (_) {}
  return null;
}

List<String> _getLibSearchDirs() {
  final dirs = <String>[];

  // 1. Next to the executable or in lib/ subdirectory (for compiled builds)
  final exeDir = p.dirname(Platform.resolvedExecutable);
  dirs.add(p.join(exeDir, 'lib'));
  dirs.add(exeDir);

  // 2. From the bullseye2d package (for development with package dependency)
  final bundled = getBundledLibDir();
  if (bundled != null) {
    dirs.add(bundled);
  }

  return dirs;
}

String _platformDirName() {
  if (Platform.isWindows) return 'windows';
  if (Platform.isMacOS) return 'macos';
  return 'linux';
}
