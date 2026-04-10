import 'dart:ffi';
import 'dart:typed_data';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/backend/sdl3/audio_visualizer.dart';
import 'package:ffi/ffi.dart';
import 'package:sdl3/sdl3.dart';

/// SDL3 audio buffer handle wrapping a MIX_Audio pointer.
class Sdl3AudioBufferHandle implements AudioBufferHandle {
  final Pointer<MixAudio> mixAudio;
  double _duration = 0.0;

  Sdl3AudioBufferHandle(this.mixAudio) {
    final durationFrames = mixGetAudioDuration(mixAudio);
    if (durationFrames > 0) {
      _duration = mixAudioFramesToMs(mixAudio, durationFrames) / 1000.0;
    }
  }

  @override
  double get duration => _duration;

  @override
  void dispose() {
    mixDestroyAudio(mixAudio);
  }
}

/// SDL3_mixer (v3) based implementation of [AudioBackend].
///
/// Uses the new Track/Mixer API: audio is loaded as MIX_Audio objects,
/// played through MIX_Track objects on a MIX_Mixer device.
class Sdl3AudioBackend implements AudioBackend {
  static const int _numChannels = 32;

  late final Pointer<MixMixer> mixer;
  final List<Pointer<MixTrack>> _tracks = [];
  Pointer<MixTrack> _musicTrack = nullptr;
  Pointer<MixAudio> _musicAudio = nullptr;

  double _musicVolume = 1.0;

  @override
  void init() {
    mixInit();

    // Create mixer device for default playback
    mixer = mixCreateMixerDevice(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, nullptr);
    if (mixer == nullptr) {
      throw Exception('Failed to create SDL_mixer device: ${sdlGetError()}');
    }

    // Pre-create tracks for sound channels
    for (int i = 0; i < _numChannels; i++) {
      final track = mixCreateTrack(mixer);
      if (track == nullptr) {
        throw Exception('Failed to create mixer track $i: ${sdlGetError()}');
      }
      _tracks.add(track);
    }

    // Create a dedicated track for music
    _musicTrack = mixCreateTrack(mixer);
    if (_musicTrack == nullptr) {
      throw Exception('Failed to create music track: ${sdlGetError()}');
    }
  }

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
    final nativeBuffer = buffer as Sdl3AudioBufferHandle;

    if (channel < 0) {
      channel = obtainFreeChannel(null);
    }
    if (channel < 0 || channel >= _numChannels) return -1;

    final track = _tracks[channel];

    // Stop any currently playing audio on this track
    mixStopTrack(track, 0);

    // Assign audio to track and play
    mixSetTrackAudio(track, nativeBuffer.mixAudio);
    mixSetTrackGain(track, volume);
    mixSetTrackLoops(track, loop ? -1 : 0);

    if (rate != 1.0) {
      mixSetTrackFrequencyRatio(track, rate);
    }

    if (pan != 0.0) {
      // Convert pan (-1.0 to 1.0) to stereo gains
      final left = (1.0 - pan).clamp(0.0, 1.0);
      final right = (1.0 + pan).clamp(0.0, 1.0);
      final gains = calloc<MixStereoGains>();
      gains.ref
        ..left = left
        ..right = right;
      mixSetTrackStereo(track, gains);
      calloc.free(gains);
    }

    mixPlayTrack(track, 0);
    return channel;
  }

  @override
  void stopChannel(int channel) {
    if (channel < 0 || channel >= _numChannels) return;
    mixStopTrack(_tracks[channel], 0);
  }

  @override
  void pauseChannel(int channel) {
    if (channel < 0 || channel >= _numChannels) return;
    mixPauseTrack(_tracks[channel]);
  }

  @override
  void resumeChannel(int channel) {
    if (channel < 0 || channel >= _numChannels) return;
    mixResumeTrack(_tracks[channel]);
  }

  @override
  void setChannelVolume(int channel, double volume) {
    if (channel < 0 || channel >= _numChannels) return;
    mixSetTrackGain(_tracks[channel], volume.clamp(0.0, 1.0));
  }

  @override
  void setChannelPan(int channel, double pan) {
    if (channel < 0 || channel >= _numChannels) return;
    final left = (1.0 - pan).clamp(0.0, 1.0);
    final right = (1.0 + pan).clamp(0.0, 1.0);
    final gains = calloc<MixStereoGains>();
    gains.ref
      ..left = left
      ..right = right;
    mixSetTrackStereo(_tracks[channel], gains);
    calloc.free(gains);
  }

  @override
  void setChannelRate(int channel, double rate) {
    if (channel < 0 || channel >= _numChannels) return;
    mixSetTrackFrequencyRatio(_tracks[channel], rate);
  }

  @override
  int obtainFreeChannel(List<int>? targets) {
    final searchList = targets ?? List.generate(_numChannels, (i) => i);
    for (final ch in searchList) {
      if (ch >= 0 && ch < _numChannels && !mixTrackPlaying(_tracks[ch])) {
        return ch;
      }
    }
    return -1;
  }

  @override
  void playMusic(String path, bool loop, [double loopStart = -1, double loopEnd = -1]) {
    stopMusic();

    final audio = mixLoadAudio(mixer, path, true);
    if (audio == nullptr) return;

    _musicAudio = audio;
    mixSetTrackAudio(_musicTrack, audio);
    mixSetTrackGain(_musicTrack, _musicVolume);
    mixSetTrackLoops(_musicTrack, loop ? -1 : 0);
    mixPlayTrack(_musicTrack, 0);
  }

  @override
  void stopMusic() {
    mixStopTrack(_musicTrack, 0);
    if (_musicAudio != nullptr) {
      mixDestroyAudio(_musicAudio);
      _musicAudio = nullptr;
    }
  }

  @override
  void pauseMusic() {
    mixPauseTrack(_musicTrack);
  }

  @override
  void resumeMusic() {
    mixResumeTrack(_musicTrack);
  }

  @override
  double get musicPosition {
    final frames = mixGetTrackPlaybackPosition(_musicTrack);
    if (frames <= 0) return 0.0;
    return mixTrackFramesToMs(_musicTrack, frames) / 1000.0;
  }

  @override
  double get musicDuration {
    if (_musicAudio == nullptr) return 0.0;
    final frames = mixGetAudioDuration(_musicAudio);
    if (frames <= 0) return 0.0;
    return mixAudioFramesToMs(_musicAudio, frames) / 1000.0;
  }

  @override
  double get musicVolume => _musicVolume;

  @override
  set musicVolume(double v) {
    _musicVolume = v.clamp(0.0, 1.0);
    mixSetTrackGain(_musicTrack, _musicVolume);
  }

  @override
  void suspend() {
    mixPauseAllTracks(mixer);
  }

  @override
  void resume() {
    mixResumeAllTracks(mixer);
  }

  @override
  void dispose() {
    // Stop and destroy all tracks
    for (final track in _tracks) {
      mixStopTrack(track, 0);
      mixDestroyTrack(track);
    }
    _tracks.clear();

    if (_musicTrack != nullptr) {
      mixStopTrack(_musicTrack, 0);
      mixDestroyTrack(_musicTrack);
      _musicTrack = nullptr;
    }
    if (_musicAudio != nullptr) {
      mixDestroyAudio(_musicAudio);
      _musicAudio = nullptr;
    }

    mixDestroyMixer(mixer);
    mixQuit();
  }

  @override
  Future<AudioBufferHandle> decodeAudio(Uint8List bytes) async {
    // Create IOStream from memory, load audio
    final nativeBytes = calloc<Uint8>(bytes.length);
    nativeBytes.asTypedList(bytes.length).setAll(0, bytes);

    final io = sdlIoFromConstMem(nativeBytes.cast(), bytes.length);
    if (io == nullptr) {
      calloc.free(nativeBytes);
      throw Exception('Failed to create IOStream from memory: ${sdlGetError()}');
    }

    final audio = mixLoadAudioIo(mixer, io, true, true);
    calloc.free(nativeBytes);

    if (audio == nullptr) {
      throw Exception('Failed to decode audio: ${sdlGetError()}');
    }

    return Sdl3AudioBufferHandle(audio);
  }

  @override
  Future<AudioBufferHandle> decodeAudioFromFile(String path) async {
    final audio = mixLoadAudio(mixer, path, true);
    if (audio == nullptr) {
      throw Exception('Failed to load audio from file: $path - ${sdlGetError()}');
    }
    return Sdl3AudioBufferHandle(audio);
  }

  @override
  AudioVisualizerBackend createVisualizer(int fftSize) {
    return Sdl3AudioVisualizerBackend(fftSize);
  }
}
