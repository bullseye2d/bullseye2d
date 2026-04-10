import 'package:bullseye2d/bullseye2d.dart';
import '../demo_app.dart';

class InputDemo extends Scene {
  late BitmapFont font;
  late List<double> xboxControllerPoints;

  static ColorList bgGradient = [
    Color(0.4, 0.7, 0.9, 1.0),
    Color(0.8, 0.6, 0.8, 1.0),
    Color(0.3, 0.5, 0.8, 1.0),
    Color(0.7, 0.5, 0.7, 1.0),
  ];

  InputDemo(super.app);

  @override
  void onCreate() async {
    font = resources.loadFont("assets/fonts/roboto/Roboto-Regular.ttf", 64);

    String data = await resources.loadString("assets/data/xbox_controller.txt");

    xboxControllerPoints = [];
    var points = data.split(",");
    for (var i = 0; i < points.length; i += 1) {
      xboxControllerPoints.add(double.tryParse(points[i].trim()) ?? 0.0);
    }
  }

  @override
  void onUpdate() {}

  @override
  void onRender() {
    double w = virtualWidth.toDouble();
    double h = virtualHeight.toDouble();

    gfx.drawRect(0, 0, w, h, colors: bgGradient);

    final double cx = virtualWidth / 2.0;
    final double cy = virtualHeight / 2.0 - 80;

    var n = gamepad.countDevices();

    if (n == 0) {
      final String text = "No Gamepad connected.\nConnect a gamepad and press any button.";
      gfx.drawLine(40, cy - 50, 1900, cy - 50);
      gfx.drawLine(40, cy + 150, 1900, cy + 150);
      gfx.drawText(font, text, x: cx, y: cy + 70, alignX: 0.5, alignY: 0.5);
    } else {
      var tx = cx;
      var ty = cy + 20;
      if (n == 1) {
        _drawXboxController(0, 110, tx, ty);
      } else if (n > 1) {
        _drawXboxController(0, 90, tx - 400, ty);
        _drawXboxController(1, 90, tx + 400, ty);
      }
    }

    String mouseX = mouse.x.floor().toString();
    String mouseY = mouse.y.floor().toString();

    gfx.drawText(font, "Mouse Position: $mouseX, $mouseY", x: 10, y: 30);
    gfx.drawText(font, "Left Mouse Button: ${mouse.mouseDown(MouseButton.Left) ? 1 : 0}",
        x: virtualWidth - 30, y: 30, alignX: 1.0);
    gfx.drawText(font, "Right Mouse Button: ${mouse.mouseDown(MouseButton.Right) ? 1 : 0}",
        x: virtualWidth - 30, y: 30 + font.leading, alignX: 1.0);
    gfx.drawText(font, "Keyboard Buffer:\n${keyboard.getCharBuffer()}", x: 10, y: virtualHeight - 30, alignY: 1.0);
  }

  void _drawXboxControllerSilhouette(double cx, double cy, double size, Color outlineColor, Color color) {
    final normalizedPoints = xboxControllerPoints;

    List<double> polyFillVertices = [];
    final p0X = cx + normalizedPoints[0] * size;
    final p0Y = cy + normalizedPoints[1] * size;
    for (int i = 2; i < normalizedPoints.length - 2; i += 2) {
      final pIX = cx + normalizedPoints[i] * size;
      final pIY = cy + normalizedPoints[i + 1] * size;
      final pIPlus1X = cx + normalizedPoints[i + 2] * size;
      final pIPlus1Y = cy + normalizedPoints[i + 3] * size;
      polyFillVertices.add(p0X);
      polyFillVertices.add(p0Y);
      polyFillVertices.add(pIX);
      polyFillVertices.add(pIY);
      polyFillVertices.add(pIPlus1X);
      polyFillVertices.add(pIPlus1Y);
    }

    if (polyFillVertices.isNotEmpty) {
      gfx.drawPoly(polyFillVertices, colors: [color]);
    }

    List<double> lineVertices = [];
    for (int i = 0; i < normalizedPoints.length - 1; i += 2) {
      lineVertices.add(cx + normalizedPoints[i] * size);
      lineVertices.add(cy + normalizedPoints[i + 1] * size);
    }
    lineVertices.add(cx + normalizedPoints[0] * size);
    lineVertices.add(cy + normalizedPoints[1] * size);

    gfx.drawLines(lineVertices, colors: [outlineColor]);
  }

  void _stick(double cx, double cy, double size, double x, double y, double r, Color color) {
    gfx.drawCircle(cx + x * size, cy + y * size, r * size, colors: [color]);
  }

  void _dpad(double cx, double cy, double size, double ncx, double ncy, double len, double w, Color color, int dpad) {
    const int left = 1 << 0;
    const int right = 1 << 1;
    const int up = 1 << 2;
    const int down = 1 << 3;

    final double dpadCX = cx + ncx * size;
    final double dpadCY = cy + ncy * size;
    final double armLength = len * size;
    final double armWidth = w * size;
    final double halfArmWidth = armWidth / 2.0;
    final double segmentLength = (armLength - armWidth) / 2.0;

    Color baseColor = color * 0.6;
    baseColor.a = 1.0;
    gfx.setColorFrom(baseColor);
    gfx.drawRect(dpadCX - armLength / 2.0, dpadCY - halfArmWidth, armLength, armWidth);
    gfx.drawRect(dpadCX - halfArmWidth, dpadCY - armLength / 2.0, armWidth, armLength);

    if (segmentLength > 0) {
      gfx.setColorFrom(color);
      if (dpad.has(left)) gfx.drawRect(dpadCX - armLength / 2.0, dpadCY - halfArmWidth, segmentLength, armWidth);
      if (dpad.has(right)) gfx.drawRect(dpadCX + halfArmWidth, dpadCY - halfArmWidth, segmentLength, armWidth);
      if (dpad.has(up)) gfx.drawRect(dpadCX - halfArmWidth, dpadCY - armLength / 2.0, armWidth, segmentLength);
      if (dpad.has(down)) gfx.drawRect(dpadCX - halfArmWidth, dpadCY + halfArmWidth, armWidth, segmentLength);
    }
  }

  void _circle(double cx, double cy, double size, double x, double y, double r, Color color) {
    gfx.setColorFrom(color);
    gfx.drawCircle(cx + x * size, cy + y * size, r * size);
  }

  void _btn(double cx, double cy, double size, double x, double y, double w, double h, Color color) {
    double bw = w * size;
    double bh = h * size;
    gfx.setColorFrom(color);
    gfx.drawRect(cx + x * size - bw / 2, cy + y * size - bh / 2, bw, bh);
  }

  void _shoulder(double cx, double cy, double size, double x, double y, double w, double h, Color color) {
    gfx.setColorFrom(color);
    gfx.drawRect(cx + x * size, cy + y * size, w * size, h * size);
  }

  void _drawXboxController(int port, double size, double cx, double cy) {
    final Color color = Color(0.85, 0.85, 0.85, 1.0);
    _drawXboxControllerSilhouette(cx, cy, size, color, Color(0.15, 0.15, 0.15, 1.0));

    final double sbh = 0.2, sbw = 1.3, bumperY = -1.4;
    final double th = 0.3, tw = sbw, ty = bumperY - th - 0.02;

    final double rbX = 1.0, rtX = rbX + (sbw - tw) / 2;
    _shoulder(cx, cy, size, rtX, ty, tw, th, color * 0.5);
    _shoulder(cx, cy, size, rtX, ty, tw * gamepad.joyZ(port, Trigger.Right), th, color);
    _shoulder(cx, cy, size, rbX, bumperY, sbw, sbh, color * (gamepad.joyDown(port, GamepadButton.RB) ? 1.0 : 0.8));

    final double lbX = -1.0 - sbw, ltX = lbX + (sbw - tw) / 2;
    _shoulder(cx, cy, size, ltX, ty, tw, th, color * 0.5);
    _shoulder(cx, cy, size, ltX, ty, tw * gamepad.joyZ(port, Trigger.Left), th, color);
    _shoulder(cx, cy, size, lbX, bumperY, sbw, sbh, color * (gamepad.joyDown(port, GamepadButton.LB) ? 1.0 : 0.8));

    var dl = gamepad.joyDown(port, GamepadButton.Left) ? 1 : 0;
    var dr = gamepad.joyDown(port, GamepadButton.Right) ? 1 : 0;
    var du = gamepad.joyDown(port, GamepadButton.Up) ? 1 : 0;
    var dd = gamepad.joyDown(port, GamepadButton.Down) ? 1 : 0;
    _dpad(cx, cy, size, -0.8, 1.0, 1.0, 0.3, color, dl | (dr << 1) | (du << 2) | (dd << 3));

    const double cs = 0.55, cr = 0.2, sr = 0.65;

    double sx = cx + gamepad.joyX(port, Joystick.Left) * size * cs;
    double sy = cy + gamepad.joyY(port, Joystick.Left) * size * cs;
    _stick(cx, cy, size, -2.2, 0.0, sr, color * 0.45);
    _stick(sx, sy, size, -2.2, 0.0, cr, color);

    sx = cx + gamepad.joyX(port, Joystick.Right) * size * cs;
    sy = cy + gamepad.joyY(port, Joystick.Right) * size * cs;
    _stick(cx, cy, size, 0.8, 1.0, sr, color * 0.45);
    _stick(sx, sy, size, 0.8, 1.0, cr, color);

    const double bx = 2.2, by = 0.0, br = 0.3, bo = 0.5;
    _circle(cx, cy, size, bx, by - bo, br, Color(0.9, 0.75, 0.05, 1.0) * (gamepad.joyDown(port, GamepadButton.Y) ? 1.0 : 0.8));
    _circle(cx, cy, size, bx - bo, by, br, Color(0.1, 0.35, 0.75, 1.0) * (gamepad.joyDown(port, GamepadButton.X) ? 1.0 : 0.8));
    _circle(cx, cy, size, bx + bo, by, br, Color(0.8, 0.15, 0.15, 1.0) * (gamepad.joyDown(port, GamepadButton.B) ? 1.0 : 0.8));
    _circle(cx, cy, size, bx, by + bo, br, Color(0.1, 0.65, 0.1, 1.0) * (gamepad.joyDown(port, GamepadButton.A) ? 1.0 : 0.8));

    _btn(cx, cy, size, 0.4, -0.4, 0.4, 0.2, color * (gamepad.joyDown(port, GamepadButton.Menu) ? 1.0 : 0.8));
    _btn(cx, cy, size, -0.4, -0.4, 0.4, 0.2, color * (gamepad.joyDown(port, GamepadButton.View) ? 1.0 : 0.8));
    gfx.setColor();
  }
}
