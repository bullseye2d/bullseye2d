import 'package:bullseye2d/bullseye2d.dart';
import '../common/app.dart';

class HelloWorldApp extends CommonApp {
  late BitmapFont font;
  late Images pointer;

  int frameCounter = 0;
  ColorList colors = List.filled(2, Color.zero());

  @override
  onCreate() async {
    font = resources.loadFont("assets/fonts/wireone/WireOne-Regular.ttf", 256);

    pointer = resources.loadImage("assets/gfx/pointer.png", pivotX: 0.0, pivotY: 0.0);
    showMouse(pointer);
  }

  @override
  onUpdate() {
    frameCounter++;

    final brightnessFactor = 0.9 + 0.1 * cosDegree(frameCounter * 2.25);
    for (var i = 0; i < 2; ++i) {
      double baseAngle = frameCounter * 3.0 + (i * 40.0);
      colors[i].setValues(
        (sinDegree(baseAngle) + 1) / 2.0,
        (sinDegree(baseAngle + 120) + 1) / 2.0,
        (sinDegree(baseAngle + 240) + 1) / 2.0,
        1.0,
      );
      colors[i] *= brightnessFactor;
    }
  }

  @override
  onRender() {
    gfx.clear(0, 0, 0);

    double px = virtualWidth / 2;
    double py = virtualHeight / 2 + 24;

    gfx.drawText(font, "Hello World!", x: px, y: py, alignX: 0.5, alignY: 0.5, colors: colors);
  }
}
