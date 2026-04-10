# Your First Bullseye2D Application

## Prerequisites

Ok, let's create a first simple application. Please make sure you have the Dart SDK and `Bullseye2D` already installed.

<details>
<summary>How to setup Dart SDK and Bullseye2D?</summary>
<content>

## 1. Install Dart SDK

Go to https://dart.dev/get-dart and install the Dart SDK (*Flutter is NOT requried*).

## 2. Install `Bullseye2D`

Install the `Bullseye2D` CLI Tool:
```bash
dart pub global activate bullseye2d
```

</content>
</details>

## Create the project
To start a new project, run the following command:

```bash
bullseye2d create ./hello_world
```

The script creates a new project with template files.

<div class="note">
  <p><strong>Info: </strong>Instead of using the <em>Bullseye2D CLI</em>-Tool you
    can also add bullseye2d to your project manually.
    Note that in that case, you'll need to create the HTML and canvas element yourself for web.
  </p>

  ```bash
  dart pub add bullseye2d
  ```
</div>

## Navigate into your project directory:

```bash
cd ./hello_world
```

## Run your game

You can run on either platform:

```bash
# Web (opens in browser at http://localhost:8080)
bullseye2d run web

# SDL3 (opens a desktop window)
bullseye2d run sdl3
```

You should see the text "One hundred & eighty!" displayed.

# Understanding the project files

## lib/game.dart

This is your shared game code. Both web and SDL3 entry points import this file.

```dart
import 'package:bullseye2d/bullseye2d.dart';

class HelloWorld extends App {
  late BitmapFont font;

  HelloWorld([AppConfig? config]) : super(config);

  @override
  void onCreate() {
    font = resources.loadFont("assets/fonts/roboto/Roboto-Regular.ttf", 96);
  }

  @override
  void onUpdate() {}

  @override
  void onRender() {
    gfx.clear(0, 0, 0);
    gfx.drawText(font, "One hundred & eighty!",
      x: width / 2,
      y: height / 2,
      alignX: 0.5,
      alignY: 0.5
    );
  }
}
```

Your game class extends the base [**App**](../topics/App-topic.html) class. A single import `'package:bullseye2d/bullseye2d.dart'` gives you access to all modules.

The constructor accepts an optional `AppConfig` so each entry point can configure the app differently (e.g., SDL3 sets a window title and size).

**`onCreate()`** is called once when the app starts. Here, it loads a `BitmapFont` from the shared `assets/` directory.

**`onUpdate()`** is called every frame for game logic (currently empty).

**`onRender()`** is called every frame for drawing. It clears the screen and draws centered text.

## web/main.dart

The web entry point -- simply imports and instantiates your game:

```dart
import 'package:hello_world/game.dart';

void main() {
  HelloWorld();
}
```

## bin/main.dart

The SDL3 entry point. The same thing, but with window configuration:

```dart
import 'package:hello_world/game.dart';
import 'package:bullseye2d/bullseye2d.dart';

void main() {
  HelloWorld(AppConfig(
    title: 'HelloWorld',
    width: 1280,
    height: 720,
  ));
}
```

## web/index.html

The HTML page for the web version:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Bullseye2D - HelloWorld</title>
    <script defer src="main.dart.js"></script>
</head>
<body>
  <div class="container">
    <canvas id="gameCanvas" tabindex=1 width="1280" height="720"></canvas>
  </div>
</body>
</html>
```

The `index.html` needs a `Canvas Element`. Bullseye2D looks for id `gameCanvas` by default, but you can change it via `AppConfig`:

```dart
var myConfig = AppConfig()
  ..canvasElement = 'theBigStage';

HelloWorld(myConfig);
```

Note the **`tabindex=1`** attribute -- it makes the canvas focusable so it can receive keyboard input.

## assets/

The `assets/` directory at the project root is where all your game assets go (images, fonts, sounds). It's shared between web and SDL3:

- **Web**: A symlink `web/assets -> ../assets` makes them accessible to webdev
- **SDL3**: `Sdl3FileBackend` resolves paths relative to the working directory (during development) or the executable location (for compiled builds)

Use `assets/` as a prefix in your code:
```dart
resources.loadFont("assets/fonts/roboto/Roboto-Regular.ttf", 96);
resources.loadImage("assets/player.png");
resources.loadSound("assets/audio/shoot.wav");
```
