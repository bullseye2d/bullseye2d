import 'package:bullseye2d/src/audio/audio_visualizer.dart';
import 'package:bullseye2d/src/audio/sound.dart';
import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/loader.dart';
import 'package:bullseye2d/src/util/debug.dart';

/// {@category Audio}
/// The playback state of an audio channel or music.
enum ChannelState {
  /// The channel is currently not playing any sound and is available.
  stopped,

  /// The channel is actively playing a sound.
  playing,

  /// The channel's playback has been temporarily paused.
  paused,

  /// The channel's playback was suspended (e.g., due to the application losing focus).
  suspended,
}

/// {@category Audio}
/// Manages audio playback for sounds and music.
class Audio {
  static const int audioChannelCount = 32;

  final AudioBackend _backend;
  final List<Sound?> _channelSounds = List.filled(32, null);
  final List<int> _allChannels = List.generate(audioChannelCount, (index) => index);
  AudioVisualizer? _musicVisualizer;

  double _musicVolume = 1.0;

  /// The current playback state of the music. See [ChannelState].
  var musicState = ChannelState.stopped;

  Audio(AudioBackend backend) : _backend = backend;

  /// Gets the current playback position of the music in seconds.
  double get musicPosition => _backend.musicPosition;

  /// Gets the total duration of the currently loaded music in seconds.
  double get musicDuration => _backend.musicDuration;

  /// Gets the playback progress of the music, from 0.0 (start) to 1.0 (end).
  double get musicProgress => (musicDuration > 0.0) ? musicPosition / musicDuration : 0.0;

  /// Gets the current volume of the music, ranging from 0.0 (silent) to 1.0 (full volume).
  double get musicVolume => _musicVolume;

  /// Sets the music volume. Clamped between 0.0 and 1.0.
  set musicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _backend.musicVolume = _musicVolume;
  }

  /// Initializes or reconfigures the [AudioVisualizer] for the current music.
  AudioVisualizer initMusicVisualizer([int fftSize = 2048]) {
    _musicVisualizer?.disconnect();
    final visualizer = AudioVisualizer(fftSize);
    visualizer.initFromBackend(_backend);
    _musicVisualizer = visualizer;
    return visualizer;
  }

  void dispose() {
    _musicVisualizer?.disconnect();
    _musicVisualizer = null;
    _backend.dispose();
  }

  /// Plays the given [Sound].
  ///
  /// Returns the channel ID on which the sound is playing, or -1 if it could not be played.
  int playSound(Sound sound, {int channel = -1, bool loop = false, double? loopStart, double? loopEnd}) {
    var targetChannels = (channel == -1) ? _allChannels : [channel];
    return playSoundOnTargetChannels(sound, targetChannels: targetChannels, loop: loop, loopStart: loopStart, loopEnd: loopEnd);
  }

  /// Plays the given [Sound] on one of the specified target channels.
  int playSoundOnTargetChannels(Sound sound, {List<int>? targetChannels, bool loop = false, double? loopStart, double? loopEnd}) {
    if (sound.state != LoadingState.ready || sound.bufferHandle == null) return -1;

    if (sound.lastTimePlayed != null) {
      final timeSinceLastPlayed = DateTime.now().difference(sound.lastTimePlayed!);
      if (timeSinceLastPlayed < sound.retriggerDelay) return -1;
    }

    var channelId = _backend.obtainFreeChannel(targetChannels);
    if (channelId == -1) {
      warn("All audio channels are in use. Consider to increase channel count.");
      return -1;
    }

    _backend.playSound(
      sound.bufferHandle!,
      channel: channelId,
      loop: loop,
      loopStart: loopStart ?? -1,
      loopEnd: loopEnd ?? -1,
    );

    _channelSounds[channelId] = sound;
    sound.lastTimePlayed = DateTime.now();
    return channelId;
  }

  /// Stops the sound playing on the specified [channelId].
  void stopChannel(int channelId) {
    _backend.stopChannel(channelId);
  }

  /// Pauses the sound playing on the specified [channelId].
  void pauseChannel(int channelId) {
    _backend.pauseChannel(channelId);
  }

  /// Resumes a paused sound on the specified [channelId].
  void resumeChannel(int channelId) {
    _backend.resumeChannel(channelId);
  }

  /// Sets the volume for the sound on the specified [channelId].
  void setVolume(int channelId, double volume) {
    _backend.setChannelVolume(channelId, volume);
  }

  /// Sets the stereo panning for the sound on the specified [channelId].
  void setPan(int channelId, double pan) {
    _backend.setChannelPan(channelId, pan);
  }

  /// Sets the playback rate for the sound on the specified [channelId].
  void setRate(int channelId, double rate) {
    _backend.setChannelRate(channelId, rate);
  }

  /// Finds and returns the ID of a free (stopped) audio channel.
  int obtainFreeChannel(List<int>? targetChannels) {
    return _backend.obtainFreeChannel(targetChannels);
  }

  /// Loads and plays music from the given [path].
  void playMusic(String path, bool loop, [double loopStart = -1, double loopEnd = -1]) {
    _backend.playMusic(path, loop, loopStart, loopEnd);
    musicState = ChannelState.playing;
  }

  /// Stops the currently playing or paused music.
  void stopMusic() {
    _backend.stopMusic();
    musicState = ChannelState.stopped;
  }

  /// Pauses the currently playing music.
  void pauseMusic() {
    _backend.pauseMusic();
    musicState = ChannelState.paused;
  }

  /// Resumes playback of paused music.
  void resumeMusic() {
    _backend.resumeMusic();
    musicState = ChannelState.playing;
  }

  /// Suspends all audio playback (music and sounds).
  void suspend() {
    if (musicState == ChannelState.playing) {
      musicState = ChannelState.suspended;
    }
    _backend.suspend();
  }

  /// Resumes all audio playback that was previously suspended.
  void resume() {
    if (musicState == ChannelState.suspended) {
      musicState = ChannelState.playing;
    }
    _backend.resume();
  }

  /// Loads a sound from a file and tracks loading progress.
  void loadSoundFromFile(Sound sound, String path, Loader loadingInfo) {
    var loadingState = loadingInfo.add(path);
    _backend.decodeAudioFromFile(path).then((handle) {
      sound.bufferHandle = handle;
      sound.state = LoadingState.ready;
      loadingState.completedOrFailed = true;
    }).catchError((e) {
      warn("Error loading sound: $path", e);
      sound.state = LoadingState.error;
      loadingState.completedOrFailed = true;
    });
  }
}
