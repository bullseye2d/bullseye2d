import 'package:bullseye2d/bullseye2d.dart';
import '../common/app.dart';

class SpritesApp extends CommonApp {
  static const zoomFactor = 7.0;

  late BitmapFont font;

  late Images walker;
  double frame = 0;

  @override
  onCreate() async {
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
  onUpdate() {
    frame += 0.15;
  }

  @override
  onRender() {
    var center = Point(virtualWidth / 2, virtualHeight / 2);
    gfx.clear(0, 0, 0);
    gfx.drawImage(walker, frame.floor() % walker.length, center.x, center.y, 0, zoomFactor, zoomFactor);

    gfx.setColor(0.4, 0.4, 0.4);
    gfx.drawText(
      font,
      "walker created by henk nieborg\n© copyright by asylum square",
      x: center.x,
      y: virtualHeight - 50,
      alignX: 0.5,
      alignY: 0.5,
    );
    gfx.setColor();
  }
}
