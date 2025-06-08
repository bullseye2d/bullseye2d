# Your First Bullseye2D Application

## Prerequisites

Ok, let's create a first simple application. Please make sure you have the Dart SDK and `Bullseye2D` already installed.

<details>
<summary>How to setup Dart SDK and Bullseye2D?</summary>
<content>

## 1. Install Dart SDK

Go to https://dart.dev/get-dart and install the Dart SDK (*Flutter is NOT requried*).

## 2. Activate `webdev`

From your terminal run the following command:
```bash
dart pub global activate webdev
```

## 3. Install `Bullseye2D`

Install the `Bullseye2D` CLI Tool:
```bash
dart pub global activate bullseye2d
```
</content>
</details>

## Create the project
To start a new project, run the following command from within the `bullseye2d` directory:

```bash
bullseye2d create ./hello_world
```

The script will create a new `Bullseye2D` project for you and provides you with some basic template files.

<div class="note">
  <p><strong>Info: </strong>Instead of using the <em>Bullseye2D CLI</em>-Tool you
    can also add bullseye2d to your project.
    Please note, that in this case, you have to create the index.html and canvas element yourself.
  </p>

  ```bash
  dart pub add bullseye2d
  ```
</div>

## Navigate into your new project directory:

```bash
cd ../hello_world
```

## 3. Start the development server
Now you can use `webdev` to run your application. When you work on your project, you can keep `webdev` running. Each time you change a file, it will automatically rebuild your application and refresh your browser.

Run it with:

```bash
webdev serve
```

Now open your browser and go to `http://localhost:8080`. You should see the text "One hundred & eighty!" displayed.

# Understanding the initial files

## web/main.dart

Let's explain some of the files, the project creator created for you.

Your newly created project has a subfolder called `web/`. In that folder the file `main.dart` is located. This is the main entry point of your application. The project creator has created a simple class for you that renders the text you just saw in your Browser.

```dart
import 'package:bullseye2d/bullseye2d.dart';

class HelloWorld extends App {
  late BitmapFont font;

  @override
  onCreate() async {
    font = resources.loadFont("fonts/roboto/Roboto-Regular.ttf", 96);
  }

  @override
  onUpdate() {
  }

  @override
  onRender() {
    gfx.clear(0, 0, 0);
    gfx.drawText(font, "One hundred & eighty!", 
      x: width / 2, 
      y: height / 2, 
      alignX: 0.5, 
      alignY: 0.5
    );
  }
}

main() {
  HelloWorld();
}
```

As you can see, you have to create a class that extends the base [**App**](../topics/App-topic.html) class.

One single import `'package:bullseye2d/bullseye2d.dart'` will import all modules of `Bullseye2D`.

The demo project overrides three methods `onCreate`, `onUpdate`, and `onRender`.

**`onCreate()`** is called once when the app starts. Here, it loads a `BitmapFont`. The  `assets/fonts/roboto/Roboto-Regular.ttf` file was copied by the `create_project.dart` script. The `assets`-folder is a god place to put all your assets in.

**`onUpdate()`** is called every frame for game logic (currently empty).

**`onRender()`** is called every frame for drawing. It clears the screen and draws text.

**`main()`** is the entry point (like in any other `Dart`-Application, which creates an instance of your `HelloWorld` app.

## web/index.html

Lets also have a look at the index.html file created for you:

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bullseye2D - HelloWorld</title>
    <script defer src="main.dart.js"></script>
<style>
<!-- some styles are in here -->
</style>
</head>
<body>
  <div class="container">
    <canvas id="gameCanvas" tabindex=1 width="1280" height="720"></canvas>
  </div>
</body>
</html>
```

The `index.html`-file needs to have a `Canvas Element`. `Bullseye2D` by default looks for id `gameCanvas`, but you can change that to anything you like, as long as you provide the `id` via an [**AppConfig**](../bullseye2d/AppConfig-class.html) object to your application.

Please note the **`tabindex=1`** attribute. It makes the canvas element focusable, which is necessary for it to receive keyboard input. Without it, keyboard events might not be captured by your game.

</content>
</details>

For now, let's rename the canvas in here to `theBigStage`:

```html
  <div class="container">
    <canvas id="theBigStage" tabindex=1 width="1280" height="720"></canvas>
  </div>
```

Then in `main.dart` you need to let your app know which canvas to use:

```dart
main() {
  var myConfig = AppConfig()
    ..canvasElement = 'theBigStage';

  HelloWorld(myConfig);
}
```

