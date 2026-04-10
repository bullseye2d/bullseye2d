import 'package:bullseye2d/src/backend/backend.dart';

/// {@category Audio}
/// The loading status of a [Sound] resource.
enum LoadingState { none, loading, error, ready }

/// {@category Audio}
/// Manages an audio resource, its loading state, and playback properties.
class Sound {
  /// The current loading state of the sound.
  LoadingState state = LoadingState.none;

  /// The decoded audio buffer (opaque, platform-specific).
  AudioBufferHandle? bufferHandle;

  /// The [DateTime] when the sound was last played.
  DateTime? lastTimePlayed;

  /// The minimum [Duration] that must pass before this sound can be played again.
  var retriggerDelay = Duration.zero;

  /// Releases the audio resources held by this sound and resets its state.
  dispose() {
    bufferHandle?.dispose();
    bufferHandle = null;
    state = LoadingState.none;
  }
}
