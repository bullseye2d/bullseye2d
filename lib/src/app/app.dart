import 'package:bullseye2d/bullseye2d.dart';
import 'package:bullseye2d/src/backend/backend.dart';
import 'dart:async';

/// {@category App}
/// The base `App` class. Extend from this class to create a `Bullseye2D` application.
///
/// An `App` provides the main structure for a game, handling the game loop,
/// input, rendering, audio, and resource management.
///
/// To create a game, you typically:
/// 1. Extend this `App` class.
/// 2. Override lifecycle methods like [onCreate], [onUpdate], and [onRender].
/// 3. Instantiate your custom `App` class in your `main()` function.
///
/// ```dart
/// class MyGame extends App {
///   @override
///   void onCreate() {
///     // Initialize resources here
///     log('Game created!');
///   }
///
///   @override
///   void onUpdate() {
///     // Game logic updates here
///   }
///
///   @override
///   void onRender() {
///     // Rendering code here
///     gfx.clear(0.1, 0.2, 0.3); // Clear screen with a color
///   }
/// }
///
/// void main() {
///   MyGame();
/// }
/// ```

abstract class App {
  static late App instance;

  late final AppConfig _config;
  late final WindowBackend _windowBackend;
  late final RendererBackend _renderer;
  bool _killApp = false;
  bool _suspended = false;
  double _updateRate = 60.0;
  int _timerSeq = 0;

  // Stuff for the loader
  var _loadCounter = 0;
  var _loadingProgress = 0.0;
  var _smoothFactor = 1.0;

  /// Provides access to the device's accelerometer data.
  ///
  /// Use this to detect device motion and orientation changes.
  late final Accelerometer accel;

  /// Manages audio playback for sounds and music.
  ///
  /// Use this to play sound effects, background music, and manage audio channels.
  late final Audio audio;

  /// Handles gamepad input from connected controllers.
  ///
  /// Use this to query button presses, joystick positions, and trigger states.
  late final Gamepad gamepad;

  /// The main graphics interface for rendering 2D primitives, textures, and text.
  ///
  /// All drawing operations are performed through this object.
  late final Graphics gfx;

  /// Manages keyboard input.
  ///
  /// Use this to check for key presses, holds, and releases, and to read text input.
  late final Keyboard keyboard;

  /// Manages the loading of game assets.
  ///
  /// Tracks the progress of asynchronous resource loading and provides
  /// information about the loading state, which can be used to display
  /// loading screens via the [onLoading] method.
  late final Loader loader;

  /// Manages mouse and touch input.
  ///
  /// Use this to get cursor position, button states, and touch events.
  late final Mouse mouse;

  /// Manages loading and caching of game resources like textures, fonts, and sounds.
  ///
  /// Provides methods to load assets and automatically handles
  /// progress tracking with the [loader].
  late final ResourceManager resources;

  /// The current width of the game window/canvas in pixels.
  ///
  /// This value is updated when the window/canvas resizes. See [onResize].
  int width = 0;

  /// The current height of the game window/canvas in pixels.
  ///
  /// This value is updated when the window/canvas resizes. See [onResize].
  int height = 0;

  /// Creates a new `App` instance.
  ///
  /// - [config]: Optional [AppConfig] to customize application behavior, such as
  ///   the canvas element ID and graphics batch capacity. If `null`, default
  ///   configuration is used.
  ///
  /// The constructor initializes all core systems (graphics, input, audio, resources)
  /// and sets up the game loop. The [onCreate] method is called once initialization
  /// is complete.
  App([AppConfig? config]) {
    instance = this;

    _config = config ??= AppConfig();

    // Create platform backends via the conditional-import factory
    final factory = PlatformFactoryImpl();
    _windowBackend = factory.createWindow(_config);
    Platform.init(_windowBackend);

    loader = Loader();

    // Input backends
    final keyboardBackend = factory.createKeyboard(_windowBackend);
    final mouseBackend = factory.createMouse(_windowBackend);
    final gamepadBackend = factory.createGamepad();
    final accelBackend = factory.createAccelerometer();

    gamepad = Gamepad(gamepadBackend);
    keyboard = Keyboard(keyboardBackend);
    mouse = Mouse(mouseBackend);
    accel = Accelerometer(accelBackend, mouse, config.autoRequestAccelerometerPermission);

    // Audio backend
    final audioBackend = factory.createAudio();
    audio = Audio(audioBackend);

    // Renderer
    _renderer = factory.createRenderer(_windowBackend);
    _renderer.init();
    Texture.white = Texture.createWhite(_renderer);

    gfx = Graphics(
      _renderer,
      batchCapacityInBytes: _config.gfxBatchCapacityInBytes,
      width: _windowBackend.width,
      height: _windowBackend.height,
    );

    // Resource manager with all backends
    final imageLoader = factory.createImageLoader();
    final fileLoader = factory.createFileLoader();
    final fontRasterizer = factory.createFontRasterizer();
    final storageBackend = factory.createStorage();
    initFileBackend(fileLoader);
    LocalStorage.init(storageBackend);
    resources = ResourceManager(_renderer, imageLoader, fileLoader, fontRasterizer, audio, loader);

    _windowBackend.onFocus(() {
      if (!_config.autoSuspend || !_suspended) {
        return;
      }
      _suspended = false;
      audio.resume();
      onResume();
      _validateUpdateTimer();
    });

    _windowBackend.onBlur(() {
      if (!_config.autoSuspend || _suspended) {
        return;
      }
      _suspended = true;
      onSuspend();
      audio.suspend();
      keyboard.suspend();
      mouse.suspend();
      gamepad.suspend();
    });

    _windowBackend.focus();

    updateRate = 60;

    width = _windowBackend.width;
    height = _windowBackend.height;
    gfx.setViewport(0, 0, width, height);
    onCreate();
    onResize(width, height);
    _renderGame();
    _validateUpdateTimer();
  }

  /// Gets the target update rate of the game loop in updates per second (Hz).
  double get updateRate => _updateRate;

  /// Sets the target update rate of the game loop in updates per second (Hz).
  ///
  /// If set to 0 or less, the game will attempt to update as fast as possible,
  /// synchronized with the browser's animation frame.
  set updateRate(double updatesPerSecond) {
    _updateRate = updatesPerSecond;
    _validateUpdateTimer();
  }

  /// The display width of the window/canvas (CSS layout size on web, same as [width] on SDL3).
  int get displayWidth => _windowBackend.displayWidth;

  /// The display height of the window/canvas (CSS layout size on web, same as [height] on SDL3).
  int get displayHeight => _windowBackend.displayHeight;

  /// Sets the rendering surface size.
  ///
  /// On web, this sets the canvas pixel resolution (canvas.width/height).
  /// On SDL3, this resizes the window.
  void setRenderSize(int w, int h) {
    _windowBackend.setSize(w, h);
  }

  /// Shows the mouse cursor.
  void showMouse([Images? images, int frame = 0]) {
    _windowBackend.setCursorVisible(true);
  }

  /// Hides the mouse cursor.
  void hideMouse() {
    _windowBackend.setCursorVisible(false);
  }

  void _validateDeviceWindow() {
    var notify = (_windowBackend.width != width || _windowBackend.height != height);
    width = _windowBackend.width;
    height = _windowBackend.height;

    if (notify) {
      onResize(width, height);
    }
  }

  void _updateGame() {
    if (_killApp) return;

    if (loader.done) {
      gamepad.onBeginFrame();
      onUpdate();
      keyboard.onEndFrame();
      mouse.onEndFrame();
    }
  }

  void _dispose() {
    audio.dispose();
    _renderer.dispose();
    _windowBackend.dispose();
  }

  void _renderGame() {
    if (_killApp) {
      _dispose();
      return;
    }
    _validateDeviceWindow();
    if (loader.done) {
      onRender();
    } else {
      // TODO: Refactor this so we don't have this logic duplicated in _updateGame and here
      gamepad.onBeginFrame();

      loader.loadingSequenceFinished = onLoading() && loader.allItemsFinished;

      keyboard.onEndFrame();
      mouse.onEndFrame();
      if (loader.loadingSequenceFinished) {
        loader.reset();

        gfx.clear(0, 0, 0, 1);
        gfx.flush();
      }
    }

    gfx.flush();
    _renderer.present();
  }

  void _validateUpdateTimer() {
    _timerSeq++;
    if (_suspended) return;

    final int currentSeq = _timerSeq;

    final int maxUpdates = 4;
    final double updateRate = _updateRate;

    if (updateRate <= 0) {
      //updaterate = 0, go as fast as possible
      void animate() {
        if (_killApp) return;
        if (currentSeq != _timerSeq) return;
        if (_suspended) return;
        if (!_windowBackend.pumpEvents()) {
          _killApp = true;
          _dispose();
          return;
        }

        _updateGame();
        if (currentSeq != _timerSeq) return;
        if (_suspended) return;

        _windowBackend.requestAnimationFrame(animate);

        _renderGame();
      }

      _windowBackend.requestAnimationFrame(animate);
      return;
    }

    final double updatePeriod = 1000.0 / updateRate;
    double nextUpdate = 0;

    timeElapsed() {
      if (_killApp) return;
      if (currentSeq != _timerSeq) return;
      if (_suspended) return;
      if (!_windowBackend.pumpEvents()) {
        _killApp = true;
        _dispose();
        return;
      }

      if (nextUpdate == 0) {
        nextUpdate = _windowBackend.now();
      }

      final double now = _windowBackend.now();

      for (int i = 0; i < maxUpdates; ++i) {
        _updateGame();
        if (currentSeq != _timerSeq || _suspended) return;

        nextUpdate += updatePeriod;

        if (nextUpdate > now) {
          final delay = nextUpdate - now;
          Timer(Duration(milliseconds: delay.toInt()), timeElapsed);
          _renderGame();
          return;
        }
      }

      nextUpdate = 0;
      Timer(Duration.zero, timeElapsed);
      _renderGame();
    }

    Timer(Duration.zero, timeElapsed);
  }

  /// Called once when the application is created and initialized.
  ///
  /// Override this method to perform one-time setup tasks, such as:
  /// - Loading initial game assets using [resources].
  /// - Setting up game state.
  /// - Configuring initial graphics settings.
  ///
  /// This method is called before the main game loop starts.
  void onCreate() {}

  /// Called repeatedly by the game loop to update game logic.
  ///
  /// Override this method to implement your game's core logic, such as:
  /// - Handling player input from [keyboard], [mouse], [gamepad], or [accel].
  /// - Updating positions and states of game objects.
  /// - Performing collision detection.
  /// - Managing game flow (e.g., levels, scores).
  ///
  /// The frequency of calls to this method is determined by [updateRate].
  /// This method is only called if `loader.done` is true (i.e., all initial
  /// resources have finished loading, if you don't have set `isEnabled`
  /// property of [loader] to false).
  void onUpdate() {}

  /// Called repeatedly by the game loop to render the game scene.
  ///
  /// Override this method to draw your game's visuals using the [gfx] object.
  /// This includes:
  /// - Clearing the screen.
  /// - Drawing sprites, shapes, text, and other graphical elements.
  ///
  /// This method is called after [onUpdate].
  /// It is only called if `loader.done` is true (if you don't have set `isEnabled`
  /// property of [loader] to false).
  ///
  /// `gfx.flush()` is called automatically at the end of the frame after
  /// `onRender`.
  void onRender() {}

  /// Called when the application is suspended.
  ///
  /// This typically happens when the browser tab or window loses focus,
  /// if `autoSuspend` is enabled in [AppConfig] (which is true by default).
  ///
  /// Override this method to save game state, pause animations, or mute audio
  /// if needed. The base `App` class automatically suspends audio and input systems.
  void onSuspend() {}

  /// Called when the application is resumed after being suspended.
  ///
  /// This typically happens when the browser tab or window regains focus,
  /// if `autoSuspend` was enabled and the app was previously suspended.
  ///
  /// Override this method to restore game state or resume activities that were
  /// paused in [onSuspend]. The base `App` class automatically resumes audio.
  void onResume() {}

  /// This is called as soon as the dimension of the canvas changes. `Bullseye2D`
  /// provides a default implementation that updates the projection matrix, but
  /// you are free to overwrite it, and provide your custom implementation.
  /// - [width]: The new width of the canvas.
  /// - [height]: The new height of the canvas.
  void onResize(int width, int height) {
    gfx.setViewport(0, 0, width, height);
    gfx.set2DProjection(width: width.toDouble(), height: height.toDouble());
  }

  /// Called repeatedly while game assets are loading.
  ///
  /// Everytime an asset is loaded in the background `onLoading` is called
  /// instead of `onUpdate/onRender`.
  //
  /// Bullseye provides a default implementation that shows a progress bar
  /// but you can overwrite this method to provide your custom loader.
  ///
  /// Once all loading is completed the app jumps back to `onUpdate/onRender`
  /// again, when you return `true`here. If you want to delay it or you want
  /// to wait for user input, for example, return false as long as you want
  /// to keep the loader active.
  ///
  /// If you return `true` but the loading is still in progress, your return
  /// value is ignored.
  ///
  /// If you want to disable the dispatching to `onLoading`, you can deactivate
  /// it, by setting `isEnable` of `loader` to `false`:
  ///
  /// loader.isEnabled = false
  ///
  bool onLoading() {
    _loadCounter += 1;
    _smoothFactor = min(12.0, _smoothFactor + 0.25);

    gfx.setColor(0.1, 0.1, 0.2, 1);
    gfx.clear();

    double r = (width / 2.0) * 0.1;
    double circleRadius = r * 0.13;

    double x = width / 2.0;
    double y = height / 2.0 - r / 2;

    for (var i = 0; i < 360; i += 45) {
      gfx.setColor(1, 1, 1, 0.5 + 0.5 * cosDegree(i - _loadCounter * 2));
      double segmentX = x + sinDegree(i + _loadCounter) * r * 0.5;
      double segmentY = y + cosDegree(i + _loadCounter) * r * 0.5;
      gfx.drawCircle(segmentX, segmentY, circleRadius);
    }

    gfx.setColor(0.8, 0.8, 0.8, 0.75 + sinDegree(_loadCounter * 5) * 0.25);

    y += 2 * r;

    _loadingProgress = _loadingProgress + 0.001 + (loader.percent - _loadingProgress) / _smoothFactor;
    _loadingProgress = min(loader.percent, _loadingProgress);
    gfx.drawRect(40, y - 20, _loadingProgress * (width - 80), 12);

    gfx.setColor();

    if (_loadingProgress >= 1.0) {
      _loadCounter = 0;
      return true;
    }

    return false;
  }
}
