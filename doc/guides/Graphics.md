# Graphics Module

All rendering in `Bullseye2D` is handled through the `Graphics` object, accessible via `app.gfx`.

## Coordinate System

By default, Bullseye2D uses a 2D Cartesian coordinate system where:
- The origin `(0,0)` is at the **top-left corner** of the canvas.
- The X-axis increases to the **right**.
- The Y-axis increases **downwards**.

This can be customized using the projection matrix (see section on "The 2D Projection").

## Colors

Colors are represented by the `Color` type. Each component (Red, Green, Blue, Alpha) ranges from `0.0` to `1.0`.

You can set the current drawing color using:
- `gfx.setColor(double r, double g, double b, double a)`: Sets color with individual components.
  ```dart
  gfx.setColor(1.0, 0.5, 0.0, 1.0); // Orange
  ```
- `gfx.setColorFrom(Color color)`: Sets color from a `Color` object.
  ```dart
  var myColor = Color(0.0, 1.0, 0.0, 1.0); // Green
  gfx.setColorFrom(myColor);
  ```

For operations that support per-vertex coloring (like gradients on rectangles or polygons), you can use a `ColorList`.

<details>
<summary>Render a rectangle with an gradient</summary>
<content>

```dart
@override
onRender() {
  ColorList gradient = [
    Color(0.4, 0.7, 0.9, 1.0),
    Color(0.8, 0.6, 0.8, 1.0),
    Color(0.3, 0.5, 0.8, 1.0),
    Color(0.7, 0.5, 0.7, 1.0)
  ];

  gfx.drawRect(0, 0, w, h, colors: gradient)
```

</content>
</details>

<details>
<summary>Blend Modes</summary>
<content>

You can control how colors are blended when drawn on top of existing pixels using `gfx.setBlendMode(BlendMode mode)`. Available modes:
| Blend Mode        | Description                                                            |
|-------------------|------------------------------------------------------------------------|
| `BlendMode.opaque`  | (Default) Source pixels overwrite destination pixels.                  |
| `BlendMode.alpha`   | Standard alpha blending (typically for pre-multiplied alpha textures). |
| `BlendMode.additive`| Adds the source color to the destination color (brightening effect).   |
| `BlendMode.multiply`| Multiplies the source color with the destination color, darkening it and respecting source alpha. |
| `BlendMode.multiply2`| A stronger darkening effect than `BlendMode.multiply`.                 |
| `BlendMode.screen`  | Inverts both colors, multiplies them, and then inverts the result; a brightening effect, often seen as the opposite of multiply. |

```dart
gfx.setBlendMode(BlendMode.additive);
gfx.drawImage(myGlowEffectImage, ...);
gfx.setBlendMode(BlendMode.alpha); // Switch back for normal drawing
```

</content>
</details>

## Clearing the Screen

Before drawing each frame, you typically want to clear the screen.
- `gfx.clear()`: Clears with the color currently set by `gfx.setColor()`.
- `gfx.clear(double r, double g, double b, double a)`: Clears with the specified RGBA color.

```dart
// In onRender():
// Clear screen to dark blue
gfx.clear(0.0, 0.0, 0.2, 1.0);

// ... rest of your drawing code ...
```

## Drawing primitives

The `gfx` object provides methods to draw various primitives:

| Member/Method                                                     | Description                                                                    |
|-------------------------------------------------------------------|--------------------------------------------------------------------------------|
| `gfx.drawPoint(double x, double y)`                           | Draws a single point at the specified coordinates.                             |
| `gfx.drawLine(double x1, y1, x2, y2, {ColorList? colors})`    | Draws a line between two points, optionally with per-vertex colors.            |
| `gfx.drawLines(List<double> vertices, {ColorList? colors})`   | Draws a series of connected lines (line strip).                                |
| `gfx.drawRect(double x, y, width, height, {Texture? t, ...})` | Draws a filled rectangle, optionally textured and with per-vertex colors.      |
| `gfx.drawOval(double x, y, rX, rY, {int segments, ...})`      | Draws a filled oval or ellipse.                                                |
| `gfx.drawCircle(double x, y, radius, {int segments, ...})`    | Draws a filled circle.                                                         |
| `gfx.drawPoly(List<double> vertices, {List<double>? uvs, ...})`| Draws a filled polygon from a list of vertices.                               |
| `gfx.drawTriangle(double x1,y1, x2,y2, x3,y3, u1,v1, ...)`    | Draws a textured triangle with specified vertex and UV coordinates.            |

<details>
<summary>Example: Drawing some primitives</summary>
<content>

```dart
import 'package:bullseye2d/bullseye2d.dart';

class RenderDemo extends App {
  @override
  onCreate() async {
  }

  @override
  onRender() {
    gfx.clear(0, 0, 0, 1);

    // draw a line
    gfx.drawLine(10, 10, 500, 10);

    // draw a rectangle
    gfx.drawLines([10, 20, 500, 20, 500, 100, 10, 100, 10, 20]);

    // draw a filled rectangle
    gfx.drawRect(10, 110, 50, 50);

    // draw an ellipse
    gfx.drawOval(255, 50, 40, 20);
  }
}

main() {
  RenderDemo();
}
```

</content>
</details>


## Rendering Text

Bullseye2D uses Bitmap Fonts for rendering text. A `BitmapFont` is generated from a TrueType/OpenType font file by rendering characters into a texture atlas.

### Loading a Font

Use `app.resources.loadFont()`:

```dart
// In onCreate():
late BitmapFont myFont;
myFont = resources.loadFont(
  "assets/fonts/my_font.ttf",
  32.0, // Font size in pixels
  antiAlias: true, // Optional: Smooth rendering (default true)
  containedAsciiCharacters: BitmapFont.extendedAscii // Optional: Character set (default extended ASCII)
);
```

<details>
<summary>Character Sets for <em>BitmapFont</em></summary>
<content>

When loading a `BitmapFont`, you can specify which characters to include in the texture atlas using the `containedAsciiCharacters` parameter.
| Member | Description |
|--------|-------------|
| `BitmapFont.defaultAscii`| Printable ASCII characters (codes 32-126).|
| `BitmapFont.extendedAscii`| (Default) Includes `defaultAscii` plus Latin-1 supplement characters (codes 160-255).|

You can also provide your own custom string of characters. Only the characters specified will be available for rendering.

</content>
</details>

### Drawing Text

If you have loaded a `BitmapFont` you can use `gfx.drawText()` to render text to the screen

```dart
// In onRender():
gfx.setColor(1.0, 1.0, 1.0, 1.0); // Set text color (white)
gfx.drawText(myFont, "Hello, World!",
  x: 100, y: 150,
  alignX: 0.0, // 0.0:left, 0.5:center, 1.0:right (default 0.0)
  alignY: 0.0, // 0.0:top, 0.5:middle, 1.0:bottom (default 0.0)
  scaleX: 1.0, // Optional horizontal scale
  scaleY: 1.0, // Optional vertical scale
);

```
`gfx.drawText` supports newline characters (`\n`) for multi-line text.

**Measuring Text**
To get the dimensions of a string before drawing:
```dart
Point textSize = gfx.measureText(myFont, "Some text");
log("Text width: ${textSize.x}, height: ${textSize.y}");
```

**Adjusting Spacing:**
- `font.leadingMod`: Multiplier for vertical line spacing (default `1.0`).
- `font.tracking`: Multiplier for horizontal character spacing (default `1.0`).

```dart
myFont.leadingMod = 1.2; // Increase line height by 20%
myFont.tracking = 0.9; // Decrease character spacing by 10%
```

## Images

You can load a image or a spritsheet (an single image that will be sliced up in multiple frames) with `resources.loadImage`:

<details>
<summary>Example of a rotating image</summary>
<content>

```dart
import 'package:bullseye2d/bullseye2d.dart';

class SpritesApp extends App {
  int counter = 0;

  late Images sprites;

  @override
  onCreate() async {
    sprites = resources.loadImage("assets/gfx/spritesheet.png", frameWidth: 16, frameHeight: 16);
  }

  @override
  onUpdate() {
    counter += 1;
  }

  @override
  onRender() {
    gfx.clear(0, 0, 0, 1);

    int frame = 0;
    double rotation = (counter / 2.0) % 360;
    const double zoomFactor = 2.0;

    // render a rotating sprite
    gfx.drawImage(sprites, frame, width / 2, height / 2, rotation, zoomFactor, zoomFactor);
  }
}

main() {
  SpritesApp();
}
```

  </content>
</details>

## Animating Images

To animate a spritesheet, simply change the `frame` index passed to `gfx.drawImage()` over time.


<details>
<summary>Example of a animated image</summary>
<content>

```dart
import 'package:bullseye2d/bullseye2d.dart';

class SpritesApp extends App {
  double frame = 0.0;

  late Images sprites;

  @override
  onCreate() async {
    sprites = resources.loadImage("assets/gfx/spritesheet.png", frameWidth: 16, frameHeight: 16);
  }

  @override
  onUpdate() {
    frame += 0.1;
  }

  @override
  onRender() {
    gfx.clear(0, 0, 0, 1);
    gfx.drawImage(sprites, frame.floor() % sprites.length, width / 2, height / 2);
  }
}

main() {
  SpritesApp();
}
```

  </content>
</details>


## Transformations

The graphics system uses a transformation matrix to position, rotate, and scale objects. The matrix stack allows you to save and restore transformation states, which is essential for hierarchical transformations (e.g., a moon rotating around a planet, which itself orbits a sun).

| Member/Method                                                     | Description                                                                    |
|-------------------------------------------------------------------|--------------------------------------------------------------------------------|
|`gfx.pushMatrix()` | Saves the current transformation matrix onto a stack. |
|`gfx.popMatrix()` | Restores the previously saved matrix from the stack, making it the current one. |
|`gfx.resetMatrix()` | Resets the current transformation matrix to the identity (no transformation). |
|`gfx.translate(double tx, double ty)` | Moves the origin. |
|`gfx.rotate(double degrees)` | Rotates around the current origin. |
|`gfx.scale(double sx, double sy)` | Scales from the current origin. |
|`gfx.transform(ix, iy, jx, jy, tx, ty)` | Applies a full affine transformation. |

<details>
  <summary>Example</summary>
<content>

```dart
import 'package:bullseye2d/bullseye2d.dart';

class TranslationDemo extends App {
  double sunRotation = 0.0;
  double planetOrbitAngle = 0.0;
  double moonOrbitAngle = 0.0;

  @override
  onUpdate() {
    sunRotation += 0.5;
    planetOrbitAngle += 1.0;
    moonOrbitAngle += 2.0;
  }

  @override
  onRender() {
    gfx.clear(0, 0, 0, 1);
    gfx.setColor(1, 1, 1, 1);

    // --- Sun ---
    gfx.pushMatrix();
    gfx.translate(width / 2, height / 2); // Move to center of screen
    gfx.rotate(sunRotation);
    gfx.drawCircle(0, 0, 100, colors: [Color(1, 1, 0, 1), Color(1, 0.5, 0.5, 1)]); // Draw Sun with radius 100

    gfx.pushMatrix();
    gfx.rotate(planetOrbitAngle); // Planet's orbital rotation
    gfx.translate(250, 0); // Move out to planet's orbital distance
    gfx.drawCircle(0, 0, 50, colors: [Color(0, 0, 1, 1), Color(0, 0, 0.5, 1)]); // Draw Planet

    // --- Moon (orbits Planet) ---
    gfx.rotate(moonOrbitAngle);
    gfx.translate(80, 0);
    gfx.drawRect(-16, -16, 32, 32, colors: [Color(0.7, 0.7, 0.7, 1)]); // Draw Moon
    gfx.popMatrix(); // we pop matrix, so we're back on the on the translations we set up for sun

    gfx.rotate(planetOrbitAngle);
    gfx.translate(-250, 0);
    gfx.drawCircle(0, 0, 50, colors: [Color(1, 0, 1, 1), Color(1, 0, 0.5, 1)]);

    gfx.popMatrix();
  }
}

main() {
  TranslationDemo();
}
```

</content>
  </details>

### Why use a Matrix Stack?

Imagine you want to draw a car with wheels that rotate.
1. You translate and rotate the car body to its position.
2. To draw the first wheel:
   - `pushMatrix()`: Save the car body's transformation.
   - `translate(wheel1_offsetX, wheel1_offsetY)`: Move to where wheel 1 attaches to the body.
   - `rotate(wheel1_rotation)`: Rotate the wheel itself.
   - Draw the wheel (centered at the new 0,0).
   - `popMatrix()`: Restore the transformation to be just the car body's again.
3. To draw the second wheel, you do a similar push/translate/rotate/draw/pop sequence, starting from the car body's transformation.

Without the stack, you'd have to manually calculate absolute world coordinates for every part of every object, which becomes very complex with nested rotations and translations. The stack keeps track of relative transformations.

## The 2D Projection

The projection matrix transforms your 2D world coordinates into the normalized device coordinates. `Bullseye2D` provides `gfx.set2DProjection()` to easily set up an orthographic projection.

- `gfx.set2DProjection({double x = 0.0, double y = 0.0, double? width, double? height})`
  - `x, y`: The top-left corner of your visible world.
  - `width, height`: The width and height of your visible world. If not provided, they default to the canvas's client width/height.

This means if you call `gfx.set2DProjection(width: 800, height: 600)`, your game world will effectively be 800 units wide and 600 units high, regardless of the actual canvas pixel size. The engine handles the scaling.

**`onResize(int newWidth, int newHeight)`**

The `App.onResize()` method is called automatically whenever the browser window (and thus the canvas) is resized.
Its default implementation is:
```dart
// Default App.onResize()
onResize(int width, int height) {
  gfx.setViewport(0, 0, width, height);
  gfx.set2DProjection(width: width.toDouble(), height: height.toDouble());
}
```
This makes your game world pixel-perfectly match the canvas size.

The `examples/web/common/app.dart` shows an example of a fixed virtual resolution approach. The browser will scale the canvas element itself, and your game renders to a fixed-size buffer.

## Performance: Batching

Bullseye2D employs a technique called **batch rendering** to optimize performance. Instead of sending each drawing command (e.g., `drawRect`, `drawImage`) to the GPU immediately, it collects compatible commands into a "batch" and sends them all at once. This significantly reduces the overhead of communication between the CPU and GPU.

**How Bullseye2D Helps:**
- **Automatic Batching:** The engine tries to batch draw calls for you.
- **Vertex Buffer:** It maintains a vertex buffer (size configurable via `AppConfig.gfxBatchCapacityInBytes`). When this buffer is full, or a state change occurs, the current batch is flushed (sent to the GPU).

**What is a "Flush"?**
A flush means all currently batched geometry is drawn. `gfx.flush()` is called:
1.  Automatically at the end of `App.onRender()`.
2.  When the internal batching buffer is full.
3.  When a rendering state change occurs that prevents further batching. These include:
    - Changing the active texture (`Texture.white` is a texture too!).
    - Changing the `BlendMode` (`gfx.setBlendMode()`).
    - Changing the primitive type (e.g., switching from drawing quads/rectangles to lines).
        - Note: `_PrimitiveType.triangleFan` and `_PrimitiveType.lineStrip` will always cause a flush before drawing and after, as they are drawn with `gl.drawArrays` in a non-indexed way that's distinct from the batched quads.

**How to Maximize Batching Performance:**
1.  **Minimize Texture Swaps:**
    - Use **texture atlases** (sprite sheets). Put many small images into one larger texture. This allows you to draw multiple different sprites without changing the bound texture, leading to larger batches. `Image.loadFrames` helps with this.
    - Group draw calls by texture: Draw all objects using texture A, then all objects using texture B, etc.
2.  **Minimize Blend Mode Changes:**
    - Group draw calls by `BlendMode`. Draw all alpha-blended objects together, then all additive objects together, etc.
3.  **Minimize Primitive Type Changes:**
    - If you need to draw many lines and many quads, try to draw all lines first, then all quads (or vice-versa), if your game logic allows.
4.  **Be Aware of Text:** `BitmapFont`s use their own texture atlases. Drawing text will likely cause a texture swap if you were just drawing other images.

<details>
<summary>Understanding Batching Example</summary>
<content>

**Less Optimal (more flushes):**
```dart
// Texture A for player
gfx.drawImage(playerImage, ...); // Uses Texture A

// Texture B for enemy 1
gfx.drawImage(enemy1Image, ...); // FLUSH (Texture change from A to B)

// Text uses FontTexture
gfx.drawText(font, "Score: 100", ...); // FLUSH (Texture change from B to 
                                       // FontTexture)

// Back to Texture A for another player element (e.g., shield)
gfx.drawImage(playerShieldImage, ...); // FLUSH (Texture change from 
                                       // FontTexture to A)
```
**Total Flushes (potentially): 3 internal + 1 end-of-frame = 4**

**More Optimal (fewer flushes):**
```dart
// Assume playerImage and playerShieldImage are from the SAME texture atlas (Texture A)
// Assume enemy1Image and enemy2Image are from the SAME texture atlas (Texture B)

// Draw all Texture A items
gfx.drawImage(playerImage, ...);
gfx.drawImage(playerShieldImage, ...); // No flush if playerShieldImage uses Texture A

// Draw all Texture B items
gfx.drawImage(enemy1Image, ...); // FLUSH (Texture change from A to B)
gfx.drawImage(enemy2Image, ...); // No flush if enemy2Image uses Texture B

// Draw text
gfx.drawText(font, "Score: 100", ...); // FLUSH (Texture change from B to FontTexture)
```
**Total Flushes (potentially): 2 internal + 1 end-of-frame = 3**

The engine will warn you in the console if the batch buffer (`gfxBatchCapacityInBytes`) is too small and causes frequent flushes due to capacity rather than state changes: `vbo_buffer is full. consider enlarge it for better performance`.

</content>
</details>

## Using a Custom Mouse Pointer

You can replace the default system mouse cursor with a custom image.
1.  Load your cursor image(s) using `resources.loadImage()`. Pay attention to `pivotX` and `pivotY` as these will define the hotspot of your custom cursor.
2.  Call `app.showMouse(Images? images, [int frame = 0])`.
3.  To hide the cursor, call `app.hideMouse()`.

```dart
import 'package:bullseye2d/bullseye2d.dart';

class PointerDemo extends App {
  @override
  onCreate() async {
    Images pointer = resources.loadImage("assets/gfx/pointer.png", pivotX: 0.0, pivotY: 0.0);
    showMouse(pointer);
  }
}

main() {
  PointerDemo();
}

```

## Writing a Custom Loading Screen

The `App` class has an `onLoading()` method that is called repeatedly while assets are loading (i.e., `loader.done` is `false`). You can override this to create a custom loading screen.

- `loader.percent`: Overall loading progress (0.0 to 1.0). This is an average of individual item progresses.
- `loader.loaded`: Total bytes loaded across all items.
- `loader.total`: Total bytes expected (can be 0 if sizes aren't known yet for some items).
- `loader.allItemsFinished`: True if every individual item has completed (success or fail).
- `loader.loadingSequenceFinished`: Becomes true when all `resources.load*` calls in your initial setup (e.g., `onCreate`) have been made and `onLoading` returns true while `allItemsFinished` is also true.

**`onLoading()` Behavior:**
- This method is called *instead* of `onUpdate()` and `onRender()` while `loader.done` is false.
- To exit the loading screen and proceed to normal game loop (`onUpdate`/`onRender`), `onLoading()` must return `true` AND `loader.allItemsFinished` must also be true.
- If you return `true` but `loader.allItemsFinished` is still false, `onLoading` will continue to be called.
- The default `onLoading` implementation in `App` shows spinning circles and a progress bar.

**Example of a Simple Custom Loading Screen:**
```dart
// In your App class:
@override
bool onLoading() {
  gfx.clear(0.05, 0.05, 0.1, 1.0); // Dark blue background


  // calculate and render the loading bar
  gfx.drawRect(0, height / 2 - 20.0, width * loader.percent , 40);

  // Condition to leave the loading screen:
  // All items finished loading AND (for this example) player presses Space
  if (loader.allItemsFinished) {
      if (keyboard.keyHit(KeyCodes.Space)) {
          log("Loading complete and space pressed, starting game!");
          return true; // Proceed to onUpdate/onRender
      }
  }

  return false;
}
```

<div class="note">
  <p><strong>Info</strong>
    If you don't want Bullseye's loader / onLoading at all, you can disable it with.</p>

```dart
// in onCreate():
loader.isEnabled = false
```

  <p>
    Please be aware that assets might not be ready when onUpdate/onRender gets called. You can either either check the items if they are still loading or you can ignore it. In that case, Sounds or Images will not be rendered until fully loaded, but your logic will run fine without error.
  </p>
</div>

