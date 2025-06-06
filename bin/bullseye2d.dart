import 'package:bullseye2d/commands/commands.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner();
  runner.registerCommand(DocsCommand());
  runner.registerCommand(CreateCommand());
  await runner.run(arguments);
}

