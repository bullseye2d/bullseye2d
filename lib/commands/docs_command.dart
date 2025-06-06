import 'package:bullseye2d/commands/commands.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_static/shelf_static.dart';

class DocsCommand extends Command {
  static const String _commandName = 'docs';
  static const String _docApiDir = 'doc/api';

  @override
  String get name => _commandName;

  @override
  String get description => 'Builds and optionally serves API documentation.';

  @override
  ArgParser get parser {
    return ArgParser()
      ..addFlag('serve', abbr: 's', help: 'Serve the generated docs.', defaultsTo: false)
      ..addOption('port', abbr: 'p', help: 'Port to serve docs on.', defaultsTo: '8081')
      ..addFlag('help', abbr: 'h', help: 'Show this help message for the "docs" command.', negatable: false);
  }

  @override
  Future<void> run(ArgResults argResults) async {
    final serveDocs = argResults['serve'] as bool;
    final portString = argResults['port'] as String;
    int? port;

    if (serveDocs) {
      port = int.tryParse(portString);
      if (port == null) {
        print('Error: Invalid port number provided: "$portString"');
        exit(1);
      }
    }

    print('Cleaning old documentation at $_docApiDir...');
    deleteDirectory(_docApiDir);

    print('Generating API documentation...');
    await runProcess(
      Platform.executable,
      ['doc', '--validate-links'],
    );

    print('Documentation generated successfully in $_docApiDir.');

    if (serveDocs) {
      if (!await Directory(_docApiDir).exists()) {
          print('Error: Documentation directory $_docApiDir does not exist. Cannot serve.');
          exit(1);
      }

      final staticHandler = createStaticHandler(
        _docApiDir,
        defaultDocument: 'index.html',
        serveFilesOutsidePath: true,
      );

      final cascade = shelf.Cascade().add(staticHandler);

      final server = await io.serve(
        shelf.logRequests().addHandler(cascade.handler),
        InternetAddress.loopbackIPv4,
        port!,
      );

      print('Serving documentation from "$_docApiDir" at http://${server.address.host}:${server.port}');
      print('Press Ctrl+C to stop the server.');

      await ProcessSignal.sigint.watch().first;

      print('\nStopping server...');
      await server.close(force: true);
      print('Server stopped.');
    }
  }
}
