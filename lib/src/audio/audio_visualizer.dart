import 'package:bullseye2d/bullseye2d.dart';
import 'dart:js_interop';
import 'package:web/web.dart';
import 'dart:typed_data' show Uint8List;

/// {@category Audio}
/// Handles the setup and data retrieval for audio visualization using the Web Audio API.
class AudioVisualizer {
  MediaElementAudioSourceNode? _sourceNode;
  AnalyserNode? _analyserNode;
  late Uint8List _waveformData;
  int _fftSize;

  /// Creates an [AudioVisualizer] instance with an optional [fftSize].
  ///
  /// - [fftSize]: The desired Fast Fourier Transform size for the analyser.
  ///   This value must be a power of 2 between 32 and 32768 (inclusive).
  ///   If an invalid value is provided, it will be adjusted to the nearest valid value.
  ///   Defaults to 2048.
  AudioVisualizer([int fftSize = 2048]) : _fftSize = fftSize, _waveformData = Uint8List(fftSize);

  /// Initializes the audio visualizer.
  ///
  /// This method sets up the necessary Web Audio API nodes and connections.
  /// It also initializes [_waveformData] based on the [fftSize].
  ///
  /// - [audioElement]: The HTML audio element whose audio will be visualized.
  /// - [audioContext]: The Web Audio API context to use for creating nodes.
  ///
  /// If an error occurs during setup (e.g., due to browser restrictions or
  /// invalid parameters), a warning is logged, and the visualizer attempts to
  /// [disconnect] any partially set up nodes.
  void init(HTMLAudioElement audioElement, AudioContext audioContext) {
    _fftSize = _ensureValidFFTSize(_fftSize);
    try {
      _sourceNode = audioContext.createMediaElementSource(audioElement);
      _analyserNode = audioContext.createAnalyser();
      _analyserNode!.fftSize = _fftSize;
      _waveformData = Uint8List(_analyserNode!.fftSize);

      _sourceNode!.connect(_analyserNode!);
      _analyserNode!.connect(audioContext.destination);
    } catch (e) {
      warn('Error setting up music analyser: $e');
      disconnect();
    }
  }

  /// Updates and returns the current waveform (time-domain) data.
  ///
  /// This method populates the [_waveformData] list with the latest audio data.
  ///
  /// Returns the updated [_waveformData].
  Uint8List updateWavefromData() {
    if (_analyserNode != null) {
      try {
        _analyserNode!.getByteTimeDomainData(_waveformData.toJS);
      } catch (e) {
        _waveformData.fillRange(0, _waveformData.length, 128);
      }
    } else {
      _waveformData.fillRange(0, _waveformData.length, 128);
    }

    return _waveformData;
  }

  int _ensureValidFFTSize(int size) {
    void w() {
      warn('Invalid fftSize. Must be power of 2 between 32 and 32768.');
    }
    if ((size & (size - 1)) != 0) {
      w();
      size = nextPowerOfTwo(size);
    }

    if (size < 32) {
      w();
      size = 32;
    } else if (size > 32768) {
      w();
      size = 32768;
    }
    return size;
  }

  /// Sets the Fast Fourier Transform (FFT) size.
  ///
  /// The [size] must be a power of 2 between 32 and 32768.
  /// If an invalid value is provided, it will be adjusted.
  /// This also affects the size of [_waveformData] and [frequencyBinCount].
  set fftSize(int size) {
    size = _ensureValidFFTSize(size);

    _fftSize = size;

    try {
      _analyserNode?.fftSize = size;
    } catch (e) {
      warn('Error setting fftSize: $e');
    }
  }

  /// Gets the current Fast Fourier Transform (FFT) size.
  ///
  /// It determines the number of samples used in the FFT analysis and thus
  /// the length of the [_waveformData].
  int get fftSize => _fftSize;

  /// Gets the number of frequency bins available.
  int get frequencyBinCount => _analyserNode?.frequencyBinCount ?? 0;

  /// Disconnects the audio nodes from the
  /// audio graph and resets them to `null`.
  ///
  /// This should be called to clean up resources when the visualizer is no longer needed
  /// or if the audio source changes.
  /// Errors during disconnection are silently ignored.
  void disconnect() {
    try {
      _sourceNode?.disconnect();
      _analyserNode?.disconnect();
    } catch (e) {
      // Ignore
    }
    _sourceNode = null;
    _analyserNode = null;
  }
}
