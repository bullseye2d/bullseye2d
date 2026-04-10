import 'dart:ffi';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:sdl3/sdl3.dart';

class Sdl3GamepadBackend implements GamepadBackend {
  static const int _maxPorts = 4;

  final List<Pointer<SdlGamepad>> _gamepads = List.filled(_maxPorts, nullptr);
  final List<int> _instanceIds = List.filled(_maxPorts, -1);

  // Axis state per port: [leftX, leftY, rightX, rightY, triggerL, triggerR]
  final List<List<double>> _axes = List.generate(_maxPorts, (_) => List.filled(6, 0.0));
  // Button state per port
  final List<List<bool>> _buttons = List.generate(_maxPorts, (_) => List.filled(16, false));

  @override
  void Function(int port)? onConnected;
  @override
  void Function(int port)? onDisconnected;

  @override
  void poll() {
    for (var i = 0; i < _maxPorts; i++) {
      final gp = _gamepads[i];
      if (gp == nullptr) continue;

      _axes[i][0] = sdlGetGamepadAxis(gp, SDL_GAMEPAD_AXIS_LEFTX) / 32767.0;
      _axes[i][1] = sdlGetGamepadAxis(gp, SDL_GAMEPAD_AXIS_LEFTY) / 32767.0;
      _axes[i][2] = sdlGetGamepadAxis(gp, SDL_GAMEPAD_AXIS_RIGHTX) / 32767.0;
      _axes[i][3] = sdlGetGamepadAxis(gp, SDL_GAMEPAD_AXIS_RIGHTY) / 32767.0;
      _axes[i][4] = sdlGetGamepadAxis(gp, SDL_GAMEPAD_AXIS_LEFT_TRIGGER) / 32767.0;
      _axes[i][5] = sdlGetGamepadAxis(gp, SDL_GAMEPAD_AXIS_RIGHT_TRIGGER) / 32767.0;

      // Map SDL gamepad buttons to bullseye2d GamepadButton indices
      // A=0, B=1, X=2, Y=3, LB=4, RB=5, View=6(Back)=8web, Menu=7(Start)=9web, etc.
      _buttons[i][0] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_SOUTH);
      _buttons[i][1] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_EAST);
      _buttons[i][2] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_WEST);
      _buttons[i][3] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_NORTH);
      _buttons[i][4] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_LEFT_SHOULDER);
      _buttons[i][5] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER);
      _buttons[i][6] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_BACK);
      _buttons[i][7] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_START);
      _buttons[i][8] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_LEFT_STICK);
      _buttons[i][9] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_RIGHT_STICK);
      _buttons[i][10] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_DPAD_UP);
      _buttons[i][11] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_DPAD_DOWN);
      _buttons[i][12] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_DPAD_LEFT);
      _buttons[i][13] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_DPAD_RIGHT);
      _buttons[i][14] = sdlGetGamepadButton(gp, SDL_GAMEPAD_BUTTON_GUIDE);
      _buttons[i][15] = false; // unused
    }
  }

  @override
  int get connectedCount {
    int count = 0;
    for (var gp in _gamepads) {
      if (gp != nullptr) count++;
    }
    return count;
  }

  @override
  double axisValue(int port, int axis) {
    if (port < 0 || port >= _maxPorts) return 0.0;
    if (axis < 0 || axis >= _axes[port].length) return 0.0;
    return _axes[port][axis];
  }

  @override
  bool buttonPressed(int port, int button) {
    if (port < 0 || port >= _maxPorts) return false;
    if (button < 0 || button >= _buttons[port].length) return false;
    return _buttons[port][button];
  }

  /// Called by the SDL3 event loop when a gamepad is added.
  void handleDeviceAdded(int instanceId) {
    for (var i = 0; i < _maxPorts; i++) {
      if (_gamepads[i] == nullptr) {
        final gp = sdlOpenGamepad(instanceId);
        if (gp != nullptr) {
          _gamepads[i] = gp;
          _instanceIds[i] = instanceId;
          onConnected?.call(i);
        }
        return;
      }
    }
  }

  /// Called by the SDL3 event loop when a gamepad is removed.
  void handleDeviceRemoved(int instanceId) {
    for (var i = 0; i < _maxPorts; i++) {
      if (_instanceIds[i] == instanceId) {
        sdlCloseGamepad(_gamepads[i]);
        _gamepads[i] = nullptr;
        _instanceIds[i] = -1;
        onDisconnected?.call(i);
        return;
      }
    }
  }

  void dispose() {
    for (var i = 0; i < _maxPorts; i++) {
      if (_gamepads[i] != nullptr) {
        sdlCloseGamepad(_gamepads[i]);
        _gamepads[i] = nullptr;
      }
    }
  }
}
