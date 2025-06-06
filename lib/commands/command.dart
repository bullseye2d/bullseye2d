import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;

abstract class Command {
  ArgParser get parser;

  /// The name of the command
  String get name;

  /// A short description of what the command does, used in global help.
  String get description;

  /// Executes the command.
  Future<void> execute(List<String> arguments) async {
    ArgResults argResults;
    try {
      argResults = parser.parse(arguments);
    } catch (e) {
      print('Error parsing arguments for command "$name": $e\n');
      printUsage();
      exit(1);
    }

    if (argResults['help'] as bool? ?? false) {
      printUsage();
      exit(0);
    }

    await run(argResults);
  }

  /// The core logic of the command, to be implemented by subclasses.
  Future<void> run(ArgResults argResults);

  /// Deletes a directory recursively.
  void deleteDirectory(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (e) {
        print('Error deleting directory $path: $e');
        exit(1);
      }
    } else {
      print('Directory $path does not exist, skipping deletion.');
    }
  }

  /// Executes a process and handles its output and errors.
  Future<ProcessResult> runProcess(
    String executable,
    List<String> processArgs, {
    String? workingDirectory,
    bool verbose = false,
  }) async {
    final commandString = '$executable ${processArgs.join(' ')}';
    final wdString = workingDirectory != null ? ' in $workingDirectory' : '';

    if (verbose) {
      print('Running command: $commandString$wdString');
    }

    final processResult = await Process.run(executable, processArgs, workingDirectory: workingDirectory);

    if (processResult.exitCode != 0) {
      print('Error running command: $commandString$wdString (Exit code: ${processResult.exitCode})');
      if ((processResult.stdout as String).isNotEmpty) {
        print('STDOUT:\n${processResult.stdout}');
      }
      if ((processResult.stderr as String).isNotEmpty) {
        print('STDERR:\n${processResult.stderr}');
      }
      exit(processResult.exitCode);
    } else {
      if (verbose) {
        print('Command "$commandString" completed successfully.');
        if ((processResult.stdout as String).isNotEmpty) {
          print('Output:\n${processResult.stdout}');
        }
        if ((processResult.stderr as String).isNotEmpty) {
          print('Stderr (though command succeeded):\n${processResult.stderr}');
        }
      }
    }
    return processResult;
  }

  String getPackageRoot() {
    final selfPackageUri = Uri.parse('package:bullseye2d/bullseye2d.dart');
    final resolvedUri = Isolate.resolvePackageUriSync(selfPackageUri);
    if (resolvedUri == null) {
      throw StateError('Could not resolve package URI for bullseye2d. Make sure the package is correctly installed.');
    }
    return p.dirname(p.dirname(resolvedUri.toFilePath()));
  }

  /// Prints the usage information for this specific command.
  void printUsage() {
    print('Usage: bullseye2d $name [options]\n');
    print('$description\n');
    print('Options for command "$name":');
    print(parser.usage);
  }
}
