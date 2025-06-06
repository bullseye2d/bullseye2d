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

  void _printWebdevWarning(String advice, String details) {
    print('\n******************************************************************************');
    print('[!] WARNING: Could not confirm webdev is available or working correctly.');
    if (details.isNotEmpty) print('   Details: $details');
    if (advice.isNotEmpty) print(advice);
    print('   If you encounter issues running your project, you might need to:');
    print('   1. Activate webdev: dart pub global activate webdev');
    print('   2. Ensure Dart SDK\'s pub cache bin directory is in your system PATH.');
    print('******************************************************************************');
  }

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
      print('[✓] Directory $projectParentDir created.');
    }

    await runProcess(
      Platform.executable,
      ['create', '-t', 'web', projectNameSnakeCase],
      workingDirectory: projectParentDir,
      verbose: false,
    ); // Less verbose
    print('[✓] Project structure created.');

    await runProcess(
      Platform.executable,
      ['pub', 'add', 'web:^1.1.1'],
      workingDirectory: projectAbsolutePath,
      verbose: false,
    ); // Less verbose
    print('[✓] Web dependency added.');

    await runProcess(
      Platform.executable,
      ['pub', 'add', 'bullseye2d'],
      workingDirectory: projectAbsolutePath,
      verbose: false,
    ); // Less verbose
    print('[✓] Bullseye2D engine dependency added.');

    final templateDir = Directory(p.join(bullseyeRootPath, 'bin', 'template'));
    final webDir = Directory(p.join(projectAbsolutePath, 'web'));
    int filesCopied = 0, filesProcessed = 0;

    if (!templateDir.existsSync()) {
      print('[!] Warning: Template directory not found at ${templateDir.path}. Skipping template file copying.');
    } else {
      await for (final entity in templateDir.list(recursive: true, followLinks: false)) {
        final relativePath = p.relative(entity.path, from: templateDir.path);
        final destinationPath = p.join(webDir.path, relativePath).replaceAll(".tpl", "");
        final destRelative = p.relative(destinationPath, from: projectAbsolutePath);

        if (entity is File) {
          await Directory(p.dirname(destinationPath)).create(recursive: true);
          final isSpecialTemplate = entity.path.endsWith('.tpl') || p.basename(entity.path) == 'index.html';

          stdout.write(
            '  [✓] ${isSpecialTemplate ? "Processing and copying" : "Copying"} $relativePath to $destRelative...',
          );
          if (isSpecialTemplate) {
            String content = await entity.readAsString();
            content = content.replaceAll('{APP_NAME}', appNamePascalCase);
            await File(destinationPath).writeAsString(content);
            filesProcessed++;
          } else {
            await entity.copy(destinationPath);
            filesCopied++;
          }
          stdout.writeln(' Done.');
        } else if (entity is Directory) {
          await Directory(destinationPath).create(recursive: true);
        }
      }
    }

    if (filesCopied > 0 || filesProcessed > 0) {
      print('[✓] Template files (copied: $filesCopied, processed: $filesProcessed) synchronized.');
    } else {
      print('  [i] No template files were copied or processed.');
    }

    try {
      final webdevResult = await Process.run('dart', ['pub', 'global', 'run', 'webdev', '--version']);
      if (webdevResult.exitCode != 0) {
        String stderr = webdevResult.stderr.toString();
        String specificAdvice = '';
        if (stderr.contains('Could not find package "webdev"') ||
            stderr.contains('Unknown command "webdev"') ||
            webdevResult.exitCode == 65 || // Pub: package not found
            webdevResult.exitCode ==
                78 // Pub: input error (sometimes for bad commands for pub run)
                ) {
          specificAdvice =
              '   It seems "webdev" is not globally activated or not found by "dart pub global run".\n'
              '   Try running: dart pub global activate webdev';
        } else {
          specificAdvice =
              '   The command "dart pub global run webdev --version" failed.\n'
              '   webdev might not be installed or configured correctly.\n'
              '   Details (stderr): ${stderr.split('\n').first.trim()}';
        }
        _printWebdevWarning(specificAdvice, "webdev check failed (exit code ${webdevResult.exitCode})");
      } else {
        print('[✓] Webdev seems to be available.');
      }
    } catch (e) {
      String errorMessage = e.toString();
      String specificAdvice = '';
      if (e is ProcessException) {
        if (e.message.contains("No such file or directory") || // Linux/macOS
            e.message.contains("The system cannot find the file specified") // Windows
            ) {
          specificAdvice =
              '   The "dart" command (needed to run webdev) was not found. Ensure the Dart SDK is installed and its bin directory is in your system PATH.';
        } else {
          specificAdvice =
              '   An error occurred while trying to run "dart" to check webdev: ${e.message.split('\n').first.trim()}';
        }
      } else {
        specificAdvice =
            '   An unexpected error occurred while checking webdev: ${errorMessage.split('\n').first.trim()}';
      }
      _printWebdevWarning(specificAdvice, errorMessage.split('\n').first);
    }

    final relativeProjectPath = p.relative(projectAbsolutePath, from: Directory.current.path);
    print('\n-------------------------------------------------------------------');
    print('--- Bullseye2D project "$appNamePascalCase" created successfully! ---');
    print('---------------------------------------------------------------------\n');
    print('Next steps:');
    print('1. Navigate to your project directory:');
    print('   cd $relativeProjectPath');
    print('2. Start the development server:');
    print('   webdev serve');
    print('3. Open your browser and go to: http://localhost:8080');
    print('-------------------------------------------------------------------');
  }
}
