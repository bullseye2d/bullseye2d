import 'dart:typed_data' show Uint8List;
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/util/debug.dart';
import 'package:bullseye2d/src/util/math.dart';

/// {@category Audio}
/// Provides audio visualization (waveform data) for the currently playing music.
///
/// Delegates platform-specific capture to an [AudioVisualizerBackend].
class AudioVisualizer {
  AudioVisualizerBackend? _backend;
  int _fftSize;

  AudioVisualizer([int fftSize = 2048]) : _fftSize = _ensureValidFFTSize(fftSize);

  /// Initialize the visualizer from the audio backend.
  void initFromBackend(AudioBackend backend) {
    _backend?.disconnect();
    _backend = backend.createVisualizer(_fftSize);
  }

  /// Whether the audio visualizer is supported on the current platform.
  bool get isSupported => _backend?.isSupported ?? false;

  /// Updates and returns the current waveform (time-domain) data.
  ///
  /// Values are 0-255, centered at 128 (silence).
  Uint8List updateWavefromData() {
    if (_backend == null) {
      final data = Uint8List(_fftSize);
      data.fillRange(0, data.length, 128);
      return data;
    }
    return _backend!.updateWaveformData();
  }

  /// The FFT size. Must be a power of 2 between 32 and 32768.
  int get fftSize => _fftSize;

  set fftSize(int size) {
    _fftSize = _ensureValidFFTSize(size);
    _backend?.fftSize = _fftSize;
  }

  /// The number of frequency bins available.
  int get frequencyBinCount => _backend?.frequencyBinCount ?? 0;

  /// Disconnect and release resources.
  void disconnect() {
    _backend?.disconnect();
    _backend = null;
  }

  static int _ensureValidFFTSize(int size) {
    if ((size & (size - 1)) != 0) {
      warn('Invalid fftSize. Must be power of 2 between 32 and 32768.');
      size = nextPowerOfTwo(size);
    }
    if (size < 32) {
      warn('Invalid fftSize. Must be power of 2 between 32 and 32768.');
      size = 32;
    } else if (size > 32768) {
      warn('Invalid fftSize. Must be power of 2 between 32 and 32768.');
      size = 32768;
    }
    return size;
  }
}
