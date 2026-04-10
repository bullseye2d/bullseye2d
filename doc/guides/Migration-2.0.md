# Migrating from Bullseye2D 1.x to 2.0

## 1. Update dependency

```yaml
# pubspec.yaml
bullseye2d: ^2.0.0
```

Then run `dart pub get`.

## 2. New project structure

Bullseye2D 2.0 supports web and SDL3 desktop targets. Games share code via `lib/`, with thin platform entry points:

```
project/
  assets/              # all assets live here now
  bin/main.dart        # SDL3 entry point (new)
  lib/my_game.dart     # shared game code
  web/
    assets -> ../assets  # symlink to shared assets
    index.html
    main.dart          # web entry point
```

### Move assets out of `web/`

```sh
mkdir assets
mv web/fonts web/gfx web/sfx web/music web/levels assets/
ln -s ../assets web/assets
```

### Prefix all asset paths with `assets/`

```dart
// before
resources.loadImage("gfx/sprites.png", ...);
resources.loadFont("fonts/MyFont.ttf", ...);
audio.playMusic("music/theme.mp3", true);

// after
resources.loadImage("assets/gfx/sprites.png", ...);
resources.loadFont("assets/fonts/MyFont.ttf", ...);
audio.playMusic("assets/music/theme.mp3", true);
```

This applies to all `loadImage`, `loadFont`, `loadSound`, `loadString`, and `playMusic` calls.

## 3. Extract game code into `lib/`

Move your game class to `lib/` so both entry points can import it. The game class must **not** import `package:web` directly — pass any web-specific data (e.g. URL parameters) via constructor parameters instead.

Accept an optional `AppConfig` so each entry point can provide its own:

```dart
class MyGame extends App {
  MyGame({AppConfig? config})
      : super(config ?? AppConfig(autoSuspend: false));
}
```

## 4. Create entry points

**`web/main.dart`**
```dart
import 'package:my_project/my_game.dart';

void main() {
  MyGame();
}
```

**`bin/main.dart`** (SDL3)
```dart
import 'package:bullseye2d/bullseye2d.dart';
import 'package:my_project/my_game.dart';

void main() {
  MyGame(
    config: AppConfig(
      title: 'My Game',
      width: 1280,
      height: 720,
    ),
  );
}
```

