import 'package:bullseye2d/commands/commands.dart';
import 'package:bullseye2d/src/backend/sdl3/sdl3.dart';
import 'package:path/path.dart' as p;

class BuildCommand extends Command {
  @override
  String get name => 'build';

  @override
  String get description => 'Builds the project for the specified target (web or sdl3).';

  @override
  ArgParser get parser {
    return ArgParser()
      ..addFlag('help', abbr: 'h', help: 'Show this help message.', negatable: false)
      ..addOption('output', abbr: 'o', help: 'Output directory.');
  }

  @override
  Future<void> run(ArgResults argResults) async {
    if (argResults.rest.isEmpty) {
      print('Error: Target is required.\n');
      print('Usage: bullseye2d build <web|sdl3>\n');
      print('  web      Build for web deployment');
      print('  sdl3     Compile executable and bundle assets + SDL3 libraries');
      exit(1);
    }

    final target = argResults.rest.first;

    switch (target) {
      case 'web':
        await _buildWeb(argResults);
      case 'sdl3':
        await _buildSdl3(argResults);
      default:
        print('Error: Unknown target "$target". Use "web" or "sdl3".');
        exit(1);
    }
  }

  Future<void> _buildWeb(ArgResults argResults) async {
    if (!Directory('web').existsSync()) {
      print('Error: No web/ directory found. Are you in a Bullseye2D project?');
      exit(1);
    }

    final output = argResults['output'] as String? ?? 'build/web';
    print('Building for web...');
    final process = await Process.start('dart', [
      'pub',
      'global',
      'run',
      'webdev',
      'build',
      '-o',
      'web:$output',
    ], mode: ProcessStartMode.inheritStdio);

    final exitCode = await process.exitCode;
    if (exitCode != 0) exit(exitCode);

    print('\nWeb build complete: $output/');
  }

  Future<void> _buildSdl3(ArgResults argResults) async {
    final entryPoint = File('bin/main.dart');
    if (!entryPoint.existsSync()) {
      print('Error: No bin/main.dart found. Are you in a Bullseye2D project?');
      exit(1);
    }

    final outputDir = argResults['output'] as String? ?? 'build/sdl3';
    final projectName = _getProjectName();
    final exeName = Platform.isWindows ? '$projectName.exe' : projectName;
    final exePath = p.join(outputDir, exeName);

    // Create output directory
    await Directory(outputDir).create(recursive: true);

    // Compile executable
    print('Compiling executable...');
    await runProcess(Platform.executable, ['compile', 'exe', 'bin/main.dart', '-o', exePath], verbose: false);
    print('[+] Compiled: $exePath');

    // Bundle assets
    final assetsDir = Directory('assets');
    if (assetsDir.existsSync()) {
      final destAssets = p.join(outputDir, 'assets');
      final destAssetsDir = Directory(destAssets);
      if (destAssetsDir.existsSync()) {
        await destAssetsDir.delete(recursive: true);
      }
      await _copyDirectory(assetsDir.path, destAssets);
      print('[+] Assets bundled: $destAssets/');
    }

    // Bundle SDL3 shared libraries
    await _bundleSDL3Libraries(outputDir);

    print('\nSDL3 build complete: $outputDir/');
    print('  Executable: $exePath');
    if (assetsDir.existsSync()) {
      print('  Assets:     $outputDir/assets/');
    }
    print('\nThe build output is self-contained and ready to distribute.');
  }

  /// Copies SDL3 shared libraries from the bullseye2d package into the build output.
  Future<void> _bundleSDL3Libraries(String outputDir) async {
    final libDir = getBundledLibDir();
    if (libDir == null) {
      print('[!] Warning: Could not locate bundled SDL3 libraries.');
      print('    SDL3 shared libraries must be available at runtime.');
      return;
    }

    final sourceDir = Directory(libDir);
    if (!sourceDir.existsSync()) {
      print('[!] Warning: SDL3 library directory not found: $libDir');
      print('    SDL3 shared libraries must be available at runtime.');
      return;
    }

    int copied = 0;
    await for (final entity in sourceDir.list()) {
      if (entity is File) {
        final destPath = p.join(outputDir, p.basename(entity.path));
        await entity.copy(destPath);
        copied++;
      }
    }

    if (copied > 0) {
      print('[+] SDL3 libraries bundled ($copied files)');
    } else {
      print('[!] Warning: No SDL3 libraries found in $libDir');
    }
  }

  String _getProjectName() {
    final pubspec = File('pubspec.yaml');
    if (pubspec.existsSync()) {
      final lines = pubspec.readAsLinesSync();
      for (final line in lines) {
        if (line.startsWith('name:')) {
          return line.substring(5).trim();
        }
      }
    }
    return p.basename(Directory.current.path);
  }

  Future<void> _copyDirectory(String src, String dst) async {
    final srcDir = Directory(src);
    await for (final entity in srcDir.list(recursive: true, followLinks: true)) {
      final relativePath = p.relative(entity.path, from: src);
      final destPath = p.join(dst, relativePath);
      if (entity is Directory) {
        await Directory(destPath).create(recursive: true);
      } else if (entity is File) {
        await Directory(p.dirname(destPath)).create(recursive: true);
        await entity.copy(destPath);
      }
    }
  }
}
