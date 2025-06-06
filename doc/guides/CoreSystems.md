
# Core Systems

For convienence you have access to all core systems of `Bullseye2D` via global getters.

Here is an example of how you can access various subsystems from anywhere in your code that imports `Bullseye2D`.

```dart
class MySprite {
  var position = Vector2();
 
  late Image sprite;
  late Sound engineFX;
 
  MySprite() {
    sprite = resouces.loadImage("mySprite.png");
    engineFx = resources.loadSound("mySound.wav");
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

