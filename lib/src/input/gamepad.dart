import 'package:bullseye2d/bullseye2d.dart';
import 'package:bullseye2d/src/backend/backend.dart';

/// {@category Input}
/// Represents the standard buttons and directional inputs found on a typical gamepad.
// dart format off
enum GamepadButton {
  // ignore: constant_identifier_names
  A,  B,  X,  Y,  LB,  RB,  View,  Menu,  Left,  Up,  Right,  Down,  LSB,  RSB,  Home
}

/// {@category Input}
/// Identifies the left or right analog stick on a gamepad.
enum Joystick {
  // ignore: constant_identifier_names
  Left, Right
}

/// {@category Input}
/// Identifies the left or right analog trigger on a gamepad.
enum Trigger {
  // ignore: constant_identifier_names
  Left, Right
}

// dart format on
/// Holds the input state for a single gamepad port.
class _GamepadInput {
  final List<double> xAxis = List.filled(2, 0.0);
  final List<double> yAxis = List.filled(2, 0.0);

  final List<double> trigger = List.filled(2, 0.0);

  final List<bool> buttonDown = List.filled(GamepadButton.values.length, false);
  final List<bool> buttonHit = List.filled(GamepadButton.values.length, false);
  final List<bool> buttonUp = List.filled(GamepadButton.values.length, false);

  void reset() {
    buttonDown.fillRange(0, buttonDown.length, false);
    xAxis.fillRange(0, xAxis.length, 0.0);
    yAxis.fillRange(0, yAxis.length, 0.0);
    trigger.fillRange(0, trigger.length, 0.0);
  }

  void suspend() {
    for (var i = 0; i < GamepadButton.values.length; ++i) {
      if (buttonDown[i]) {
        buttonUp[i] = true;
      }
    }
  }

  /// @nodoc
  void readFromBackend(GamepadBackend backend, int port) {
    var previousButtonDown = [...buttonDown];

    reset();

    // Axes: 0=leftX, 1=leftY, 2=rightX, 3=rightY, 4=triggerL, 5=triggerR
    xAxis[Joystick.Left.index] = backend.axisValue(port, 0);
    yAxis[Joystick.Left.index] = backend.axisValue(port, 1);
    xAxis[Joystick.Right.index] = backend.axisValue(port, 2);
    yAxis[Joystick.Right.index] = backend.axisValue(port, 3);
    trigger[Trigger.Left.index] = backend.axisValue(port, 4);
    trigger[Trigger.Right.index] = backend.axisValue(port, 5);

    // Buttons — backend button indices map to GamepadButton enum indices
    for (var button in GamepadButton.values) {
      buttonDown[button.index] = backend.buttonPressed(port, button.index);
    }

    for (var button in GamepadButton.values) {
      buttonHit[button.index] = buttonDown[button.index] && !previousButtonDown[button.index];
      buttonUp[button.index] = !buttonDown[button.index] && previousButtonDown[button.index];
    }
  }
}

/// {@category Input}
/// Manages input from connected gamepads.
///
/// This class handles the detection of gamepads, reading their states (buttons, axes, triggers),
/// and providing an interface to query these states. It supports multiple gamepads
/// up to [MAX_PORTS].
class Gamepad {
  /// The maximum number of gamepad ports (simultaneously connected gamepads) supported.
  // ignore: constant_identifier_names
  static const int MAX_PORTS = 4;

  final List<_GamepadInput> _input = List.generate(MAX_PORTS, (_) => _GamepadInput(), growable: false);
  final GamepadBackend _backend;

  /// @nodoc
  Gamepad(this._backend);

  /// @nodoc
  void onBeginFrame() {
    _backend.poll();
    for (var i = 0; i < MAX_PORTS; ++i) {
      _input[i].readFromBackend(_backend, i);
    }
  }

  /// @nodoc
  void suspend() {
    for (var joyPort in _input) {
      joyPort.suspend();
    }
  }

  /// Returns the number of currently connected and mapped gamepads.
  ///
  /// This number of gamepads that the system is actively tracking,
  /// up to [MAX_PORTS].
  int countDevices() {
    return _backend.connectedCount;
  }

  /// Checks if a specific button on a given gamepad port is currently held down.
  ///
  /// - [port]: The gamepad port index (0 to [MAX_PORTS] - 1).
  /// - [btn]: The [GamepadButton] to check.
  ///
  /// Returns `true` if the button is pressed, `false` otherwise or if the port is invalid.
  bool joyDown(int port, GamepadButton btn) {
    if (port < 0 || port >= _input.length) return false;
    return _input[port].buttonDown[btn.index];
  }

  /// Checks if a specific button on a given gamepad port was just pressed in the current frame.
  ///
  /// - [port]: The gamepad port index (0 to [MAX_PORTS] - 1).
  /// - [btn]: The [GamepadButton] to check.
  ///
  /// Returns `true` if the button was pressed in this frame (i.e., it was up last frame and is down now),
  /// `false` otherwise or if the port is invalid.
  bool joyHit(int port, GamepadButton btn) {
    if (port < 0 || port >= _input.length) return false;
    return _input[port].buttonHit[btn.index];
  }

  /// Checks if a specific button on a given gamepad port was just released in the current frame.
  ///
  /// - [port]: The gamepad port index (0 to [MAX_PORTS] - 1).
  /// - [btn]: The [GamepadButton] to check.
  ///
  /// Returns `true` if the button was released in this frame (i.e., it was down last frame and is up now),
  /// `false` otherwise or if the port is invalid.
  bool joyUp(int port, GamepadButton btn) {
    if (port < 0 || port >= _input.length) return false;
    return _input[port].buttonUp[btn.index];
  }

  /// Gets the current X-axis value of a specified joystick on a given gamepad port.
  ///
  /// - [port]: The gamepad port index (0 to [MAX_PORTS] - 1).
  /// - [joystick]: The [Joystick] (Left or Right) to query.
  ///
  /// Returns the X-axis value, typically ranging from -1.0 (left) to 1.0 (right).
  /// Returns 0.0 if the port or joystick is invalid.
  double joyX(int port, Joystick joystick) {
    int index = joystick.index;
    if (port < 0 || port >= _input.length) return 0.0;
    if (index < 0 || index >= _input[port].xAxis.length) return 0.0;
    return _input[port].xAxis[index];
  }

  /// Gets the current Y-axis value of a specified joystick on a given gamepad port.
  ///
  /// - [port]: The gamepad port index (0 to [MAX_PORTS] - 1).
  /// - [joystick]: The [Joystick] (Left or Right) to query.
  ///
  /// Returns the Y-axis value, typically ranging from -1.0 (up) to 1.0 (down).
  /// Returns 0.0 if the port or joystick is invalid.
  double joyY(int port, Joystick joystick) {
    int index = joystick.index;
    if (port < 0 || port >= _input.length) return 0.0;
    if (index < 0 || index >= _input[port].yAxis.length) return 0.0;
    return _input[port].yAxis[index];
  }

  /// Gets the current value of a specified analog trigger on a given gamepad port.
  ///
  /// - [port]: The gamepad port index (0 to [MAX_PORTS] - 1).
  /// - [trigger]: The [Trigger] (Left or Right) to query.
  ///
  /// Returns the trigger value, typically ranging from 0.0 (released) to 1.0 (fully pressed).
  /// Returns 0.0 if the port or trigger is invalid.
  double joyZ(int port, Trigger trigger) {
    int index = trigger.index;
    if (port < 0 || port >= _input.length) return 0.0;
    if (index < 0 || index >= _input[port].trigger.length) return 0.0;
    return _input[port].trigger[index];
  }

  /// Calculates the angle of a specified joystick on a given gamepad port.
  ///
  /// The angle is in degrees, where 0 degrees is typically pointing upwards,
  /// 90 degrees is right, 180 is down, and 270 is left.
  ///
  /// - [port]: The gamepad port index (0 to [MAX_PORTS] - 1).
  /// - [joystick]: The [Joystick] (Left or Right) to query.
  ///
  /// Returns the angle in degrees (0-359).
  double angle(int port, Joystick joystick) {
    var x = joyX(port, joystick);
    var y = joyY(port, joystick);
    return (atan2Degree(y, x) + 360 + 90) % 360;
  }
}
