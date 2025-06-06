import 'dart:async';
import 'dart:convert';

import 'package:bullseye2d/commands/commands.dart';
import 'package:path/path.dart' as p;

class ExamplesCommand extends Command {
  @override
  String get name => 'examples';

  @override
  String get description => 'Builds and serves the example projects.\n';

  static const String _examplesDirName = 'example';
  static const String _ansiErrorHighlight = '\x1b[41;97m';
  static const String _ansiSuccessHighlight = '\x1b[92m';
  static const String _ansiReset = '\x1b[0m';

  final RegExp _dartErrorPattern = RegExp(r'(.*\.dart:\d+:\d+:)');
  final RegExp _infoSucceededPattern = RegExp(r'^(\[INFO\] Succeeded.*)$');

  @override
  ArgParser get parser {
    return ArgParser()
      ..addOption('vm-service-port', help: 'Port for the Dart VM service.', defaultsTo: '6969')
      ..addFlag('live-reload', help: 'Enable live reload for "build_runner serve".', defaultsTo: true)
      ..addOption('hostname', abbr: 'N', help: 'Hostname to serve on (for all targets).', defaultsTo: 'localhost')
      ..addOption(
        'port',
        abbr: 'P',
        help: 'Default port to serve on if no port is specified in a target.',
        defaultsTo: '8080',
      )
      ..addFlag('highlight', help: 'Highlight .dart errors and success messages in output.', defaultsTo: false)
      ..addFlag('help', abbr: 'h', help: 'Show this help message for the "examples" command.', negatable: false);
  }

  String _highlightLine(String line) {
    String highlightedLine = line;
    highlightedLine = highlightedLine.replaceAllMapped(_dartErrorPattern, (match) {
      return '$_ansiErrorHighlight${match.group(0)}$_ansiReset';
    });
    highlightedLine = highlightedLine.replaceAllMapped(_infoSucceededPattern, (match) {
      return '$_ansiSuccessHighlight${match.group(0)}$_ansiReset';
    });
    return highlightedLine;
  }

  @override
  Future<void> run(ArgResults argResults) async {
    final String vmServicePort = argResults['vm-service-port'] as String;
    final bool liveReload = argResults['live-reload'] as bool;
    final String hostname = argResults['hostname'] as String;
    final String defaultPort = argResults['port'] as String;
    final bool highlightOutput = argResults['highlight'] as bool;
    final String packageRootPath = getPackageRoot();
    final String examplesDirPath = p.join(packageRootPath, _examplesDirName);

    if (!Directory(examplesDirPath).existsSync()) {
      print('Error: Directory "$examplesDirPath" not found.');
      print(
        'This command expects to be run from the project root, and for an "$_examplesDirName" subdirectory to exist.',
      );
      exit(1);
    }

    if (!File(p.join(examplesDirPath, 'pubspec.yaml')).existsSync()) {
      print('Error: "$examplesDirPath/pubspec.yaml" not found.');
      print('Ensure "$_examplesDirName" is a valid Dart package and run "dart pub get" within it if necessary.');
      exit(1);
    }

    await runProcess(Platform.executable, ['pub', 'get'], workingDirectory: examplesDirPath, verbose: false);
    print('[✓] Dependencies fetched for examples.');

    List<String> dartVmArgs = [];
    if (vmServicePort.isNotEmpty && int.tryParse(vmServicePort) != null) {
      dartVmArgs.add('--enable-vm-service=$vmServicePort');
    } else if (vmServicePort.isNotEmpty) {
      print('Warning: Invalid VM service port "$vmServicePort". VM service will not be enabled.');
    }

    var targets = List<String>.from(argResults.rest);
    if (targets.isEmpty) {
      targets.add('web:$defaultPort');
    }

    List<String> buildRunnerCommandArgs = ['serve', '--hostname=$hostname'];

    if (liveReload) {
      buildRunnerCommandArgs.add('--live-reload');
    }
    buildRunnerCommandArgs.addAll(targets);

    final String executable = Platform.executable; // dart
    final List<String> processArgs = [...dartVmArgs, 'run', 'build_runner', ...buildRunnerCommandArgs];

    print('Executing in directory "$examplesDirPath": $executable ${processArgs.join(' ')}\n');

    final process = await Process.start(
      executable,
      processArgs,
      workingDirectory: examplesDirPath,
      runInShell: Platform.isWindows,
      mode: ProcessStartMode.normal,
    );

    final stdoutCompleter = Completer<void>();
    final stderrCompleter = Completer<void>();

    var sigintSubscription = ProcessSignal.sigint.watch().listen((signal) {
      print('\nStopping build_runner (SIGINT received)...');
      final killed = process.kill(ProcessSignal.sigint);
      if (!killed) {
        print('Failed to send SIGINT, attempting SIGKILL.');
        process.kill(ProcessSignal.sigkill);
      }
    });

    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (highlightOutput) {
              stdout.writeln(_highlightLine(line));
            } else {
              stdout.writeln(line);
            }
          },
          onDone: () {
            if (!stdoutCompleter.isCompleted) stdoutCompleter.complete();
          },
          onError: (e) {
            if (!stdoutCompleter.isCompleted) stdoutCompleter.completeError(e);
          },
        );

    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (highlightOutput) {
              stderr.writeln('$_ansiErrorHighlight$line$_ansiReset');
            } else {
              stderr.writeln(line);
            }
          },
          onDone: () {
            if (!stderrCompleter.isCompleted) stderrCompleter.complete();
          },
          onError: (e) {
            if (!stderrCompleter.isCompleted) stderrCompleter.completeError(e);
          },
        );

    final exitCode = await process.exitCode;

    await Future.wait([stdoutCompleter.future.catchError((_) {}), stderrCompleter.future.catchError((_) {})]);

    await sigintSubscription.cancel();

    if (exitCode != 0 &&
        exitCode != -ProcessSignal.sigint.signalNumber &&
        exitCode != -ProcessSignal.sigterm.signalNumber) {
      print('\nbuild_runner exited with code $exitCode');
      exit(exitCode); // Propagate failure exit code
    } else if (exitCode == 0) {
      print('\nbuild_runner finished successfully.');
    }
  }
}
