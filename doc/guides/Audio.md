# Audio Module

The audio module contains functions for playing sounds and music. You can access it via `app.audio`.

It uses a fixed 32 channel model which allows you to play sounds trough any of the preset audio channels. **NOTE: It is planned to configure to number of audio channels via [AppConfig](../bullseye/AppConfig-class.html) in the future.**

You can dynamically alter the volume, pan and pitch of a channel.

For larger audio files you can use the **music**-commands to stream music in the background.

The Audio Module supports `mp3`, `ogg` and `wav` files.

<div class="note warning">
  <p><strong>Warning:</strong>On iOS Devices <b>ogg</b> format is not supported.</p>
</div>

## Loading Sounds

You can use the [loadSound](../bullseye/ResourceManager/loadSound.html) method of [ResourceManager](..//bullseye/ResourceManager/ResourceManager.html) to load sounds.

Sounds are loaded asynchronous. During loading the App's [onLoading](../bullseye/App/onLoading.html) method gets called instead of [onUpdate](../bullseye/App/onUpdate.html) and [onRender](../bullseye/App/onRender.html) (if [loader.isEnabled](../bullseye/Loader/isEnabled.html) is set to `true`, which is the default).

```dart
late Sound shootSfx;
shootSfx = resources.loadSound(
  "assets/audio/shoot.wav",
  // optional: If you want to prevent the sound to be played multiple times
  // in a give time range, please specify it with retriggerDelayInMs
  retriggerDelayInMs: 100
);
```

## Playing Sounds

Sounds are played on `channels`.
- [audio.playSound](../bullseye/Audio/playSound.html):
  - If `channel = -1` (default): Plays on any available channel.
  - Returns the channel ID it's playing on, or -1 if failed.
- [audio.playSoundOnTargetChannels](../bullseye/Audio/playSoundOnTargetChannels.html): Tries to play on one of the specified channels. This is useful if you want to create specific group for differen types of sound effects.

```dart
if (keyboard.keyHit(KeyCodes.Space)) {
  // Calling playSound without arguments it tries to obtain a free
  // channel automatically and plays on that one. You can also
  // force it to a channel. If that channel is already in use it
  // will automatically stop that sound and start to play the new
  // sound.
  int playedChannel = audio.playSound(shootSfx);    
  if (playedChannel != -1) {
    log("Played shoot SFX on channel $playedChannel");
  }
}
```

## Looping Sounds
Set `loop: true` in `playSound()`.
- `loopStart`, `loopEnd`: Define a sub-section of the sound to loop. These are in **samples**. 
  ```dart
  // Loop a 1-second segment starting at 0.5 seconds, assuming 44100Hz
  audio.playSound(myLoopSfx, loop: true,
    loopStart: 0.5 * 44100,
    loopEnd: 1.5 * 44100
  );
  ```

## Altering Sounds
  ```dart
  // Change the volume of a channel (This can be called during
  // a channel is played back or to prepare a channel
  audio.setVolume(playedChannel, 0.5);

  // Change the Pitch Rate / Playback speed of a channel
  audio.setRate(playedChannel, 1.5); // Play 50% faster and higher pitch

  // Set the panning of the channel
  // -1.0 is left
  // 0.0 is centered
  // 1.0 is right
  audio.setPan(playedChannel, -0.8); // Pan mostly to the left

  // Pause a channel
  audio.pauseChannel(playedChannel);

  // Resume a paused channel
  audio.resumeChannel(playedChannel);

  // Stop playback on channel completly
  audio.stopChannel(playedChannel);
  ```

# Playing Music

Music is typically longer, and thus is streamed.

- `audio.playMusic`:
  - `loopStart`/`loopEnd` for music are also in samples and depend on `hz` (sample rate).
  **Note:** Music looping with `loopStart`/`loopEnd` might not work and depends on server support for `Accept-Ranges` headers (Dart's dev server might not fully support this for precise seeking needed for custom loops). Simple `loop: true` for the whole track usually works.
- `audio.musicVolume` (getter/setter, `0.0` to `1.0`)
- `audio.musicPosition` (getter, current time in seconds)
- `audio.musicDuration` (getter, total time in seconds)
- `audio.musicProgress` (getter, `0.0` to `1.0`)
- `audio.stopMusic()`, `audio.pauseMusic()`, `audio.resumeMusic()`
- `audio.musicState` (`ChannelState.playing`, `ChannelState.paused`, etc.)

<div class="note">
  <p><strong>Info:</strong>
   On most browser you can only playback music after the first user interaction.<br/><br/>
    In that case, Bullseye2D retries, so as soon as the first user interaction (click)
     occurs, playback will be started.
  </p>
</div>

```dart
audio.musicVolume = 0.7;
audio.playMusic("assets/audio/background_music.ogg", true);

// Music visualizer (optional)
AudioVisualizer visualizer = audio.initMusicVisualizer(1024); // FFT size

// In you update/render loop
Uint8List waveformData = visualizer.updateWavefromData();

// ... draw waveformData ...
// }
```

The Web Audio API requires user interaction first to start playing audio in some browsers. 

Bullseye2D attempts to resume the audio context automatically. The `App` class also handles suspending/resuming audio when the browser tab loses/gains focus (`autoSuspend` property, true by default).
