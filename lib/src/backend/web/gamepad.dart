import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/bullseye2d.dart' show log;
import 'package:web/web.dart' as web;
import 'dart:js_interop';

class WebGamepadBackend implements GamepadBackend {
  static const int _maxPorts = 4;

  final List<int> _deviceLookup = List.filled(_maxPorts, -1);
  List<web.Gamepad?> _gamepads = [];

  // Per-port state: axes, triggers, buttons
  final List<List<double>> _xAxis = List.generate(_maxPorts, (_) => List.filled(2, 0.0));
  final List<List<double>> _yAxis = List.generate(_maxPorts, (_) => List.filled(2, 0.0));
  final List<List<double>> _trigger = List.generate(_maxPorts, (_) => List.filled(2, 0.0));
  final List<List<bool>> _buttonDown = List.generate(_maxPorts, (_) => List.filled(16, false));

  @override
  void Function(int port)? onConnected;
  @override
  void Function(int port)? onDisconnected;

  WebGamepadBackend() {
    web.window.addEventListener('gamepadconnected', _connectHandler.toJS);
    web.window.addEventListener('gamepaddisconnected', _disconnectHandler.toJS);
    for (var gamepad in _getGamepads()) {
      _connectGamepad(gamepad);
    }
  }

  @override
  void poll() {
    _gamepads = _getGamepads();
    for (var i = 0; i < _maxPorts; ++i) {
      var index = _deviceLookup[i];
      if (index == -1) continue;
      if (index >= _gamepads.length) continue;
      var gamepad = _gamepads[index];
      if (gamepad == null) continue;

      _xAxis[i][0] = (gamepad.axes.length > 0) ? gamepad.axes[0].toDartDouble : 0.0;
      _yAxis[i][0] = (gamepad.axes.length > 1) ? gamepad.axes[1].toDartDouble : 0.0;
      _xAxis[i][1] = (gamepad.axes.length > 2) ? gamepad.axes[2].toDartDouble : 0.0;
      _yAxis[i][1] = (gamepad.axes.length > 3) ? gamepad.axes[3].toDartDouble : 0.0;

      _trigger[i][0] = (gamepad.buttons.length > 6) ? gamepad.buttons[6].value : 0.0;
      _trigger[i][1] = (gamepad.buttons.length > 7) ? gamepad.buttons[7].value : 0.0;

      // Standard button mapping
      const buttonMap = [0, 1, 2, 3, 4, 5, -1, -1, 8, 9, 10, 11, 12, 13, 14, 15];
      for (var b = 0; b < buttonMap.length; b++) {
        var mapped = buttonMap[b];
        if (mapped >= 0 && mapped < gamepad.buttons.length) {
          _buttonDown[i][b] = gamepad.buttons[mapped].pressed;
        } else {
          _buttonDown[i][b] = false;
        }
      }
    }
  }

  @override
  int get connectedCount {
    int result = 0;
    for (var slot in _deviceLookup) {
      if (slot != -1) result += 1;
    }
    return result;
  }

  @override
  double axisValue(int port, int axis) {
    if (port < 0 || port >= _maxPorts) return 0.0;
    // axis 0-1 = left stick X/Y, axis 2-3 = right stick X/Y
    if (axis == 0) return _xAxis[port][0];
    if (axis == 1) return _yAxis[port][0];
    if (axis == 2) return _xAxis[port][1];
    if (axis == 3) return _yAxis[port][1];
    // triggers
    if (axis == 4) return _trigger[port][0];
    if (axis == 5) return _trigger[port][1];
    return 0.0;
  }

  @override
  bool buttonPressed(int port, int button) {
    if (port < 0 || port >= _maxPorts) return false;
    if (button < 0 || button >= _buttonDown[port].length) return false;
    return _buttonDown[port][button];
  }

  void _connectHandler(web.GamepadEvent event) {
    _connectGamepad(event.gamepad);
  }

  void _disconnectHandler(web.GamepadEvent event) {
    _disconnectGamepad(event.gamepad);
  }

  List<web.Gamepad?> _getGamepads() {
    try {
      return web.window.navigator.getGamepads().toDart;
    } on Exception {
      return [];
    }
  }

  void _connectGamepad(web.Gamepad? gamepad) {
    if (gamepad == null) return;

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
        onConnected?.call(slot);
      }
      log("[info] :: Gamepad connected at port ${gamepad.index}");
    } else {
      log("[warn] :: Ignored gamepad at port ${gamepad.index} with unrecognised mapping scheme ${gamepad.mapping}");
    }
  }

  void _disconnectGamepad(web.Gamepad? gamepad) {
    if (gamepad == null) return;
    for (var i = 0; i < _deviceLookup.length; ++i) {
      if (_deviceLookup[i] == gamepad.index) {
        _deviceLookup[i] = -1;
        onDisconnected?.call(i);
        log("[info] :: Gamepad disconnected at port ${gamepad.index}");
      }
    }
  }
}
