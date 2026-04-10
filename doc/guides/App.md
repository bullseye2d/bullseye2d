
# App Architecture

The core of a Bullseye2D application is a class that extends `App`.

```dart
import 'package:bullseye2d/bullseye2d.dart';

class MyGame extends App {
  MyGame([AppConfig? config]) : super(config);

  @override
  void onCreate() {
    // Called once when the app starts. Initialize resources here.
  }

  @override
  bool onLoading() {
    // Called while assets are loading (instead of onUpdate/onRender).
    // Bullseye provides a default progress bar implementation.
    // Return true when you're ready to proceed to the game.
    // Return false to keep the loading screen active (e.g., wait for user input).
    // If loading is still in progress, your return value is ignored.
    //
    // To disable the loading screen: loader.isEnabled = false
    return true;
  }

  @override
  void onUpdate() {
    // Called at the configured updateRate (default: 60 times per second).
    // Set updateRate = 0 to run as fast as possible.
    // Handle input and game logic here.
  }

  @override
  void onRender() {
    // Called each frame for rendering. gfx.flush() is called automatically after.
    // NOTE: Input state is invalid in onRender! Use onUpdate for input.
  }

  @override
  void onResize(int width, int height) {
    // Called when the window/canvas size changes.
    // Default implementation sets viewport and 2D projection.
    // Override for custom behavior (e.g., virtual resolution).
  }

  @override
  void onSuspend() {
    // Called when the app loses focus (browser tab hidden, or window minimized).
    // Audio and input are automatically suspended.
  }

  @override
  void onResume() {
    // Called when the app regains focus.
    // Audio is automatically resumed.
  }
}
```

## Entry points

Your game class is shared between web and SDL3. Each platform has its own entry point:

**Web** (`web/main.dart`):
```dart
import 'package:my_game/game.dart';

void main() {
  MyGame();
}
```

**SDL3** (`bin/main.dart`):
```dart
import 'package:my_game/game.dart';
import 'package:bullseye2d/bullseye2d.dart';

void main() {
  MyGame(AppConfig(
    title: 'My Game',
    width: 1280,
    height: 720,
  ));
}
```

## Configure your app

You can provide an [AppConfig](../bullseye2d/AppConfig-class.html) object when constructing your app.

```dart
AppConfig config = AppConfig(
  // --- Web-specific ---

  // CSS selector for the canvas element (web only, default: "#gameCanvas")
  canvasElement: "#gameCanvas",

  // --- SDL3-specific ---

  // Window title (SDL3 only)
  title: 'My Game',

  // Initial window size (SDL3 only)
  width: 1280,
  height: 720,

  // Allow the user to resize the window (SDL3 only)
  resizable: true,

  // Start in fullscreen mode (SDL3 only)
  fullscreen: false,

  // --- Shared ---

  // Increase batch buffer if you get "batch full" warnings
  gfxBatchCapacityInBytes: 65536,

  // Keep the app running when it loses focus (default: true = auto-suspend)
  autoSuspend: false,
);

MyGame(config);
```

For all possible configuration values, have a look at the [AppConfig](../bullseye2d/AppConfig-class.html) class.

## Virtual resolution

To render at a fixed virtual resolution regardless of window size, override `onResize`:

```dart
int virtualWidth = 1920;
int virtualHeight = 1080;

@override
void onResize(int width, int height) {
  gfx.setViewport(0, 0, width, height);
  gfx.set2DProjection(width: virtualWidth.toDouble(), height: virtualHeight.toDouble());
}
```

This works identically on web and SDL3.

## All core features at your fingertips

The `App` class provides access to all core engine features:

*   `gfx`: The `Graphics API` of the [**Graphics Module**](Graphics-topic.html).
*   `keyboard`: The `Keyboard API` of the [**Input Module**](Input-topic.html).
*   `mouse`: The `Mouse API` of the [**Input Module**](Input-topic.html).
*   `accel`: The `Accelerometer API` of the [**Input Module**](Input-topic.html).
*   `gamepad`: The `Gamepad API` of the [**Input Module**](Input-topic.html).
*   `audio`: The `Audio API` to play music and sound (see [**Audio Module**](Audio-topic.html))
*   `resources`: The `ResourceManager` for easy asset loading (see [**IO Module**](IO-topic.html))
*   `loader`: The `Loader` to retrieve information about the loading state of the app.
