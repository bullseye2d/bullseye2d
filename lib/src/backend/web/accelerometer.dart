import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/util/debug.dart';
import 'package:bullseye2d/src/backend/web/event_helper.dart';
import 'package:web/web.dart';
import 'dart:js_interop';
import 'dart:async';

/// Web implementation of [AccelerometerBackend] using the DeviceMotion API.
class WebAccelerometerBackend implements AccelerometerBackend {
  @override
  double x = 0.0;

  @override
  double y = 0.0;

  @override
  double z = 0.0;

  @override
  void attach() {
    window.addEventListener('devicemotion', _onDeviceMotion.toJS);
  }

  @override
  void detach() {
    window.removeEventListener('devicemotion', _onDeviceMotion.toJS);
  }

  @override
  Future<bool> requestPermission() async {
    var completer = Completer<bool>();
    try {
      var permissionState = await (_requestPermission().toDart);
      completer.complete(permissionState.toDart == 'granted');
    } catch (e) {
      warn("Accelerometer Permissions not granted", e.toString());
      completer.complete(false);
    }
    return completer.future;
  }

  void _onDeviceMotion(DeviceMotionEvent event) {
    var accel = event.accelerationIncludingGravity;
    if (accel != null && accel.x != null && accel.y != null && accel.z != null) {
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
