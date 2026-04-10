import 'package:bullseye2d/bullseye2d.dart';

class {APP_NAME} extends App {
  late BitmapFont font;

  {APP_NAME}([AppConfig? config]) : super(config);

  @override
  void onCreate() {
    font = resources.loadFont("assets/fonts/roboto/Roboto-Regular.ttf", 96);
  }

  @override
  void onUpdate() {}

  @override
  void onRender() {
    gfx.clear(0, 0, 0);
    gfx.drawText(font, "One hundred & eighty!", x: width / 2, y: height / 2, alignX: 0.5, alignY: 0.5);
  }
}
