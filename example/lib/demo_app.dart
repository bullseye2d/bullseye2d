import 'package:bullseye2d/bullseye2d.dart';

import 'demos/hello_world.dart';
import 'demos/sprites.dart';
import 'demos/input.dart';
import 'demos/music_player.dart';

class DemoApp extends App {
  int virtualWidth = 1920;
  int virtualHeight = 1080;

  late List<Scene> demos;
  int activeIndex = 0;

  DemoApp({AppConfig? config, String initialDemo = 'hello_world'})
      : super(config) {
    const demoNames = {
      'hello_world': 0,
      'sprites': 1,
      'input': 2,
      'music_player': 3,
    };
    activeIndex = demoNames[initialDemo] ?? 0;
  }

  @override
  void onCreate() {
    demos = [
      HelloWorldDemo(this),
      SpritesDemo(this),
      InputDemo(this),
      MusicPlayerDemo(this),
    ];

    for (final demo in demos) {
      demo.onCreate();
    }
  }

  @override
  void onUpdate() {
    demos[activeIndex].onUpdate();
  }

  @override
  void onRender() {
    demos[activeIndex].onRender();
  }

  @override
  void onResize(int width, int height) {
    setRenderSize(virtualWidth, virtualHeight);

    gfx.setViewport(0, 0, virtualWidth, virtualHeight);
    gfx.set2DProjection(width: virtualWidth.toDouble(), height: virtualHeight.toDouble());

    mouse.scaleX = (displayWidth == 0) ? 1.0 : virtualWidth / displayWidth;
    mouse.scaleY = (displayHeight == 0) ? 1.0 : virtualHeight / displayHeight;
  }
}

abstract class Scene {
  final DemoApp app;
  String get name;

  Scene(this.app);

  Graphics get gfx => app.gfx;
  Mouse get mouse => app.mouse;
  Keyboard get keyboard => app.keyboard;
  Gamepad get gamepad => app.gamepad;
  ResourceManager get resources => app.resources;
  int get virtualWidth => app.virtualWidth;
  int get virtualHeight => app.virtualHeight;

  void onCreate();
  void onUpdate();
  void onRender();
  void onEnter() {}
  void onLeave() {}
}
