import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/backend/web/audio_visualizer.dart';
import 'package:bullseye2d/src/audio/audio.dart';
import 'package:web/web.dart';
import 'dart:js_interop';
import 'dart:math';
import 'dart:typed_data';

/// @nodoc
class AudioChannel {
  AudioBufferSourceNode? sourceNode;
  WebAudioBufferHandle? sound;

  late GainNode gainNode;
  late PannerNode pannerNode;

  var loop = false;
  var offset = 0.0;
  var pan = 0.0;
  var rate = 1.0;
  var startTime = 0.0;
  var state = ChannelState.stopped;
  var volume = 1.0;

  AudioChannel(AudioContext audioContext) {
    gainNode = audioContext.createGain()..connect(audioContext.destination);

    pannerNode =
        audioContext.createPanner()
          ..rolloffFactor = 0
          ..panningModel = 'equalpower'
          ..connect(gainNode);
  }
}

/// Web Audio API implementation of [AudioBufferHandle].
class WebAudioBufferHandle implements AudioBufferHandle {
  final AudioBuffer buffer;

  WebAudioBufferHandle(this.buffer);

  @override
  double get duration => buffer.duration;

  double get sampleRate => buffer.sampleRate;

  @override
  void dispose() {
    // AudioBuffer has no explicit dispose -- GC handles it.
  }
}

/// Web Audio API implementation of [AudioBackend].
class WebAudioBackend implements AudioBackend {
  static const int _numChannels = 32;

  late final AudioContext audioContext;
  late final List<AudioChannel> _channels;
  final List<int> _allChannels = List.generate(_numChannels, (index) => index);

  // Music state
  Future<void>? _playPromise;
  HTMLAudioElement? _music;
  double _musicVolume = 1.0;

  WebAudioBackend();

  @override
  void init() {
    audioContext = AudioContext();
    _channels = List.generate(_numChannels, (_) => AudioChannel(audioContext), growable: false);
  }

  void ensureResumed() {
    if (audioContext.state == 'suspended') {
      audioContext.resume();
    }
  }

  // ---------------------------------------------------------------------------
  // Sound channels
  // ---------------------------------------------------------------------------

  @override
  int playSound(
    AudioBufferHandle buffer, {
    int channel = -1,
    bool loop = false,
    double volume = 1.0,
    double pan = 0.0,
    double rate = 1.0,
    double loopStart = -1,
    double loopEnd = -1,
  }) {
    ensureResumed();

    if (channel < 0) {
      channel = obtainFreeChannel(null);
    }
    if (channel < 0 || channel >= _numChannels) return -1;

    final webBuffer = buffer as WebAudioBufferHandle;
    final ch = _channels[channel];

    // Stop any currently playing audio on this channel
    if (ch.state != ChannelState.stopped && ch.sourceNode != null) {
      ch.sourceNode!.onended = null;
      try {
        ch.sourceNode!.stop(0);
        ch.state = ChannelState.stopped;
      } catch (e) {
        //
      }
    }

    ch
      ..sound = webBuffer
      ..loop = loop
      ..sourceNode = audioContext.createBufferSource()
      ..sourceNode!.buffer = webBuffer.buffer
      ..sourceNode!.playbackRate.value = ch.rate
      ..sourceNode!.loop = loop
      ..sourceNode!.connect(ch.pannerNode);

    if (ch.sourceNode!.loop) {
      if (loopStart > 0 && loopEnd > loopStart) {
        double hz = webBuffer.sampleRate;
        loopStart = loopStart / hz;
        loopEnd = loopEnd / hz;
      } else {
        loopStart = 0;
        loopEnd = ch.sourceNode!.buffer!.duration;
      }

      ch.sourceNode!
        ..loopStart = loopStart
        ..loopEnd = loopEnd;
    }

    ch.sourceNode!.onended =
        (Event event) {
          ch
            ..sourceNode = null
            ..state = ChannelState.stopped;
        }.toJS;

    ch
      ..offset = 0
      ..startTime = audioContext.currentTime
      ..sourceNode?.start(0)
      ..state = ChannelState.playing;

    return channel;
  }

  @override
  void stopChannel(int channel) {
    if (channel < 0 || channel >= _numChannels) return;
    var ch = _channels[channel];
    if (ch.state == ChannelState.stopped) return;

    if (ch.state == ChannelState.playing) {
      ch.sourceNode?.onended = null;
      try {
        ch.sourceNode?.stop(0);
      } catch (e) {
        //
      }
      ch.sourceNode = null;
    }
    ch.state = ChannelState.stopped;
  }

  @override
  void pauseChannel(int channel) {
    if (channel < 0 || channel >= _numChannels) return;
    var ch = _channels[channel];
    if (ch.state != ChannelState.playing) return;

    ch.offset =
        (ch.offset + (audioContext.currentTime - ch.startTime) * ch.rate) %
        ch.sound!.buffer.duration;

    ch.sourceNode?.onended = null;
    try {
      ch.sourceNode?.stop(0);
    } catch (e) {
      //
    }
    ch
      ..sourceNode = null
      ..state = ChannelState.paused;
  }

  @override
  void resumeChannel(int channel) {
    if (channel < 0 || channel >= _numChannels) return;
    ensureResumed();
    var ch = _channels[channel];
    if (ch.state != ChannelState.paused) return;

    ch.sourceNode = audioContext.createBufferSource();

    ch.sourceNode!
      ..buffer = ch.sound!.buffer
      ..playbackRate.value = ch.rate
      ..loop = ch.loop
      ..connect(ch.pannerNode)
      ..onended =
          (Event e) {
            ch.sourceNode = null;
            ch.state = ChannelState.stopped;
          }.toJS;

    ch
      ..startTime = audioContext.currentTime
      ..sourceNode!.start(0, ch.offset)
      ..state = ChannelState.playing;
  }

  @override
  void setChannelVolume(int channel, double volume) {
    if (channel < 0 || channel >= _numChannels) return;
    var ch = _channels[channel];
    ch
      ..volume = volume
      ..gainNode.gain.value = volume;
  }

  @override
  void setChannelPan(int channel, double pan) {
    if (channel < 0 || channel >= _numChannels) return;
    var sinPan = sin(pan * pi / 2);
    var cosPan = cos(pan * pi / 2);

    _channels[channel]
      ..pan = pan
      ..pannerNode.setPosition(sinPan, 0, -cosPan);
  }

  @override
  void setChannelRate(int channel, double rate) {
    if (channel < 0 || channel >= _numChannels) return;
    var ch = _channels[channel];

    if (ch.state == ChannelState.playing) {
      var time = audioContext.currentTime;
      ch
        ..offset = (ch.offset + (time - ch.startTime) * ch.rate) % ch.sound!.buffer.duration
        ..startTime = time;
    }

    ch
      ..rate = rate
      ..sourceNode?.playbackRate.value = rate;
  }

  @override
  int obtainFreeChannel(List<int>? targets) {
    targets ??= _allChannels;
    for (var channel in targets) {
      if (channel >= 0 && channel < _channels.length && _channels[channel].state == ChannelState.stopped) {
        return channel;
      }
    }
    return -1;
  }

  // ---------------------------------------------------------------------------
  // Music
  // ---------------------------------------------------------------------------

  @override
  void playMusic(String path, bool loop, [double loopStart = -1, double loopEnd = -1]) {
    ensureResumed();

    // Stop any existing music
    if (_music != null) {
      _music!.pause();
    }

    _music =
        HTMLAudioElement()
          ..load()
          ..src = path
          ..loop = loop
          ..volume = _musicVolume;

    if (_music!.loop) {
      if (loopStart > -1 && loopEnd > loopStart) {
        // Assume loopStart/loopEnd are already in seconds
        loopEnd = loopEnd - 0.1;

        _music!.onTimeUpdate.listen((_) {
          if (_music!.paused) return;
          if (_music!.currentTime >= loopEnd) {
            _music!.currentTime = loopStart;
          }
        });
      }
    }

    _playPromise = _music!.play().toDart;

    _playPromise!.then(
      (_) {
        _music!.onpause = _onPause.toJS;
      },
      onError: (error) {
        String? errorString = error?.toString();

        if (errorString != null && errorString.startsWith("NotSupportedError")) {
          return;
        }

        bool notAllowedError = false;
        notAllowedError = (errorString != null && errorString.startsWith("NotAllowedError"));
        notAllowedError = notAllowedError || (error.isA<DOMException>() && error.name == "NotAllowedError");

        if (notAllowedError) {
          Future.delayed(Duration(milliseconds: 500), () {
            playMusic(path, loop, loopStart, loopEnd);
          });
        }
      },
    );
  }

  void _onPause(Event e) {
    // Called when music is paused by the browser (e.g. audio device disconnects).
    // The Audio class manages musicState, not us.
  }

  @override
  void stopMusic() {
    _music?.pause();
    _music = null;
    _playPromise = null;
  }

  @override
  void pauseMusic() {
    if (_playPromise != null) {
      _playPromise!
          .then((_) {
            _music?.pause();
            _playPromise = null;
          })
          .catchError((e) {});
    } else {
      _music?.pause();
    }
  }

  @override
  void resumeMusic() {
    if (_music == null) return;
    _playPromise = _music!.play().toDart;
    _playPromise!.catchError((error) {
      // Ignore NotAllowedError
    });
  }

  @override
  double get musicPosition => _music?.currentTime ?? 0.0;

  @override
  double get musicDuration => _music?.duration ?? 0.0;

  @override
  double get musicVolume => _musicVolume;

  @override
  set musicVolume(double v) {
    _musicVolume = v.clamp(0.0, 1.0);
    _music?.volume = _musicVolume;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void suspend() {
    // Pause music
    _music?.pause();

    // Pause all playing channels
    for (var i = 0; i < _channels.length; ++i) {
      var ch = _channels[i];
      if (ch.state == ChannelState.playing) {
        pauseChannel(i);
        ch.state = ChannelState.suspended;
      }
    }
  }

  @override
  void resume() {
    // Resume music
    _music?.play();

    for (var i = 0; i < _channels.length; ++i) {
      var ch = _channels[i];
      if (ch.state == ChannelState.suspended) {
        ch.state = ChannelState.paused;
        resumeChannel(i);
      }
    }
  }

  @override
  void dispose() {
    _music?.pause();
    _music = null;
    audioContext.close();
  }

  // ---------------------------------------------------------------------------
  // Decoding
  // ---------------------------------------------------------------------------

  @override
  Future<AudioBufferHandle> decodeAudio(Uint8List bytes) async {
    final jsBuffer = bytes.buffer.toJS;
    final audioBuffer = await audioContext.decodeAudioData(jsBuffer).toDart;
    return WebAudioBufferHandle(audioBuffer);
  }

  @override
  Future<AudioBufferHandle> decodeAudioFromFile(String path) async {
    // On web, file loading is done via XHR in the Audio/ResourceManager layer.
    // This backend method loads by fetching the URL and decoding.
    final response = await window.fetch(path.toJS).toDart;
    final arrayBuffer = await response.arrayBuffer().toDart;
    final audioBuffer = await audioContext.decodeAudioData(arrayBuffer).toDart;
    return WebAudioBufferHandle(audioBuffer);
  }

  @override
  AudioVisualizerBackend createVisualizer(int fftSize) {
    if (_music == null) {
      return _StubVisualizerBackend(fftSize);
    }
    return WebAudioVisualizerBackend(audioContext, _music!, fftSize);
  }
}

/// No-op visualizer returned when no music is playing.
class _StubVisualizerBackend implements AudioVisualizerBackend {
  final Uint8List _waveformData;
  _StubVisualizerBackend(int fftSize) : _waveformData = Uint8List(fftSize)..fillRange(0, fftSize, 128);
  @override
  bool get isSupported => false;
  @override
  Uint8List updateWaveformData() => _waveformData;
  @override
  int get frequencyBinCount => 0;
  @override
  set fftSize(int size) {}
  @override
  void disconnect() {}
}
