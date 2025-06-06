import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart';

/// {@category Audio}
/// The playback state of an [AudioChannel] or music.
enum ChannelState {
  /// The channel is currently not playing any sound and is available.
  stopped,

  /// The channel is actively playing a sound.
  playing,

  /// The channel's playback has been temporarily paused.
  paused,

  /// The channel's playback was suspended (e.g., due to the application losing focus).
  suspended
}

/// @nodoc
class AudioChannel {
  Sound? sound;
  AudioBufferSourceNode? sourceNode;

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
    gainNode = audioContext.createGain()
      ..connect(audioContext.destination);

    pannerNode = audioContext.createPanner()
      ..rolloffFactor = 0
      ..panningModel = 'equalpower'
      ..connect(gainNode);
  }
}

