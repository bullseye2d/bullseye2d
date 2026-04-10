# Audio Module

The audio module contains functions for playing sounds and music. You can access it via `app.audio`.

It uses a fixed 32 channel model which allows you to play sounds through any of the preset audio channels.

You can dynamically alter the volume, pan and pitch of a channel.

For larger audio files you can use the **music**-commands to stream music in the background.

The Audio Module supports `mp3`, `ogg` and `wav` files.

<div class="note warning">
  <p><strong>Warning:</strong>On iOS Devices <b>ogg</b> format is not supported.</p>
</div>

## Loading Sounds

You can use the [loadSound](../bullseye2d/ResourceManager/loadSound.html) method of [ResourceManager](../bullseye2d/ResourceManager/ResourceManager.html) to load sounds.

Sounds are loaded asynchronous. During loading the App's [onLoading](../bullseye2d/App/onLoading.html) method gets called instead of [onUpdate](../bullseye2d/App/onUpdate.html) and [onRender](../bullseye2d/App/onRender.html) (if [loader.isEnabled](../bullseye2d/Loader/isEnabled.html) is set to `true`, which is the default).

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
- [audio.playSound](../bullseye2d/Audio/playSound.html):
  - If `channel = -1` (default): Plays on any available channel.
  - Returns the channel ID it's playing on, or -1 if failed.
- [audio.playSoundOnTargetChannels](../bullseye2d/Audio/playSoundOnTargetChannels.html): Tries to play on one of the specified channels. This is useful if you want to create specific group for differen types of sound effects.

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
  **Note (web):** Music looping with `loopStart`/`loopEnd` might not work and depends on server support for `Accept-Ranges` headers (Dart's dev server might not fully support this for precise seeking needed for custom loops). Simple `loop: true` for the whole track usually works.
- `audio.musicVolume` (getter/setter, `0.0` to `1.0`)
- `audio.musicPosition` (getter, current time in seconds)
- `audio.musicDuration` (getter, total time in seconds)
- `audio.musicProgress` (getter, `0.0` to `1.0`)
- `audio.stopMusic()`, `audio.pauseMusic()`, `audio.resumeMusic()`
- `audio.musicState` (`ChannelState.playing`, `ChannelState.paused`, etc.)

<div class="note">
  <p><strong>Info:</strong>
   On web, most browsers require user interaction before audio can play.<br/><br/>
    Bullseye2D retries automatically, so playback will start as soon as the user interacts with the page.
  </p>
</div>

```dart
audio.musicVolume = 0.7;
audio.playMusic("assets/audio/background_music.ogg", true);
```

# Audio Visualizer

The `AudioVisualizer` captures waveform data from the currently playing music. It works on both web and SDL3.

```dart
// Initialize the visualizer (typically in onCreate)
AudioVisualizer visualizer = audio.initMusicVisualizer(1024); // FFT size

// In your render loop, get the waveform data
Uint8List waveformData = visualizer.updateWavefromData();

// waveformData contains values 0-255, centered at 128
// Use it to draw visualizations (bars, waves, etc.)
for (int i = 0; i < waveformData.length; i++) {
  double amplitude = (waveformData[i] - 128) / 128.0; // -1.0 to 1.0
  // ... draw based on amplitude ...
}
```

On web, the visualizer uses the Web Audio API's `AnalyserNode`. SDL3 Implementation is missing at the moment, as we need to explore if we/how can use FFI from an Audio Thread.

The `App` class handles suspending/resuming audio when the window loses/gains focus (`autoSuspend` property, true by default).
