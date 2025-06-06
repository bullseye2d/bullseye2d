import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart';
import 'hello_world/hello_world.dart';
import 'input/input.dart';
import 'music_player/music_player.dart';
import 'sprites/sprites.dart';

main() {
  var params = Uri.dataFromString(window.location.search).queryParameters;

  logEnableStacktrace((params['enableStacktrace'] ?? '0') == '1');

  switch (params['app'] ?? 'hello_world') {
    case 'hello_world':
      HelloWorldApp();
      break;

    case 'sprites':
      SpritesApp();
      break;

    case 'music_player':
      MusicPlayerApp();
      break;

    case 'input':
      InputApp();
      break;

    default:
      error("Unknown app!");
  }
}
