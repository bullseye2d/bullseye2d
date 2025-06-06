import 'dart:async';
import 'dart:io';
import 'command.dart';


class CommandRunner {
  final Map<String, Command> _commands = {};

  void registerCommand(Command command) {
    _commands[command.name] = command;
  }

  Future<void> run(List<String> arguments) async {
    if (arguments.isEmpty) {
      printGlobalUsage();
      exit(0);
    }

    final commandName = arguments.first;

    if (commandName == '--help' || commandName == '-h') {
      printGlobalUsage();
      exit(0);
    }

    final command = _commands[commandName];

    if (command == null) {
      print('Error: Unknown command "$commandName".\n');
      printGlobalUsage();
      exit(1);
    }

    final commandArgs = arguments.sublist(1);
    try {
      await command.execute(commandArgs);
      exit(0);
    } catch (e, s) {
      print('An unexpected error occurred while running command "$commandName":');
      print(e);
      print('Stack trace:\n$s');
      exit(1);
    }
  }

  void printGlobalUsage() {
    print('Usage: bullseye2d <command> [options]\n');
    print('Available commands:');
      _commands.forEach((name, command) {
        print('  ${name.padRight(15)} ${command.description}');
      });
    print('\nRun `bullseye2d <command> --help` for more information on a specific command.');
  }
}
