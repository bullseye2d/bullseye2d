import 'package:bullseye2d/src/backend/backend.dart';
import 'package:sdl3/sdl3.dart';
import 'dart:ffi';

class Sdl3MouseBackend implements MouseBackend {
  @override
  void Function(double x, double y)? onMove;
  @override
  void Function(int button)? onButtonDown;
  @override
  void Function(int button)? onButtonUp;
  @override
  void Function(int delta)? onWheel;
  @override
  void Function(int id, double x, double y, double force)? onTouchStart;
  @override
  void Function(int id, double x, double y, double force)? onTouchMove;
  @override
  void Function(int id)? onTouchEnd;
  @override
  void Function()? onFirstClick;

  @override
  void attach() {}

  @override
  void detach() {}

  @override
  void onEndFrame() {}

  @override
  void suspend() {}

  /// Called by the SDL3 event loop for mouse motion.
  void handleMotion(Pointer<SdlEvent> event) {
    final motion = event.ref.motion;
    onMove?.call(motion.x, motion.y);
  }

  /// Called by the SDL3 event loop for mouse button events.
  void handleButton(Pointer<SdlEvent> event) {
    final btn = event.ref.button;
    // SDL3 button: 1=left, 2=middle, 3=right
    // Web/bullseye2d: 0=left, 1=middle, 2=right
    final mappedButton = btn.button - 1;
    if (mappedButton < 0) return;

    if (btn.down) {
      onFirstClick?.call();
      onFirstClick = null;
      onButtonDown?.call(mappedButton);
    } else {
      onButtonUp?.call(mappedButton);
    }
  }

  /// Called by the SDL3 event loop for mouse wheel events.
  void handleWheel(Pointer<SdlEvent> event) {
    final wheel = event.ref.wheel;
    onWheel?.call(wheel.y.sign.toInt());
  }
}
