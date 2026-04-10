import 'package:bullseye2d/commands/commands.dart';

Future<void> main(List<String> arguments) async {
  final runner = CommandRunner();
  runner.registerCommand(CreateCommand());
  runner.registerCommand(RunCommand());
  runner.registerCommand(BuildCommand());
  runner.registerCommand(DocsCommand());
  await runner.run(arguments);
}
