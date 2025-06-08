# IO Module

## ResourceManager

The `ResourceManager` simplifies loading asset. The assets are loaded asynchronously.

<details>
<summary>

How to render a progress bar during loading?

</summary>
<content>

You have to do nothing. `Bullseye2D` has a default loading and progress indicator. 

When assets are being loaded the the App's [onLoading](../bullseye2d/App/onLoading.html) method gets called 
instead of [onUpdate](../bullseye2d/App/onUpdate.html) and [onRender](../bullseye2d/App/onRender.html) (you can disable this behaviour by setting
[loader.isEnabled](../bullseye2d/Loader/isEnabled.html) to `false`.)

The base [App]() class has already a default implementation, but you can create your own loader by overwriting the [onLoading](../bullseye2d/App/onLoading.html) method.

  </content>
</details>


## Loading assets

| Function | Description|
|---|---|
| [**loadTexture**(String path)](../bullseye2d/ResourceManager/loadTexture.html) | Loads an image file as a `Texture`. Caches textures by path. |
| [**loadImage**(String path)](../bullseye2d/ResourceManager/loadImage.html) | Loads an image (and optionally slives it into frames) |
| [**loadFont**(String path, double size)](../bullseye2d/ResourceManager/loadFont.html) | Loads a font file (e.g., TTF, OTF) and prepares a `BitmapFont` instance. |
| [**loadSound**(String path)](../bullseye2d/ResourceManager/loadSound.html) | Loads an audio file. |
| [**loadString**(String path)](../bullseye2d/ResourceManager/loadFile.html) | Loads the contents of the path into a String. |

All `load*` methods return the asset handle (`Texture`, `Images`, `BitmapFont`, `Sound`) immediately. 
The actual loading is asynchronous. You can already use the handles even if loading is unfinished. 
For example if you draw an Texture/Image while it is still loading, the render call ist just ignored. 
If you have the loader enabled (which is the default behaviour) you can be sure in your onUpdate/onRender 
methods that all assets are finished loading and ready for usage.

### Loading a font

```dart
var font = resources.loadFont("assets/fonts/wireone/WireOne-Regular.ttf", 196);

// Drawing text with loaded font
gfx.drawText(font, "Drawing some letters to the screen...", x: 25, y: 25);
```

### Loading an image / spritesheet

```dart
// Loading a sheet of 16x16 sprites
var spritesheet = resources.loadImage(
  "assets/spritesheet.png", frameWidth: 16, frameHeight: 16
);

// Drawing frame 0 of spritesheet at position 16, 16
gfx.drawImage(spritesheet, 0, 16, 16)
```


### Loading a sound

```dart
// Load a sound
var shootFX = loadSound("assets/shoot.wav", retriggerDelayInMs: 50);

// Start playing the sound
audio.playSound(shootFX);
```

### Playing music

```dart
// Loading a music file is not required, you can directly play it
// and it will be streamed in the background as soon as possible.
audio.playMusic("assets/music.ogg", true);
```
