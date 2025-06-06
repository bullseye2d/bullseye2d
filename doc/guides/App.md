
# App Architecture

The core of a Bullseye2D application is a class that extends `App`.

```dart
import 'package:bullseye2d/bullseye2d.dart';

class MyGame extends App {
  @override
  void onCreate() {
    // This method is called when the app is created. You can use this to
    // initialize stuff or loading resources...
  }

  @override
  bool onLoading() {
    // Everytime an asset is loaded in the background `onLoading` is called
    // instead of `onUpdate/onRender`.
    //
    // Bullseye provides a default implementation that shows a progress bar
    // but you can overwrite this method to provide your custom loader.
    //
    // Once all loading is completed the app jumps back to `onUpdate/onRender`
    // again, when you return `true`here. If you want to delay it or you want
    // to wait for user input, for example, return false as long as you want
    // to keep the loader active.
    //
    // If you return `true` but the loading is still in progress, your return
    // value is ignored.
    //
    // If you want to disable the dispatching to `onLoading`, you can 
    // deactivate it, by setting `isEnable` of `loader` to `false`:
    //
    // loader.isEnabled = false
    //
    return true; 
  } 

  @override
  void onUpdate() {
    // You can set `updatedRate` of the app. The default value is `60`, 
    // which means `onUpdate` is called 60 times per second. If you set it 
    // to 0, `onUpdate/onRender` is called as often as possbile (which on 
    // most browser might be still 60fps).
  }

  @override
  void onRender() {
    // Here you should render everything. You can also render directly in 
    // onUpdate and ignore onRender. 
    // But this has disadvantages if the update rate doesn't match the 
    // display refresh rate.
    // NOTE: In onRender you don't have access to the input module as it polls on each onUpdate
    // and will be reset
  }

  @override
  void onResize() {
    // This is called as soon as the dimension of the canvas changes. 
    // `Bullseye2D` provides a default implementation that updates the 
    // projection matrix, but you are free to overwrite it, and provide your
    // custom implementation.
  }
  
  @override
  void onSuspend() {
    // This is called as soon as the app gets suspended (for example if the 
    // tab looses focus)
  }
  
  @override
  void onResume() {
    // This gets called when the app gains focus again.
  }
}

void main() {
  // To launch your app just instanciate your class that extends App.
  // You can optionally provide an AppConfig object.
  MyGame();
}
```

## Configure your app

You can optionally provide an [AppConfig](../bullseye/AppConfig-class.html) object when you constructing your app. For example, you can let your application know which HTML Canvas Element it should use to render your application into it.

```dart
class MyGame extends App {
  MyGame([super.config]);
}

void main() {
  AppConfig config = AppConfig(
    // Sets the CSS Selector to get the canvas element that the app should
    // use to render itself
    canvasElement: "#cssSelectorOfTheCanvas",

    // You can increase the memory that is used for the renderer to bacht
    // draw calls. If it is too small, it commits the queued calls to the
    // GPU and logs a warning message to the developer console.
    // In thise case you can improve the reserved memory here, to optimize
    // youre rendering performance.
    gfxBatchCapacityInBytes: 65536,

    // By default, if your app looses focus it stops running. You can disable
    // that, so your app continues to run even if it looses focus.
    autoSuspend: false
  );

  // Create an instance of you application with the desired configuration
  // and run the app.
  MyGame(config);
}
```

For all possible configuration values, have a look at the [AppConfig](../bullseye/AppConfig-class.html) class.

## All core features at your fingertips

The `App` class also provides access to all core engine features:

*   `gfx`: The `Graphics API` of the [**Graphics Module**](Graphics-topic.html).
*   `keyboard`: The `Keyboard API` of the [**Input Module**](Input-topic.html).
*   `mouse`: The `Mouse API` of the [**Input Module**](Input-topic.html).
*   `accel`: The `Accelerometer API` of the [**Input Module**](Input-topic.html).
*   `gamepad`: The `Gamepad API` of the [**Input Module**](Input-topic.html).
*   `audio`: The `Audio API` to play music and sound (see [**Audio Module**](Audio-topic.html))
*   `resources`: The `ResourceManager` for easy asset loading (see [**IO Module**](IO-topic.html)) 
*   `loader`: The `Loader` to retrieve information about the loading state of the app.

