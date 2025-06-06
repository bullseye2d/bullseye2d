import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// {@category Input}
/// Represents the standard buttons and directional inputs found on a typical gamepad.
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

/// Holds the input state for a single gamepad.
class _GamepadInput {
  final List<double> xAxis = List.filled(2, 0.0);
  final List<double> yAxis = List.filled(2, 0.0);

  final List<double> trigger = List.filled(2, 0.0);

  final List<bool> buttonDown = List.filled(GamepadButton.values.length, false);
  final List<bool> buttonHit = List.filled(GamepadButton.values.length, false);
  final List<bool> buttonUp = List.filled(GamepadButton.values.length, false);

  static const Map<GamepadButton, int> standardButtonMapping = {
    GamepadButton.A     : 0,
    GamepadButton.B     : 1,
    GamepadButton.X     : 2,
    GamepadButton.Y     : 3,
    GamepadButton.LB    : 4,
    GamepadButton.RB    : 5,
    GamepadButton.View  : 8,
    GamepadButton.Menu  : 9,
    GamepadButton.LSB   : 10,
    GamepadButton.RSB   : 11,
    GamepadButton.Up    : 12,
    GamepadButton.Down  : 13,
    GamepadButton.Left  : 14,
    GamepadButton.Right : 15,
    GamepadButton.Home  : 16
  };

  reset() {
    buttonDown.fillRange(0, buttonDown.length, false);
    xAxis.fillRange(0, xAxis.length, 0.0);
    yAxis.fillRange(0, yAxis.length, 0.0);
    trigger.fillRange(0, trigger.length, 0.0);
  }

  suspend() {
    for (var i = 0; i < GamepadButton.values.length; ++i) {
      if (buttonDown[i]) {
        buttonUp[i] = true;
      }
    }
  }

  bool read(web.Gamepad? gamepad) {
    if (gamepad == null) return false;

    var previousButtonDown = [...buttonDown];

    reset();

    xAxis[Joystick.Left.index] = (gamepad.axes.length > 0) ? gamepad.axes[0].toDartDouble : 0.0;
    yAxis[Joystick.Left.index] = (gamepad.axes.length > 1) ? gamepad.axes[1].toDartDouble : 0.0;

    xAxis[Joystick.Right.index] = (gamepad.axes.length > 2) ? gamepad.axes[2].toDartDouble : 0.0;
    yAxis[Joystick.Right.index] = (gamepad.axes.length > 3) ? gamepad.axes[3].toDartDouble : 0.0;

    trigger[Trigger.Left.index]  = (gamepad.buttons.length > 6) ? gamepad.buttons[6].value : 0.0;
    trigger[Trigger.Right.index] = (gamepad.buttons.length > 7) ? gamepad.buttons[7].value : 0.0;

    for (var entry in standardButtonMapping.entries) {
      if (entry.value < 0 || entry.value >= gamepad.buttons.length) continue;
      buttonDown[entry.key.index] = gamepad.buttons[entry.value].pressed;
    }

    for (var button in GamepadButton.values) {
      buttonHit[button.index] = buttonDown[button.index] && !previousButtonDown[button.index];
      buttonUp[button.index]  = !buttonDown[button.index] && previousButtonDown[button.index];
    }

    return true;
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
  final List<int> _deviceLookup = List.filled(MAX_PORTS, -1);
  List<web.Gamepad?> _gamepads = [];

  /// Creates a new `Gamepad` manager.
  ///
  /// It automatically listens for gamepad connection and disconnection events
  /// and attempts to map connected gamepads to available ports.
  ///
  /// Typically, you don't instantiate this class yourself. Instead, you use
  /// the `app.gamepad` member provided by the [App] class.
  Gamepad() {
    web.window.addEventListener('gamepadconnected', _connectGamepadHandler.toJS);
    web.window.addEventListener('gamepaddisconnected', _disconnectGamepadHandler.toJS);
    for (var gamepad in _getGamepads()) {
      _connectGamepad(gamepad);
    }
  }

  /// @nodoc
  onBeginFrame() {
    _gamepads = _getGamepads();
    for (var i = 0; i < MAX_PORTS; ++i) {
      var index = _deviceLookup[i];
      if (index == -1) continue;
      if (index >= _gamepads.length) continue;
      if (_gamepads[index] == null) continue;
      _input[i].read(_gamepads[index]);
    }
  }

  /// @nodoc
  suspend() {
    for (var joyPort in _input) {
      joyPort.suspend();
    }
  }

  /// Returns the number of currently connected and mapped gamepads.
  ///
  /// This number of gamepads that the system is actively tracking,
  /// up to [MAX_PORTS].
  int countDevices() {
    int result = 0;
    for (var slot in _deviceLookup) {
      if (slot != -1) result += 1;
    }
    return result;
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
  /// Note: Y-axis conventions can vary (some APIs use positive up). This implementation
  /// follows the standard where positive Y is often down for screen coordinates.
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
  /// Returns the angle in degrees (0-359). If the joystick is centered (x=0, y=0),
  /// the angle might be consistently 90 degrees or another default depending on `atan2Degree` behavior.
  double angle(int port, Joystick joystick) {
    var x = joyX(port, joystick);
    var y = joyY(port, joystick);
    return (atan2Degree(y, x) + 360 + 90) % 360;
  }

  void _connectGamepadHandler(web.GamepadEvent event) {
    _connectGamepad(event.gamepad);
  }

  void _disconnectGamepadHandler(web.GamepadEvent event) {
    _disconnectGamepad(event.gamepad);
  }

  List<web.Gamepad?> _getGamepads() {
    try {
      return web.window.navigator.getGamepads().toDart;
    } on Exception {
      return [];
    }
  }

  bool _disconnectGamepad(web.Gamepad? gamepad) {
    if (gamepad == null) return false;

    for (var i = 0; i < _deviceLookup.length; ++i) {
      if (_deviceLookup[i] == gamepad.index) {
        _deviceLookup[i] = -1;
        log("[info] :: Gamepad disconnected at port ${gamepad.index}");
      }
    }

    return true;
  }

  bool _connectGamepad(web.Gamepad? gamepad) {
    if (gamepad == null) return false;

    if (gamepad.mapping == 'standard') {
      var slot = -1;
      for (var i = 0; i < _deviceLookup.length; ++i) {
        if (_deviceLookup[i] == -1) {
          slot = i;
          break;
        }
      }

      if (slot != -1) {
        _deviceLookup[slot] = gamepad.index;
      }
      log("[info] :: Gamepad connected at port ${gamepad.index}");
    } else {
      log("[warn] :: Ignored gamepad at port ${gamepad.index} with unrecognised mapping scheme ${gamepad.mapping}");
    }

    return true;
  }
}
