import 'package:bullseye2d/bullseye2d.dart';
import 'package:vector_math/vector_math_64.dart';
import '../common/app.dart';

class InputApp extends CommonApp {
  late BitmapFont font;

  static ColorList bgGradient = [
    Color(0.4, 0.7, 0.9, 1.0),
    Color(0.8, 0.6, 0.8, 1.0),
    Color(0.3, 0.5, 0.8, 1.0),
    Color(0.7, 0.5, 0.7, 1.0),
  ];

  String get mouseX => mouse.x.floor().toString();
  String get mouseY => mouse.y.floor().toString();
  String get leftMouseButton => "Left Mouse Button: ${mouse.mouseDown(MouseButton.Left) ? 1 : 0}";
  String get rightMouseButton => "Right Mouse Button: ${mouse.mouseDown(MouseButton.Right) ? 1 : 0}";

  late List<double> xboxControllerPoints;
  @override
  onCreate() async {
    font = resources.loadFont("assets/fonts/roboto/Roboto-Regular.ttf", 64);

    String data = await resources.loadString("assets/data/xbox_controller.txt");

    xboxControllerPoints = [];
    var points = data.split(",");
    for (var i = 0; i < points.length; i += 1) {
      xboxControllerPoints.add(double.tryParse(points[i].trim()) ?? 0.0);
    }

    mouse.x = 0;
    mouse.y = 0;
  }

  @override
  onUpdate() {}

  @override
  onRender() {
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
        drawXboxController(0, 110, tx, ty);
      } else if (n > 1) {
        drawXboxController(0, 90, tx - 400, ty);
        drawXboxController(1, 90, tx + 400, ty);
      }
    }

    gfx.drawText(font, "Mouse Position: $mouseX, $mouseY", x: 10, y: 30);
    gfx.drawText(font, leftMouseButton, x: virtualWidth - 30, y: 30, alignX: 1.0);
    gfx.drawText(font, rightMouseButton, x: virtualWidth - 30, y: 30 + font.leading, alignX: 1.0);
    gfx.drawText(font, "Keyboard Buffer:\n${keyboard.getCharBuffer()}", x: 10, y: virtualHeight - 30, alignY: 1.0);
  }

  void _drawXboxControllerSilhouette(double cx, double cy, double size, Color outlineColor, Color color) {
    final normalizedPoints = xboxControllerPoints;

    List<double> polyFillVertices = [];
    final Vector2 p0Abs = Vector2(cx + normalizedPoints[0] * size, cy + normalizedPoints[1] * size);
    for (int i = 2; i < normalizedPoints.length - 2; i += 2) {
      Vector2 pIAbs = Vector2(cx + normalizedPoints[i] * size, cy + normalizedPoints[i + 1] * size);
      Vector2 pIPlus1Abs = Vector2(cx + normalizedPoints[i + 2] * size, cy + normalizedPoints[i + 3] * size);
      polyFillVertices.add(p0Abs.x);
      polyFillVertices.add(p0Abs.y);
      polyFillVertices.add(pIAbs.x);
      polyFillVertices.add(pIAbs.y);
      polyFillVertices.add(pIPlus1Abs.x);
      polyFillVertices.add(pIPlus1Abs.y);
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

  void stick(double cx, double cy, double size, double x, double y, double r, Color color) {
    double stickX = cx + x * size;
    double stickY = cy + y * size;
    double stickR = r * size;
    gfx.drawCircle(stickX, stickY, stickR, colors: [color]);
  }

  void dpad(double cx, double cy, double size, double ncx, double ncy, double len, double w, Color color, int dpad) {
    const int left = 1 << 0;
    const int right = 1 << 1;
    const int up = 1 << 2;
    const int down = 1 << 3;

    final double dpadActualCenterX = cx + ncx * size;
    final double dpadActualCenterY = cy + ncy * size;

    final double armLength = len * size;
    final double armWidth = w * size;
    final double halfArmWidth = armWidth / 2.0;

    final double segmentLength = (armLength - armWidth) / 2.0;

    Color baseColor = color * 0.6;
    baseColor.a = 1.0;

    gfx.setColorFrom(baseColor);

    gfx.drawRect(dpadActualCenterX - armLength / 2.0, dpadActualCenterY - halfArmWidth, armLength, armWidth);
    gfx.drawRect(dpadActualCenterX - halfArmWidth, dpadActualCenterY - armLength / 2.0, armWidth, armLength);

    if (segmentLength > 0) {
      gfx.setColorFrom(color);

      if (dpad.has(left)) {
        gfx.drawRect(dpadActualCenterX - armLength / 2.0, dpadActualCenterY - halfArmWidth, segmentLength, armWidth);
      }

      if (dpad.has(right)) {
        gfx.drawRect(dpadActualCenterX + halfArmWidth, dpadActualCenterY - halfArmWidth, segmentLength, armWidth);
      }

      if (dpad.has(up)) {
        gfx.drawRect(dpadActualCenterX - halfArmWidth, dpadActualCenterY - armLength / 2.0, armWidth, segmentLength);
      }

      if (dpad.has(down)) {
        gfx.drawRect(dpadActualCenterX - halfArmWidth, dpadActualCenterY + halfArmWidth, armWidth, segmentLength);
      }
    }
  }

  void circle(double cx, double cy, double size, double x, double y, double r, Color color) {
    double buttonX = cx + x * size;
    double buttonY = cy + y * size;
    double buttonR = r * size;
    gfx.setColorFrom(color);
    gfx.drawCircle(buttonX, buttonY, buttonR);
  }

  void btn(double cx, double cy, double size, double x, double y, double w, double h, Color color) {
    double buttonW = w * size;
    double buttonH = h * size;
    double buttonX = cx + x * size - buttonW / 2;
    double buttonY = cy + y * size - buttonH / 2;
    gfx.setColorFrom(color);
    gfx.drawRect(buttonX, buttonY, buttonW, buttonH);
  }

  void shoulder(double cx, double cy, double size, double x, double y, double width, double height, Color color) {
    double sbX = cx + x * size;
    double sbY = cy + y * size;
    double sbW = width * size;
    double sbH = height * size;
    gfx.setColorFrom(color);
    gfx.drawRect(sbX, sbY, sbW, sbH);
  }

  void drawXboxController(int port, double size, double cx, double cy) {
    final Color color = Color(0.85, 0.85, 0.85, 1.0);

    _drawXboxControllerSilhouette(cx, cy, size, color, Color(0.15, 0.15, 0.15, 1.0));

    final double shoulderButtonHeight = 0.2;
    final double shoulderButtonWidth = 1.3;
    final double bumperY = -1.4;

    final double triggerHeight = 0.3;
    final double triggerWidth = shoulderButtonWidth * 1.0;
    final double triggerY = bumperY - triggerHeight - 0.02;

    final double rbX = 1.0;
    final double rtX = rbX + (shoulderButtonWidth - triggerWidth) / 2;
    final Color colRB = color * (gamepad.joyDown(port, GamepadButton.RB) ? 1.0 : 0.8);
    shoulder(cx, cy, size, rtX, triggerY, triggerWidth, triggerHeight, color * 0.5);
    shoulder(cx, cy, size, rtX, triggerY, triggerWidth * gamepad.joyZ(port, Trigger.Right), triggerHeight, color);
    shoulder(cx, cy, size, rbX, bumperY, shoulderButtonWidth, shoulderButtonHeight, colRB);

    final double lbXStart = -1.0 - shoulderButtonWidth;
    final double ltX = lbXStart + (shoulderButtonWidth - triggerWidth) / 2;
    final Color colLB = color * (gamepad.joyDown(port, GamepadButton.LB) ? 1.0 : 0.8);

    shoulder(cx, cy, size, ltX, triggerY, triggerWidth, triggerHeight, color * 0.5);
    shoulder(cx, cy, size, ltX, triggerY, triggerWidth * gamepad.joyZ(port, Trigger.Left), triggerHeight, color);
    shoulder(cx, cy, size, lbXStart, bumperY, shoulderButtonWidth, shoulderButtonHeight, colLB);

    var left = gamepad.joyDown(port, GamepadButton.Left) ? 1 : 0;
    var right = gamepad.joyDown(port, GamepadButton.Right) ? 1 : 0;
    var up = gamepad.joyDown(port, GamepadButton.Up) ? 1 : 0;
    var down = gamepad.joyDown(port, GamepadButton.Down) ? 1 : 0;

    dpad(cx, cy, size, -0.8, 1.0, 1.0, 0.3, color, left | (right << 1) | (up << 2) | (down << 3));

    final double leftStickX = -2.2;
    final double leftStickY = -0.0;
    final double stickRadius = 0.65;
    final double csize = 0.55;
    final double cr = 0.2;

    double sx = cx + gamepad.joyX(port, Joystick.Left) * size * csize;
    double sy = cy + gamepad.joyY(port, Joystick.Left) * size * csize;

    stick(cx, cy, size, leftStickX, leftStickY, stickRadius, color * 0.45);
    stick(sx, sy, size, leftStickX, leftStickY, cr, color);

    final double rightStickX = 0.8;
    final double rightStickY = 1.0;

    sx = cx + gamepad.joyX(port, Joystick.Right) * size * csize;
    sy = cy + gamepad.joyY(port, Joystick.Right) * size * csize;

    stick(cx, cy, size, rightStickX, rightStickY, stickRadius, color * 0.45);
    stick(sx, sy, size, rightStickX, rightStickY, cr, color);

    final double btnsX = 2.2;
    final double btnsY = 0.0;
    final double btnRadius = 0.3;
    final double btnOffset = 0.5;

    var colY = Color(0.9, 0.75, 0.05, 1.0) * (gamepad.joyDown(port, GamepadButton.Y) ? 1.0 : 0.8);
    var colX = Color(0.1, 0.35, 0.75, 1.0) * (gamepad.joyDown(port, GamepadButton.X) ? 1.0 : 0.8);
    var colB = Color(0.8, 0.15, 0.15, 1.0) * (gamepad.joyDown(port, GamepadButton.B) ? 1.0 : 0.8);
    var colA = Color(0.1, 0.65, 0.1, 1.0) * (gamepad.joyDown(port, GamepadButton.A) ? 1.0 : 0.8);

    circle(cx, cy, size, btnsX, btnsY - btnOffset, btnRadius, colY);
    circle(cx, cy, size, btnsX - btnOffset, btnsY, btnRadius, colX);
    circle(cx, cy, size, btnsX + btnOffset, btnsY, btnRadius, colB);
    circle(cx, cy, size, btnsX, btnsY + btnOffset, btnRadius, colA);

    final double menuY = -0.4;
    btn(cx, cy, size, 0.4, menuY, 0.4, 0.2, color * (gamepad.joyDown(port, GamepadButton.Menu) ? 1.0 : 0.8));
    btn(cx, cy, size, -0.4, menuY, 0.4, 0.2, color * (gamepad.joyDown(port, GamepadButton.View) ? 1.0 : 0.8));
    gfx.setColor();
  }
}
