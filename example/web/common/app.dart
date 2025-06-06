
import 'package:bullseye2d/bullseye2d.dart';

abstract class CommonApp extends App {
  int virtualWidth = 1920;
  int virtualHeight = 1080;

  CommonApp() : super(AppConfig(gfxBatchCapacityInBytes: 1024 * 128));

  @override
  void onResize(int width, int height) {
    canvas.width = virtualWidth;
    canvas.height = virtualHeight;

    width = canvas.width;
    height = canvas.height;

    gfx.setViewport(0, 0, width, height);
    gfx.set2DProjection(width: virtualWidth.toDouble(), height: virtualHeight.toDouble());

    mouse.scaleX = (canvas.clientWidth == 0) ? 1.0 : virtualWidth / canvas.clientWidth;
    mouse.scaleY = (canvas.clientHeight == 0) ? 1.0 : virtualHeight / canvas.clientHeight;
  }
}
