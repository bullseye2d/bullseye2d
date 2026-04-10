import 'package:bullseye2d/commands/commands.dart';
import 'package:path/path.dart' as p;

class CreateCommand extends Command {
  @override
  String get name => 'create';

  @override
  String get description => 'Creates a new Bullseye2D project at the specified location.';

  @override
  ArgParser get parser {
    return ArgParser()
      ..addFlag('help', abbr: 'h', help: 'Show this help message for the "create" command.', negatable: false);
  }

  String _validateProjectName(String name) {
    if (name.isEmpty) return 'Project name cannot be empty.';
    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(name)) {
      return 'Project name must be all lowercase, with underscores, using only Latin letters (a-z), digits (0-9), and underscores (_).';
    }
    if (RegExp(r'^[0-9]').hasMatch(name)) return 'Project name cannot start with a digit.';
    if (name == 'bullseye2d') return 'Project name cannot be "bullseye2d". Choose a different name.';
    return '';
  }

  String _snakeToPascalCase(String snakeCase) =>
      snakeCase.isEmpty
          ? ''
          : snakeCase
              .split('_')
              .where((part) => part.isNotEmpty)
              .map((part) => part[0].toUpperCase() + part.substring(1))
              .join('');

  @override
  Future<void> run(ArgResults argResults) async {
    if (argResults.rest.isEmpty) {
      print('Error: Project location argument is missing.');
      print('-------------------------------------------');
      print('Usage: bullseye2d create <project-location>');
      print('-------------------------------------------\n');
      printUsage();
      exit(1);
    }
    final projectLocationInput = argResults.rest.first;

    final String bullseyeRootPath = getPackageRoot();

    final projectAbsolutePath = p.canonicalize(p.join(Directory.current.path, projectLocationInput));
    final projectNameSnakeCase = p.basename(projectAbsolutePath);
    final projectParentDir = p.dirname(projectAbsolutePath);

    String validationError = _validateProjectName(projectNameSnakeCase);
    if (validationError.isNotEmpty) {
      print(' Error: Invalid project name "$projectNameSnakeCase" (derived from "$projectLocationInput").');
      print('   Reason: $validationError');
      exit(1);
    }

    final appNamePascalCase = _snakeToPascalCase(projectNameSnakeCase);
    final projectDir = Directory(projectAbsolutePath);
    if (await projectDir.exists()) {
      print('[X] Error: Directory "$projectAbsolutePath" already exists. Please choose a different location or name.');
      exit(1);
    }

    print('--- Bullseye2D Project Setup ---');

    final parentDir = Directory(projectParentDir);
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }

    // Create project directory structure
    await Directory(p.join(projectAbsolutePath, 'lib')).create(recursive: true);
    await Directory(p.join(projectAbsolutePath, 'web')).create(recursive: true);
    await Directory(p.join(projectAbsolutePath, 'bin')).create(recursive: true);
    await Directory(p.join(projectAbsolutePath, 'assets')).create(recursive: true);
    print('[+] Project structure created.');

    // Copy and process template files
    final templateDir = Directory(p.join(bullseyeRootPath, 'bin', 'template'));
    if (!templateDir.existsSync()) {
      print('[!] Error: Template directory not found at ${templateDir.path}.');
      exit(1);
    }

    final bullseyeVersion = _readPackageVersion(bullseyeRootPath);

    final replacements = {
      '{APP_NAME}': appNamePascalCase,
      '{PACKAGE_NAME}': projectNameSnakeCase,
      '{BULLSEYE_VERSION}': bullseyeVersion,
    };

    await _copyTemplateTree(templateDir.path, projectAbsolutePath, replacements);
    print('[+] Template files applied.');

    // Create symlink: web/assets -> ../assets
    final webAssetsLink = Link(p.join(projectAbsolutePath, 'web', 'assets'));
    try {
      await webAssetsLink.create(p.join('..', 'assets'));
      print('[+] Asset symlink created (web/assets -> ../assets).');
    } catch (e) {
      // Symlink failed (e.g., Windows without developer mode) — fall back to copy
      await _copyDirectory(
        p.join(projectAbsolutePath, 'assets'),
        p.join(projectAbsolutePath, 'web', 'assets'),
      );
      print('[+] Assets copied to web/assets (symlink not supported on this system).');
    }

    // Run dart pub get
    await runProcess(
      Platform.executable,
      ['pub', 'get'],
      workingDirectory: projectAbsolutePath,
      verbose: false,
    );
    print('[+] Dependencies resolved.');

    // Check for webdev
    _checkWebdev();

    final relativeProjectPath = p.relative(projectAbsolutePath, from: Directory.current.path);
    print('\n---------------------------------------------------------------------');
    print('--- Bullseye2D project "$appNamePascalCase" created successfully! ---');
    print('---------------------------------------------------------------------\n');
    print('Next steps:');
    print('  cd $relativeProjectPath\n');
    print('  Run on web:     bullseye2d run web');
    print('  Run with SDL3:  bullseye2d run sdl3\n');
    print('  Build for web:  bullseye2d build web');
    print('  Build for SDL3: bullseye2d build sdl3');
    print('---------------------------------------------------------------------');
  }

  Future<void> _copyTemplateTree(String srcRoot, String dstRoot, Map<String, String> replacements) async {
    final srcDir = Directory(srcRoot);
    await for (final entity in srcDir.list(recursive: true, followLinks: false)) {
      final relativePath = p.relative(entity.path, from: srcRoot);
      final destPath = p.join(dstRoot, relativePath).replaceAll('.tpl', '');

      if (entity is Directory) {
        await Directory(destPath).create(recursive: true);
      } else if (entity is File) {
        await Directory(p.dirname(destPath)).create(recursive: true);

        if (entity.path.endsWith('.tpl') || p.basename(entity.path) == 'index.html') {
          var content = await entity.readAsString();
          for (final entry in replacements.entries) {
            content = content.replaceAll(entry.key, entry.value);
          }
          await File(destPath).writeAsString(content);
        } else {
          await entity.copy(destPath);
        }
      }
    }
  }

  Future<void> _copyDirectory(String src, String dst) async {
    final srcDir = Directory(src);
    await for (final entity in srcDir.list(recursive: true, followLinks: false)) {
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

  String _readPackageVersion(String packageRoot) {
    final pubspec = File(p.join(packageRoot, 'pubspec.yaml'));
    if (pubspec.existsSync()) {
      for (final line in pubspec.readAsLinesSync()) {
        if (line.startsWith('version:')) {
          return line.substring(8).trim();
        }
      }
    }
    return '1.0.0';
  }

  void _checkWebdev() {
    try {
      final result = Process.runSync('dart', ['pub', 'global', 'run', 'webdev', '--version']);
      if (result.exitCode == 0) {
        print('[+] webdev is available.');
      } else {
        _printWebdevWarning();
      }
    } catch (_) {
      _printWebdevWarning();
    }
  }

  void _printWebdevWarning() {
    print('\n[!] WARNING: webdev not found. To run on web you need it:');
    print('    dart pub global activate webdev');
  }
}
