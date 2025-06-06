import 'package:bullseye2d/bullseye2d.dart';
import 'dart:js_interop';
import 'package:web/web.dart';

/// {@category Audio}
/// Manages audio playback for sounds and music.
class Audio {
  // TODO: make this configurable
  static const int audioChannelCount = 32;

  DateTime? _suspendedOn;
  Future<void>? _playPromise;
  HTMLAudioElement? _music;

  AudioVisualizer? _musicVisualizer;

  late List<AudioChannel> _channels;
  final List<int> _allChannels = List.generate(audioChannelCount, (index) => index);

  double _musicVolume = 1.0;

  /// The Web Audio API [AudioContext] used for processing and playing sounds.
  AudioContext audioContext;

  /// The current playback state of the music. See [ChannelState].
  var musicState = ChannelState.stopped;

  Audio([AudioContext? context]) : audioContext = context ?? AudioContext() {
    _channels = List.generate(audioChannelCount, (_) => AudioChannel(audioContext), growable: false);
  }

  /// Gets the current playback position of the music in seconds.
  /// Returns 0.0 if no music is loaded.
  double get musicPosition => _music?.currentTime ?? 0.0;

  /// Gets the total duration of the currently loaded music in seconds.
  /// Returns 0.0 if no music is loaded or duration is not available.
  double get musicDuration => _music?.duration ?? 0.0;

  /// Gets the playback progress of the music, from 0.0 (start) to 1.0 (end).
  /// Returns 0.0 if duration is 0 or music is not loaded.
  double get musicProgress => (musicDuration > 0.0) ? musicPosition / musicDuration : 0.0;

  /// Gets the current volume of the music, ranging from 0.0 (silent) to 1.0 (full volume).
  double get musicVolume => _musicVolume;

  /// Sets the music volume.
  ///
  /// The [volume] is clamped between 0.0 (silent) and 1.0 (full volume).
  set musicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _music?.volume = _musicVolume;
  }

  /// Initializes or reconfigures the [AudioVisualizer] for the current music.
  ///
  /// If an [AudioVisualizer] does not exist, a new one is created with the
  /// specified [fftSize]. If it already exists, its `fftSize` is updated.
  /// If music is already loaded, the visualizer is initialized with the music source.
  ///
  /// - [fftSize]: The desired Fast Fourier Transform size for the analyzer. Defaults to 2048.
  ///
  /// Returns the initialized or updated [AudioVisualizer] instance.
  AudioVisualizer initMusicVisualizer([int fftSize = 2048]) {
    if (_musicVisualizer == null) {
      _musicVisualizer = AudioVisualizer(fftSize);
      if (_music != null) {
        _musicVisualizer!.init(_music!, audioContext);
      }
    } else {
      _musicVisualizer!.fftSize = fftSize;
    }

    return _musicVisualizer!;
  }

  /// Plays the given [Sound].
  ///
  /// - [sound]: The [Sound] object to play.
  /// - [channel]: The specific channel ID to play the sound on. If -1 (default),
  ///   an available channel will be chosen automatically from all channels.
  /// - [loop]: Whether the sound should loop. Defaults to `false`.
  /// - [loopStart]: The start time in samples for looping, if [loop] is `true`.
  ///   Converted to seconds internally using the sound's sample rate. Requires [loopEnd] to also be set.
  /// - [loopEnd]: The end time in samples for looping, if [loop] is `true`.
  ///   Converted to seconds internally using the sound's sample rate. Requires [loopStart] to also be set.
  ///
  /// Returns the channel ID on which the sound is playing, or -1 if the sound
  /// could not be played (e.g., sound not ready, retrigger delay not met, or no free channels).
  int playSound(Sound sound, {int channel = -1, bool loop = false, double? loopStart, double? loopEnd}) {
    var targetChannels = (channel == -1) ? _allChannels : [channel];
    return playSoundOnTargetChannels(
      sound,
      targetChannels: targetChannels,
      loop: loop,
      loopStart: loopStart,
      loopEnd: loopEnd,
    );
  }

  /// Plays the given [Sound] on one of the specified target channels.
  ///
  /// - [sound]: The [Sound] object to play.
  /// - [targetChannels]: A list of preferred channel IDs. The sound will be played
  ///   on the first available channel from this list. If `null`, all channels are considered.
  /// - [loop]: Whether the sound should loop. Defaults to `false`.
  /// - [loopStart]: The start time in samples for looping, if [loop] is `true`.
  ///   Converted to seconds internally using the sound's sample rate. Requires [loopEnd] to also be set.
  /// - [loopEnd]: The end time in samples for looping, if [loop] is `true`.
  ///   Converted to seconds internally using the sound's sample rate. Requires [loopStart] to also be set.
  ///
  /// Returns the channel ID on which the sound is playing, or -1 if the sound
  /// could not be played (e.g., sound not ready, retrigger delay not met, or no suitable channel found).
  int playSoundOnTargetChannels(
    Sound sound, {
    List<int>? targetChannels,
    bool loop = false,
    double? loopStart,
    double? loopEnd,
  }) {
    if (audioContext.state == 'suspended') {
      audioContext.resume();
    }

    if (sound.state != LoadingState.ready) {
      return -1;
    }

    if (sound.lastTimePlayed != null) {
      final timeSinceLastPlayed = DateTime.now().difference(sound.lastTimePlayed!);
      if (timeSinceLastPlayed < sound.retriggerDelay) {
        return -1;
      }
    }

    var channelId = obtainFreeChannel(targetChannels);
    if (channelId == -1) {
      warn("All audio channels are in use. Consider to increase channel count.");
      return -1;
    }

    var channel = _channels[channelId];
    if (channel.state != ChannelState.stopped && channel.sourceNode != null) {
      channel.sourceNode!.onended = null;
      try {
        channel
          ..sourceNode!.stop(0)
          ..state = ChannelState.stopped;
      } catch (e) {
        //
      }
    }

    channel
      ..sound = sound
      ..loop = loop
      ..sourceNode = audioContext.createBufferSource()
      ..sourceNode!.buffer = sound.buffer
      ..sourceNode!.playbackRate.value = channel.rate
      ..sourceNode!.loop = loop
      ..sourceNode!.connect(channel.pannerNode);

    if (channel.sourceNode!.loop) {
      if (loopStart != null && loopEnd != null && loopEnd > loopStart) {
        double hz = sound.buffer?.sampleRate ?? 44100;
        loopStart = loopStart / hz;
        loopEnd = loopEnd / hz;
      } else {
        loopStart = 0;
        loopEnd = channel.sourceNode!.buffer!.duration;
      }

      channel.sourceNode!
        ..loopStart = loopStart
        ..loopEnd = loopEnd;
    }

    channel.sourceNode!.onended =
        (Event event) {
          channel
            ..sourceNode = null
            ..state = ChannelState.stopped;
        }.toJS;

    channel
      ..offset = 0
      ..startTime = audioContext.currentTime
      ..sourceNode?.start(0)
      ..state = ChannelState.playing;

    sound.lastTimePlayed = DateTime.now();

    return channelId;
  }

  /// Stops the sound playing on the specified [channelId].
  ///
  /// If the channel is already stopped, this method does nothing.
  /// - [channelId]: The ID of the channel to stop.
  stopChannel(int channelId) {
    var channel = _channels[channelId];
    if (channel.state == ChannelState.stopped) return;

    if (channel.state == ChannelState.playing) {
      channel.sourceNode?.onended = null;
      try {
        channel.sourceNode?.stop(0);
      } catch (e) {
        //ignore errors
      }
      channel.sourceNode = null;
    }
    channel.state = ChannelState.stopped;
  }

  /// Pauses the sound playing on the specified [channelId].
  ///
  /// If the channel is not currently playing, this method does nothing.
  /// The current playback position is saved so it can be resumed later.
  /// - [channelId]: The ID of the channel to pause.
  pauseChannel(int channelId) {
    var channel = _channels[channelId];
    if (channel.state != ChannelState.playing) {
      return;
    }

    channel.offset =
        (channel.offset + (audioContext.currentTime - channel.startTime) * channel.rate) %
        channel.sound!.buffer!.duration;

    channel.sourceNode?.onended = null;
    try {
      channel.sourceNode?.stop(0);
    } catch (e) {
      //
    }
    channel
      ..sourceNode = null
      ..state = ChannelState.paused;
  }

  /// Resumes a paused sound on the specified [channelId].
  ///
  /// If the channel is not paused, this method does nothing.
  /// - [channelId]: The ID of the channel to resume.
  resumeChannel(int channelId) {
    if (audioContext.state == 'suspended') {
      audioContext.resume();
    }
    var channel = _channels[channelId];
    if (channel.state != ChannelState.paused) {
      return;
    }

    channel.sourceNode = audioContext.createBufferSource();

    channel.sourceNode!
      ..buffer = channel.sound!.buffer
      ..playbackRate.value = channel.rate
      ..loop = channel.loop
      ..connect(channel.pannerNode)
      ..onended =
          (Event e) {
            channel.sourceNode = null;
            channel.state = ChannelState.stopped;
          }.toJS;

    channel
      ..startTime = audioContext.currentTime
      ..sourceNode!.start(0, channel.offset)
      ..state = ChannelState.playing;
  }

  /// Sets the volume for the sound on the specified [channelId].
  ///
  /// - [channelId]: The ID of the channel whose volume is to be set.
  /// - [volume]: The desired volume, typically ranging from 0.0 (silent) to 1.0 (full volume).
  ///   This value is applied to the gain node of the channel.
  void setVolume(int channelId, double volume) {
    var channel = _channels[channelId];
    channel
      ..volume = volume
      ..gainNode.gain.value = volume;
  }

  /// Sets the stereo panning for the sound on the specified [channelId].
  ///
  /// - [channelId]: The ID of the channel whose panning is to be set.
  /// - [pan]: The panning value, from -1.0 (full left) to 1.0 (full right).
  ///   0.0 is center. This is mapped to a 3D position for the `PannerNode`
  ///   to achieve stereo panning.
  void setPan(int channelId, double pan) {
    // Calculate sine and cosine components for 3D positioning
    // The 'pan' value is expected to be from -1.0 (full left) to 1.0 (full right).
    // This maps it to an angle from -π/2 radians (-90 degrees) to π/2 radians (90 degrees).
    var sinPan = sin(pan * pi / 2);
    var cosPan = cos(pan * pi / 2);

    _channels[channelId]
      ..pan = pan
      ..pannerNode.setPosition(sinPan, 0, -cosPan);
  }

  /// Sets the playback rate for the sound on the specified [channelId].
  ///
  /// - [channelId]: The ID of the channel whose playback rate is to be set.
  /// - [rate]: The desired playback rate. 1.0 is normal speed.
  ///   0.5 is half speed, 2.0 is double speed.
  ///   If the sound is currently playing, its perceived pitch will also change.
  ///   The current playback position is adjusted to maintain smooth transition if playing.
  void setRate(int channelId, double rate) {
    var channel = _channels[channelId];

    if (channel.state == ChannelState.playing) {
      var time = audioContext.currentTime;
      channel
        ..offset = (channel.offset + (time - channel.startTime) * channel.rate) % channel.sound!.buffer!.duration
        ..startTime = time;
    }

    channel
      ..rate = rate
      ..sourceNode?.playbackRate.value = rate;
  }

  /// Finds and returns the ID of a free (stopped) audio channel.
  ///
  /// - [targetChannels]: An optional list of channel IDs to check. If `null`,
  ///   all channels ([_allChannels]) are checked.
  ///
  /// Returns the ID of a free channel, or -1 if all specified/available channels are in use.
  int obtainFreeChannel(List<int>? targetChannels) {
    targetChannels ??= _allChannels;
    for (var channel in targetChannels) {
      if (channel >= 0 && channel < _channels.length && _channels[channel].state == ChannelState.stopped) {
        return channel;
      }
    }
    return -1;
  }

  /// Loads and plays music from the given [path].
  ///
  /// If music is already playing or paused, it will be stopped/paused and replaced.
  ///
  /// You can play back mp3, ogg and wave files.
  ///
  /// <div class="note warning">
  /// <p><strong>Warning:</strong>On iOS Devices <b>ogg</b> format is not supported.</p>
  /// </div>
  ///
  /// <div class="note">
  /// <p><strong>Info:</strong>
  /// On most browser you can only playback music after the first user interaction.<br/><br/>
  /// In that case, Bullseye2D retries, so as soon as the first user interaction (click)
  /// occurs, playback will be started.
  /// </p>
  /// </div>
  ///
  /// - [path]: The URL or path to the music file.
  /// - [loop]: Whether the music should loop. Defaults to `false`.
  /// - [loopStart]: The start time in samples for looping, if [loop] is `true`.
  ///   Converted to seconds using [hz]. Requires [loopEnd] to also be set.
  ///   NOTE: Music looping might not work reliably if the web server does not
  ///   support `Accept-Ranges` headers (e.g., Dart's development server).
  /// - [loopEnd]: The end time in samples for looping, if [loop] is `true`.
  ///   Converted to seconds using [hz]. Requires [loopStart] to also be set.
  ///   NOTE: Music looping might not work reliably if the web server does not
  ///   support `Accept-Ranges` headers.
  /// - [hz]: The sample rate of the audio (e.g., 44100), used for converting sample-based loop points
  ///   to seconds. Defaults to 44100.
  void playMusic(String path, bool loop, [double loopStart = -1, double loopEnd = -1, hz = 44100]) {
    if (audioContext.state == 'suspended') {
      audioContext.resume();
    }

    if (musicState != ChannelState.stopped) {
      _musicVisualizer?.disconnect();
      _music?.pause();
      musicState = ChannelState.paused;
    }

    _music =
        HTMLAudioElement()
          ..load()
          ..src = path
          ..loop = loop
          ..volume = _musicVolume;

    _musicVisualizer?.init(_music!, audioContext);

    // NOTE: The Dart Development Webs erver doesnt support
    // Accept-Ranges headers for the assets
    // so, music looping/seeking doesnt work.
    // if you want to allow for seeking/looping please use a webserver
    // who suipports accep-range headers
    if (_music!.loop) {
      if (loopStart > -1 && loopEnd > loopStart) {
        loopStart = loopStart / hz.toDouble();
        loopEnd = (loopEnd / hz.toDouble()) - 0.1;

        _music!.onTimeUpdate.listen((_) {
          if (_music!.paused) {
            return;
          }
          if (_music!.currentTime >= loopEnd) {
            _music!.currentTime = loopStart;
          }
        });
      }
    }

    _playPromise = _music!.play().toDart;

    _playPromise!.then(
      (_) {
        musicState = ChannelState.playing;
        _music!.onpause = _onPause.toJS;
      },
      onError: (error) {
        bool notAllowedError = false;

        String? errorString = error?.toString();
        notAllowedError = (errorString != null && errorString.startsWith("NotAllowedError"));
        notAllowedError = notAllowedError || (error.isA<DOMException>() && error.name == "NotAllowedError");

        if (notAllowedError) {
          warn(errorString);
          Future.delayed(Duration(milliseconds: 500), () {
            playMusic(path, loop, loopStart, loopEnd);
          });
        }
      },
    );
  }

  // This is called when the music is paused by the user/browser
  // for example when the audio device disconnects
  void _onPause(Event e) {
    if (musicState == ChannelState.playing) {
      musicState = ChannelState.paused;
    }
  }

  /// Stops the currently playing or paused music.
  ///
  /// If no music is active (playing, paused), this method does nothing.
  /// Disconnects the [AudioVisualizer] if one was active for the music.
  /// Resets music position and clears the loaded music.
  void stopMusic() {
    if (musicState == ChannelState.stopped) {
      return;
    }

    _musicVisualizer?.disconnect();

    _music?.pause();
    _music = null;

    musicState = ChannelState.stopped;

    _playPromise = null;
  }

  /// Pauses the currently playing music.
  ///
  /// If music is not playing, this method does nothing.
  /// The current playback position is maintained.
  void pauseMusic() {
    if (musicState != ChannelState.playing) {
      return;
    }

    if (_playPromise != null) {
      _playPromise!
          .then((_) {
            if (_music != null) {
              _music!.pause();
              musicState = ChannelState.paused;
            }
            _playPromise = null;
          })
          .catchError((e) {});
    } else {
      _music?.pause();
      musicState = ChannelState.paused;
    }
  }

  /// Resumes playback of paused music.
  ///
  /// If music is not paused, this method does nothing.
  /// Handles potential "NotAllowedError" if the browser blocks resuming audio,
  /// in which case the music state might revert to stopped.
  void resumeMusic() {
    if (musicState != ChannelState.paused) {
      return;
    }

    _playPromise = _music!.play().toDart;
    musicState = ChannelState.playing;

    _playPromise!.catchError((error) {
      if (error.isA<DOMException>() && error.name == "NotAllowedError") {
        musicState = ChannelState.stopped;
      }
    });
  }

  /// Suspends all audio playback (music and sounds).
  ///
  /// This is typically called when the application loses focus or becomes inactive.
  /// Playing music is paused. Playing sounds are paused and their state is marked as suspended.
  /// Records the time of suspension to correctly adjust sound retrigger delays upon resume.
  suspend() {
    if (musicState == ChannelState.playing) {
      _music?.pause();
      musicState = ChannelState.suspended;
    }

    for (var i = 0; i < _channels.length; ++i) {
      var channel = _channels[i];
      if (channel.state == ChannelState.playing) {
        pauseChannel(i);
        channel.state == ChannelState.suspended;
      }
    }
    _suspendedOn = DateTime.now();
  }

  /// Resumes all audio playback that was previously suspended.
  ///
  /// This is typically called when the application regains focus or becomes active.
  /// Resumes music that was playing before suspension.
  /// Resumes sounds that were playing before suspension.
  /// Adjusts `lastTimePlayed` for sounds to account for the suspension duration,
  /// maintaining correct retrigger delay logic.
  resume() {
    if (musicState == ChannelState.suspended) {
      _music?.play();
      musicState = ChannelState.playing;
    }

    var timePassed = Duration.zero;

    if (_suspendedOn != null) {
      timePassed = DateTime.now().difference(_suspendedOn!);
    }

    _suspendedOn = null;

    for (var i = 0; i < _channels.length; ++i) {
      var channel = _channels[i];
      if (channel.sound?.lastTimePlayed != null) {
        channel.sound!.lastTimePlayed = channel.sound!.lastTimePlayed!.add(timePassed);
      }
      if (channel.state == ChannelState.suspended) {
        channel.state == ChannelState.paused;
        resumeChannel(i);
      }
    }
  }
}
