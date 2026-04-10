import 'dart:typed_data' show Uint8List;

import 'package:bullseye2d/src/backend/backend.dart';

// TODO: Implement SDL3 audio visualizer.
// I think using Drats FFI we are not allowed to call native functions
// from other threads (Audio thread) so we need to come up with someting
// clever or need to investigate how to do this.

/// Stub SDL3 audio visualizer — returns silence.
class Sdl3AudioVisualizerBackend implements AudioVisualizerBackend {
  int _fftSize;
  late Uint8List _waveformData;

  Sdl3AudioVisualizerBackend(int fftSize) : _fftSize = fftSize {
    _waveformData = Uint8List(_fftSize);
    _waveformData.fillRange(0, _waveformData.length, 128);
  }

  @override
  bool get isSupported => false;

  @override
  Uint8List updateWaveformData() => _waveformData;

  @override
  int get frequencyBinCount => _fftSize ~/ 2;

  @override
  set fftSize(int size) {
    _fftSize = size;
    _waveformData = Uint8List(_fftSize);
    _waveformData.fillRange(0, _waveformData.length, 128);
  }

  @override
  void disconnect() {}
}
