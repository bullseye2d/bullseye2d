import 'package:bullseye_examples/demo_app.dart';
import 'package:bullseye2d/bullseye2d.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: bullseye2d run sdl3 <demo>\n');
    print('Available demos:');
    print('  hello_world    Hello World demo');
    print('  sprites        Sprites demo');
    print('  input          Input demo');
    print('  music_player   Music Player demo');
    return;
  }

  DemoApp(
    config: AppConfig(
      title: 'Bullseye2D - ${args[0]}',
      width: 1280,
      height: 720,
    ),
    initialDemo: args[0],
  );
}
