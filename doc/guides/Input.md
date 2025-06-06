# Input Module

The input module allows you to check for user input from different devices like keyboard, mouse, gamepads and touchscreens.

`Bullseye2D` polls all information just before the update loop get called.

<div class="note warning">
  <p><strong>Note</strong> You should only use the input module inside <em>app.onUpdate</em>. In <em>onRender</em> the state is invalid.</p>
</div>

## Keyboard

You can use [Keyboard API](../bullseye/Keyboard-class.html) to check key states.

To check for a specific Key, you can use the [KeyCodes](../bullseye/KeyCodes.html) enum.

| Function/Property        | Description                           |
|:----------------|:--------------------------------------|
| `keyboard.peekChar` | Read a Char from the input queue        |
| `keyboard.getChar` | Return and consume the first Char in the input queue. |
| `keyboard.getCharBuffer` | Returns a string with the input buffer.   |
| `keyboard.keyUp` | Returns `true` if the key was released in the current frame.        |
| `keyboard.keyHit` | Returns `true` if the key was hit in the current frame.        |
| `keyboard.keyDown` | Returns `true` if the key is currently pressed down        |

Here is a short example how to read the keyboard:

```dart
import 'package:bullseye2d/bullseye2d.dart';

class KeyboardDemo extends App {
  late BitmapFont font;

  @override
  onCreate() async {
    font = resources.loadFont("fonts/roboto/Roboto-Regular.ttf", 32);
  }

  @override
  onUpdate() {
    // get first char from the chard queue
    // Returns Char.empty if index is not found in queue
    Char char = keyboard.peekChar(0);
    if (char != Char.empty) {
      log("Char hit: ", char.symbol);
    }

    // Reads and consumes the next char in the input queue.
    char = keyboard.getChar();

    if (keyboard.keyUp(KeyCodes.W)) log("Ley 'W' was released!");

    // Use keyboard.keyHitCountSinceLastFrame(KeyCodes.W) if you want to 
    // know if 'W' was hit multiple times
    // since the last update
    if (keyboard.keyHit(KeyCodes.W)) log("Key 'W' is hit!");

    if (keyboard.keyDown(KeyCodes.W)) log("Key 'W' is currently pressed down!");
  }

  @override onRender() {
    gfx.clear(0, 0, 0, 1);
    gfx.drawText(font, "Press 'W' on your keyboard, watch the developer console ;)", 
      x: 25, 
      y: 25
    );
  }
}

main() {
  KeyboardDemo();
}
```

## Mouse

The [Mouse API](../bullseye/Mouse-class.html) handles mouse button presses, movement, wheel, and touch input. Coordinates are relative to the canvas (by default).

| Property/Method                | Description                                                                                                |
|--------------------------------|------------------------------------------------------------------------------------------------------------|
| `mouse.x`                      | Current mouse cursor X coordinate within the canvas.                                                         |
| `mouse.y`                      | Current mouse cursor Y coordinate within the canvas.                                                         |
| `mouse.mouseDown(MouseButton)` | `true` if the specified mouse button is currently held down.                                                  |
| `mouse.mouseUp(MouseButton)`   | `true` if the specified mouse button was released this frame.                                                 |
| `mouse.mouseHit(MouseButton)`  | `true` if the specified mouse button was pressed down this frame.                                             |
| `mouse.mouseZ`                 | Mouse wheel scroll delta for the current frame. Positive for scroll down/away, negative for scroll up/towards. |

Example:
```dart
import 'package:bullseye2d/bullseye2d.dart';

class MouseDemo extends App {
  late BitmapFont font;

  @override
  onCreate() async {
    font = resources.loadFont("fonts/roboto/Roboto-Regular.ttf", 32);

    // set update Rate to display refresh rate
    updateRate = 0;
  }

  @override
  onUpdate() {
    double ty = 25;

    gfx.clear(0, 0, 0, 1);

    // Wait until app retrieved the first mouse coordinate
    if (mouse.x == -double.maxFinite) {
      gfx.drawText(font, "Please move your mouse over the canvas", x: 25, y: ty);
      return;
    }

    int mouseX = mouse.x.toInt();
    int mouseY = mouse.y.toInt();

    gfx.drawText(font, "Mouse Position $mouseX, $mouseY", x: 25, y: ty); ty += 30;

    if (mouse.mouseDown(MouseButton.Left)) {
      gfx.drawText(font, "Left Mouse Button was pressed", x: 25, y: ty); ty += 30;
    }

    if (mouse.mouseDown(MouseButton.Middle)) {
      gfx.drawText(font, "Middel Mouse Button was pressed", x: 25, y: ty); ty += 30;
    }

    if (mouse.mouseDown(MouseButton.Right)) {
      gfx.drawText(font, "Right Mouse Button was pressed", x: 25, y: ty); ty += 30;
    }
  }
}

main() {
  MouseDemo();
}
```

## Gamepad

The [Gamepad API](../bullseye/Gamepad-class.html) supports up to 4 gamepads with a standard (XBOX Controller) mapping.


| Function / Property                          | Description                                                                                                                                                   |
| :------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `gamepad.countDevices()`             | Returns the number of connected gamepads.                                                                                                                     |
| **Button States**                            |                                                                                                                                                               |
| `gamepad.joyDown(port, button)`         | Returns `true` if the specified `button` (`GamepadButton` enum, e.g., `A`, `LB`, `Start`, `Up`) on the gamepad at `port` (index 0-3) is currently held down.   |
| `gamepad.joyUp(port, button)`           | Returns `true` if the specified `button` (`GamepadButton` enum) on the gamepad at `port` (index 0-3) was released this frame.                                 |
| `gamepad.joyHit(port, button)`          | Returns `true` if the specified `button` (`GamepadButton` enum) on the gamepad at `port` (index 0-3) was pressed down this frame.                              |
| **Axes (Joysticks)**                         |                                                                                                                                                               |
| `gamepad.joyX(port, stick)`           | Returns the X-axis value (-1.0 to 1.0) for the specified `stick` (`Joystick` enum: `Left`, `Right`) on the gamepad at `port` (index 0-3).                       |
| `gamepad.joyY(port, stick)`           | Returns the Y-axis value (-1.0 to 1.0) for the specified `stick` (`Joystick` enum: `Left`, `Right`) on the gamepad at `port` (index 0-3).                       |
| **Triggers**                                 |                                                                                                                                                               |
| `gamepad.joyZ(port, trigger)`         | Returns the trigger value (0.0 to 1.0) for the specified `trigger` (`Trigger` enum: `Left`, `Right`) on the gamepad at `port` (index 0-3).                                                                                             |

Example:
```dart
if (gamepad.countDevices() > 0) {
  if (gamepad.joyHit(0, GamepadButton.A)) {
    log("Gamepad 0: Button A pressed!");
  }
  double leftStickX = gamepad.joyX(0, Joystick.Left);
  if (leftStickX.abs() > 0.1) { // Apply a deadzone
    log("Gamepad 0: Left stick X = $leftStickX");
  }
}
```

<div class="note warning">
  <p><strong>Note</strong> To detect gamepads the user needs to first press any buttons on them. This is usally required by the browser to
    connect the game device to your context.</p>
</div>

## Accelerometer

The [Accelerometer API](../bullseye/Accelerometer-class.html) provides device motion data. Values are normalized (1.0 typically means 1G of acceleration).
| Property        | Description                           |
|:----------------|:--------------------------------------|
| `accel.x` | Acceleration along the X-axis.        |
| `accel.y` | Acceleration along the Y-axis.        |
| `accel.z` | Acceleration along the Z-axis.        |

The orientation of these axes depends on the device's screen orientation.

<div class="note warning">
  <p><strong>Note</strong> On iOS you can only retrieve the accelerometer values if you first prompt the user for permission.<br/><br/>
    If you want to automatcially prompt the user for permission on the first interaction (first click), then set <em>autoRequestAccelerometerPermission</em> to <em>true<em> in the app config. 
  </p>
</div>

```dart
import 'package:bullseye2d/bullseye2d.dart';

class AccelDemo extends App {
  AccelDemo([super.config]);
  
  late BitmapFont font;

  @override
  onCreate() async {
    font = resources.loadFont("fonts/roboto/Roboto-Regular.ttf", 128);

    // set update Rate to display refresh rate
    updateRate = 0;
  }

  @override
  onUpdate() {
    gfx.clear(0, 0, 0, 1);
    gfx.drawText(font, "X: ${accel.x.toStringAsFixed(2)}", x: 25, y: 25);
    gfx.drawText(font, "Y: ${accel.y.toStringAsFixed(2)}", x: 25, y: 225);
    gfx.drawText(font, "Z: ${accel.z.toStringAsFixed(2)}", x: 25, y: 425);
  }
}

main() {
  // On iOS Devices it is requried to request permission to read out the
  // gyroscope, so we configure the app to handle it automatically for us
  // on the first user interaction
  AccelDemo(
    AppConfig(autoRequestAccelerometerPermission: true)
  );
}
```

