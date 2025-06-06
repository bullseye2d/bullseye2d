import 'package:bullseye2d/bullseye2d.dart';

class {APP_NAME} extends App {
  late BitmapFont font;

  @override
  onCreate() async {
    font = resources.loadFont("fonts/roboto/Roboto-Regular.ttf", 96);
    log("MyApp :: MyApp created");
  }

  @override
  onUpdate() {
  }

  @override
  onRender() {
    gfx.clear(0, 0, 0);
    gfx.drawText(font, "One hundred & eighty!", x: width / 2, y: height / 2, alignX: 0.5, alignY: 0.5);
  }
}

main() {
  {APP_NAME}();
}
