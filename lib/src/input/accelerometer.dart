import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart';
import 'dart:js_interop';
import 'dart:async';

/// {@category Input}
/// Provides access to the device's accelerometer data, including the force of gravity.
class Accelerometer {
  /// The acceleration force along the x-axis, adjusted for screen orientation.
  double x = 0.0;

  /// The acceleration force along the y-axis, adjusted for screen orientation.
  double y = 0.0;

  /// The acceleration force along the z-axis.
  double z = 0.0;

  /// Creates an [Accelerometer] instance and starts listening for device motion events.
  /// Typically, you don't instantiate this class yourself. Instead, you use
  /// the `app.accelerometer` member provided by the [App] class.
  Accelerometer(HTMLCanvasElement canvas, Mouse mouse, [bool autoRequestAccelerometerPermission = false]) {
    if (autoRequestAccelerometerPermission && Platform.isIOS()) {
      mouse.onFirstClick = () async {
        if (await requestPermission()) {
          window.addEventListener('devicemotion', _onDeviceMotion.toJS);
        }
      };
    } else {
      window.addEventListener('devicemotion', _onDeviceMotion.toJS);
    }
  }

  /// This is required on iOS 13+ to retrieve data from the gyroscope. It only works if
  /// it is called after a user interaction.
  ///
  /// If you set `autoRequestAccelerometerPermission` in the AppConfig to true it will
  /// automatically handled on first user interaction
  Future<bool> requestPermission() async {
    var completer = Completer<bool>();

    if (Platform.isIOS()) {
      try {
        var permissionState = await (_requestPermission().toDart);
        completer.complete(permissionState.toDart == 'granted');
        window.addEventListener('devicemotion', _onDeviceMotion.toJS);
      } catch (e) {
        warn("Accelerometer Permissions not granted", e.toString());
        completer.complete(false);
      }
    } else {
      window.addEventListener('devicemotion', _onDeviceMotion.toJS);
      completer.complete(true);
    }

    return completer.future;
  }

  /// Stops listening for device motion events and cleans up resources.
  dispose() {
    window.removeEventListener('devicemotion', _onDeviceMotion.toJS);
  }

  void _onDeviceMotion(DeviceMotionEvent event) {
    var accel = event.accelerationIncludingGravity;
    if (accel != null && accel.x != null && accel.y != null && accel.z != null) {
      // NOTE: Let's assume we are on earth...
      double tx = accel.x! / 9.81;
      double ty = accel.y! / 9.81;
      z = accel.z! / 9.81;

      switch (window.screen.orientation.angle) {
        case 0:
          x = tx;
          y = -ty;
          break;
        case -90:
          x = ty;
          y = tx;
          break;
        case 90:
          x = -ty;
          y = -tx;
          break;
        case 180:
          x = -tx;
          y = ty;
          break;
        default:
          x = tx;
          y = -ty;
      }

      stopEvent(event);
    }
  }
}

@JS('DeviceOrientationEvent.requestPermission')
external JSPromise<JSString> _requestPermission();
