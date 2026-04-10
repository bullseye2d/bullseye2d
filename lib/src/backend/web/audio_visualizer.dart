import 'dart:js_interop';
import 'dart:typed_data' show Uint8List;
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:web/web.dart';

/// Web Audio API implementation of [AudioVisualizerBackend].
///
/// Uses an AnalyserNode connected to a MediaElementAudioSourceNode
/// to capture time-domain waveform data from an HTMLAudioElement.
class WebAudioVisualizerBackend implements AudioVisualizerBackend {
  final AudioContext _audioContext;
  final HTMLAudioElement _audioElement;

  MediaElementAudioSourceNode? _sourceNode;
  AnalyserNode? _analyserNode;
  late Uint8List _waveformData;
  int _fftSize;

  WebAudioVisualizerBackend(this._audioContext, this._audioElement, int fftSize) : _fftSize = fftSize {
    _waveformData = Uint8List(_fftSize);
    _init();
  }

  void _init() {
    try {
      _sourceNode = _audioContext.createMediaElementSource(_audioElement);
      _analyserNode = _audioContext.createAnalyser();
      _analyserNode!.fftSize = _fftSize;
      _waveformData = Uint8List(_analyserNode!.fftSize);

      _sourceNode!.connect(_analyserNode!);
      _analyserNode!.connect(_audioContext.destination);
    } catch (e) {
      disconnect();
    }
  }

  @override
  bool get isSupported => true;

  @override
  Uint8List updateWaveformData() {
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

  @override
  int get frequencyBinCount => _analyserNode?.frequencyBinCount ?? 0;

  @override
  set fftSize(int size) {
    _fftSize = size;
    try {
      _analyserNode?.fftSize = size;
    } catch (e) {
      // ignore
    }
  }

  @override
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
