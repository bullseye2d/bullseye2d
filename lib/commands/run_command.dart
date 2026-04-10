import 'package:bullseye2d/commands/commands.dart';
import 'package:bullseye2d/src/backend/sdl3/sdl3.dart';

class RunCommand extends Command {
  @override
  String get name => 'run';

  @override
  String get description => 'Runs the project for the specified target (web or sdl3).';

  @override
  ArgParser get parser {
    return ArgParser()
      ..addFlag('help', abbr: 'h', help: 'Show this help message.', negatable: false)
      ..addOption('port', abbr: 'p', help: 'Port for the web development server.', defaultsTo: '8080');
  }

  @override
  Future<void> run(ArgResults argResults) async {
    if (argResults.rest.isEmpty) {
      print('Error: Target is required.\n');
      print('Usage: bullseye2d run <web|sdl3>\n');
      print('  web      Start the webdev development server');
      print('  sdl3     Run the SDL3 desktop application');
      exit(1);
    }

    final target = argResults.rest.first;
    final extraArgs = argResults.rest.skip(1).toList();

    switch (target) {
      case 'web':
        await _runWeb(extraArgs, argResults['port'] as String);
      case 'sdl3':
        await _runSdl3(extraArgs);
      default:
        print('Error: Unknown target "$target". Use "web" or "sdl3".');
        exit(1);
    }
  }

  Future<void> _runWeb(List<String> extraArgs, String port) async {
    if (!Directory('web').existsSync()) {
      print('Error: No web/ directory found. Are you in a Bullseye2D project?');
      exit(1);
    }

    print('Starting webdev server on port $port...');
    final process = await Process.start('dart', [
      'pub',
      'global',
      'run',
      'webdev',
      'serve',
      'web:$port',
      ...extraArgs,
    ], mode: ProcessStartMode.inheritStdio);

    final exitCode = await process.exitCode;
    if (exitCode != 0) exit(exitCode);
  }

  Future<void> _runSdl3(List<String> extraArgs) async {
    final entryPoint = File('bin/main.dart');
    if (!entryPoint.existsSync()) {
      print('Error: No bin/main.dart found. Are you in a Bullseye2D project?');
      exit(1);
    }

    // Set up environment so the spawned process can find SDL3 shared libraries
    final env = _buildSdl3Environment();

    print('Running SDL3 application...');
    final process = await Process.start(
      Platform.executable,
      ['run', 'bin/main.dart', ...extraArgs],
      mode: ProcessStartMode.inheritStdio,
      environment: env,
    );

    final exitCode = await process.exitCode;
    if (exitCode != 0) exit(exitCode);
  }

  /// Builds environment variables that include SDL3 library paths.
  /// This ensures inter-library dependencies are resolved (e.g., SDL3_image → SDL3).
  Map<String, String>? _buildSdl3Environment() {
    final libDir = getBundledLibDir();
    if (libDir == null || !Directory(libDir).existsSync()) return null;

    final env = Map<String, String>.from(Platform.environment);

    if (Platform.isLinux) {
      final existing = env['LD_LIBRARY_PATH'] ?? '';
      env['LD_LIBRARY_PATH'] = existing.isEmpty ? libDir : '$libDir:$existing';
    } else if (Platform.isMacOS) {
      final existing = env['DYLD_LIBRARY_PATH'] ?? '';
      env['DYLD_LIBRARY_PATH'] = existing.isEmpty ? libDir : '$libDir:$existing';
    } else if (Platform.isWindows) {
      final existing = env['PATH'] ?? '';
      env['PATH'] = '$libDir;$existing';
    }

    return env;
  }
}
