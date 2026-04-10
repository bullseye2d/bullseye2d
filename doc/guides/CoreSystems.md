
# Core Systems

For convenience you have access to all core systems of `Bullseye2D` via global getters.

Here is an example of how you can access various subsystems from anywhere in your code that imports `Bullseye2D`.

```dart
class MySprite {
  var position = Vector2();

  late Image sprite;
  late Sound engineFX;

  MySprite() {
    sprite = resources.loadImage("assets/mySprite.png");
    engineFx = resources.loadSound("assets/mySound.wav");
  }

  void update() {
    if (keyboard.keyHit(KeyCodes.W)) {
      position.y -= 4;
    }
  }

  void render() {
    audio.playSound(engineFX);
    gfx.drawImage(sprite, 0, position.x, position.y);
  }
}
```

## Backend Abstraction

Bullseye2D uses a platform abstraction layer under the hood. Each core system delegates to a platform-specific backend:

| System | Web Backend | SDL3 Backend |
|--------|------------|----------------|
| **Rendering** | WebGL2 | SDL_Renderer (auto-selects GPU backend) |
| **Audio** | Web Audio API | SDL3_mixer |
| **Keyboard** | DOM events | SDL3 events |
| **Mouse** | DOM events | SDL3 events |
| **Gamepad** | Browser Gamepad API | SDL3 Gamepad API |
| **File I/O** | XMLHttpRequest / Fetch | dart:io |
| **Image Loading** | Canvas2D / Blob | SDL3_image |
| **Font Rasterization** | FontFace + Canvas2D | SDL3_ttf |
| **Storage** | localStorage | JSON file on disk |

The correct backend is selected at compile time via Dart conditional imports. You never interact with backends directly -- the public API (`gfx`, `audio`, `keyboard`, `mouse`, `gamepad`, `resources`) is the same on all platforms.
