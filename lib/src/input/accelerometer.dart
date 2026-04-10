import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/input/mouse.dart';
import 'package:bullseye2d/src/util/platform.dart';

/// {@category Input}
/// Provides access to the device's accelerometer data, including the force of gravity.
///
/// On SDL3 desktop platforms this is a no-op (x, y, z are always 0.0).
class Accelerometer {
  final AccelerometerBackend _backend;

  /// The acceleration force along the x-axis, adjusted for screen orientation.
  double get x => _backend.x;

  /// The acceleration force along the y-axis, adjusted for screen orientation.
  double get y => _backend.y;

  /// The acceleration force along the z-axis.
  double get z => _backend.z;

  /// Creates an [Accelerometer] instance.
  ///
  /// If [autoRequestAccelerometerPermission] is true (needed on iOS 13+),
  /// permission is automatically requested on first user interaction.
  Accelerometer(this._backend, Mouse mouse, [bool autoRequestAccelerometerPermission = false]) {
    if (autoRequestAccelerometerPermission && Platform.isIOS()) {
      mouse.onFirstClick = () async {
        if (await _backend.requestPermission()) {
          _backend.attach();
        }
      };
    } else {
      _backend.attach();
    }
  }

  /// Requests accelerometer permission (required on iOS 13+).
  /// Must be called after a user interaction.
  ///
  /// Returns true if permission was granted.
  Future<bool> requestPermission() async {
    final granted = await _backend.requestPermission();
    if (granted) {
      _backend.attach();
    }
    return granted;
  }

  /// Stops listening for device motion events and cleans up resources.
  void dispose() {
    _backend.detach();
  }
}
