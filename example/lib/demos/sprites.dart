import 'package:bullseye2d/bullseye2d.dart';
import '../demo_app.dart';

class SpritesDemo extends Scene {
  static const zoomFactor = 7.0;

  @override
  String get name => 'Sprites';

  late BitmapFont font;
  late Images walker;
  double frame = 0;

  SpritesDemo(super.app);

  @override
  void onCreate() {
    font = resources.loadFont("assets/fonts/pressstart2p/PressStart2P-Regular.ttf", 32, antiAlias: false);
    font.leadingMod = 1.4;

    walker = resources.loadImage(
      "assets/gfx/walker_spritesheet.png",
      frameWidth: 59,
      frameHeight: 58,
      paddingX: 2,
      paddingY: 2,
      textureFlags: 0,
      pivotX: 32 / 58.0,
      pivotY: 0.5,
    );
  }

  @override
  void onUpdate() {
    frame += 0.15;
  }

  @override
  void onRender() {
    var center = Point(virtualWidth / 2, virtualHeight / 2);
    gfx.clear(0, 0, 0);
    gfx.drawImage(walker, frame.floor() % walker.length, center.x, center.y, 0, zoomFactor, zoomFactor);

    gfx.setColor(0.4, 0.4, 0.4);
    gfx.drawText(
      font,
      "walker created by henk nieborg\n\u00a9 copyright by asylum square",
      x: center.x,
      y: virtualHeight - 50.0,
      alignX: 0.5,
      alignY: 0.5,
    );
    gfx.setColor();
  }
}
