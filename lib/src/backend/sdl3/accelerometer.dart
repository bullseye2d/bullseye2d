import 'package:bullseye2d/src/backend/backend.dart';

/// SDL3 stub implementation of [AccelerometerBackend].
///
/// Currently returns 0.0 for all axes. On desktop, no sensor hardware is
/// available. On mobile (iOS/Android), SDL3 provides full accelerometer
/// support via SDL_SENSOR_ACCEL — a future implementation can use
/// sdlGetSensors() + sdlOpenSensor() + sdlGetSensorData() here and
/// gracefully fall back to 0.0 when no sensor is found.
class Sdl3AccelerometerBackend implements AccelerometerBackend {
  @override
  double get x => 0.0;

  @override
  double get y => 0.0;

  @override
  double get z => 0.0;

  @override
  void attach() {}

  @override
  void detach() {}

  @override
  Future<bool> requestPermission() async => true;
}
