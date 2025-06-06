import 'package:bullseye2d/bullseye2d.dart';
import 'dart:js_interop';
import 'package:web/web.dart';

/// {@category Audio}
/// The loading status of a [Sound] resource.
enum LoadingState { none, loading, error, ready }

/// {@category Audio}
/// Manages an audio resource, its loading state, and playback properties.
///
/// This class handles loading audio from a file or raw byte data,
/// decoding it using the Web Audio API's [AudioContext], and storing
/// the decoded [AudioBuffer]. It also tracks the [LoadingState].
class Sound {
  /// The current loading state of the sound.
  LoadingState state = LoadingState.none;

  /// The decoded audio data.
  AudioBuffer? buffer;

  /// The [DateTime] when the sound was last played.
  ///
  /// This can be used in conjunction with [retriggerDelay] to prevent
  /// a sound from being played too frequently. It's typically updated
  /// by the audio playback system.
  DateTime? lastTimePlayed;

  /// The minimum [Duration] that must pass before this sound can be played again.
  ///
  /// If a sound is triggered, and the time since [lastTimePlayed] is less than
  /// [retriggerDelay], the new play request might be ignored.
  /// Defaults to [Duration.zero], meaning no retrigger delay.
  var retriggerDelay = Duration.zero;

  /// Asynchronously loads a sound from a file at the given [path].
  ///
  /// This method uses the `bullseye` package's `load` function to fetch
  /// the audio file as an `ArrayBuffer`. Upon successful fetching, it then
  /// calls [loadFromBytes] to decode the audio data.
  ///
  /// - On successful fetch and decode, [state] becomes [LoadingState.ready]
  ///   and [buffer] will contain the decoded audio.
  /// - If fetching the file fails, [state] becomes [LoadingState.error].
  /// - If decoding the fetched data fails, [state] also becomes [LoadingState.error].
  ///
  /// Parameters:
  ///  - [path]: The URL or local path to the audio file.
  ///  - [loadingInfo]: A [Loader] instance (from `bullseye`) to manage and track
  ///    the loading progress and status of the external resource.
  ///  - [audioContext]: The Web Audio API [AudioContext] used to decode the
  ///    audio data.
  loadFromFile(String path, Loader loadingInfo, AudioContext audioContext) {
    load<JSArrayBuffer?>(
      path,
      loadingInfo,
      responseType: "arraybuffer",
      onLoad: (response, complete, error) async {
        var audioBytes = (response as JSArrayBuffer);
        await loadFromBytes(audioBytes, audioContext);
        complete(audioBytes);
      },
      onError: (event) {
        state = LoadingState.error;
      },
    );
  }

  /// Asynchronously decodes audio data from a [JSArrayBuffer] and prepares it for playback.
  ///
  /// This method takes raw audio data (e.g., fetched from a file or network)
  /// and uses the provided [audioContext] to decode it into an [AudioBuffer].
  ///
  /// - On successful decoding, [state] becomes [LoadingState.ready] and
  ///   [buffer] will store the decoded [AudioBuffer].
  /// - If an error occurs during decoding, [state] becomes [LoadingState.error]
  ///   and an error message is logged using `warn`.
  ///
  /// Parameters:
  ///  - [audioData]: The raw audio data as a [JSArrayBuffer] (from `dart:js_interop`).
  ///  - [audioContext]: The Web Audio API [AudioContext] used for decoding.
  ///
  /// Returns a [Future] that completes when decoding is finished.
  loadFromBytes(JSArrayBuffer audioData, AudioContext audioContext) async {
    try {
      buffer = await audioContext.decodeAudioData(audioData).toDart;
      state = LoadingState.ready;
    } catch (error) {
      warn("Error decoding audioData", error);
      state = LoadingState.error;
    }
  }

  /// Releases the audio resources held by this sound and resets its state.
  ///
  /// Sets the [buffer] to `null` and [state] to [LoadingState.none].
  /// This should be called when the sound is no longer needed to free up
  /// memory associated with the decoded audio data.
  dispose() {
    buffer = null;
    state = LoadingState.none;
  }
}
