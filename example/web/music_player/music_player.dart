import 'package:bullseye2d/bullseye2d.dart';
import '../common/app.dart';

class MusicPlayerApp extends CommonApp {
  static const String musicFile = "assets/audio/dropThatCat.mp3";
  static const String musicTitle = "Drop That Cat - Jochen Heizmann";
  static const int noOfBands = 160;

  late BitmapFont font;
  late AudioVisualizer visualizer;

  List<double> bands = List.filled(noOfBands, 0.0);

  int counter = 0;

  @override
  onCreate() async {
    font = resources.loadFont("assets/fonts/wireone/WireOne-Regular.ttf", 196);
    visualizer = audio.initMusicVisualizer(1024);
    audio.playMusic(musicFile, true);
  }

  @override
  onUpdate() {}

  @override
  onRender() {
    double avg = bands.average();
    gfx.clear(0.1 + 0.05 * avg, 0.05 + 0.05 * avg, 0.1 + 0.4 * avg, 1);

    counter++;

    // Draw the visualizer
    final waveData = visualizer.updateWavefromData();
    final samplesPerBand = waveData.length ~/ noOfBands;
    final bandPixelWidth = virtualWidth / noOfBands;

    for (var i = 0; i < noOfBands; ++i) {
      double sum = 0.0;
      if (samplesPerBand > 0) {
        final startSampleIndex = i * samplesPerBand;
        for (var j = 0; j < samplesPerBand; ++j) {
          sum += waveData[startSampleIndex + j] - 128;
        }
        sum /= (samplesPerBand * 128.0);
      }

      bands[i] = sum.abs() > bands[i] ? sum.abs() : bands[i] * 0.955;

      final bandX = i * bandPixelWidth;
      final bandHeight = (480.0 * bands[i]).clamp(0.0, virtualHeight.toDouble());
      final bandY = virtualHeight - bandHeight;

      final r = (bands[i] * 4.0).clamp(0.0, 1.0);
      final g = (1.0 - r + 0.5) / 2.0;

      final bandColors = [Color(r, g, 0.0, 1.0), Color(0.0, 1.0, 0.0, 1.0)];
      gfx.drawRect(bandX, bandY, bandPixelWidth - 1.0, bandHeight, colors: bandColors);
    }

    // Draw the music progress bar
    if (audio.musicDuration > 0) {
      final barHeight = 30.0;
      final barMarginX = 150.0;
      final barY = virtualHeight - barHeight - 12.0;
      final barWidth = virtualWidth - barMarginX * 2;
      final padding = 6.0;

      gfx.setColor(0.05, 0.06, 0.2, 0.97);
      gfx.drawRect(barMarginX, barY, barWidth, barHeight);

      final progressFillColors = [Color(0.8, 0.9, 0.8, 1.0), Color(0.3, 0.4, 0.4, 1.0)];

      gfx.drawRect(barMarginX + padding, barY + padding, (barWidth - padding * 2) * audio.musicProgress, barHeight - padding * 2, colors: progressFillColors);
    }

    // Draw the text
    gfx.setColor(0.0, 1.0, 1.0, 1.0);

    String text = musicTitle;

    // Browsers often only can play music after the first user interaction (first click)
    // so meanwhile we will show the user, he should do a click!
    if (audio.musicState == ChannelState.stopped) {
      text = "Click to start music!";
    }

    gfx.drawText(font, text, x: virtualWidth / 2, y: virtualHeight / 4, alignX: 0.5, alignY: 0.5);
  }

}
