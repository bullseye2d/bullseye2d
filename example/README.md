# Bullseye2D Examples

Bullseye2D comes with demos that run on both web and SDL3 desktop from the same source code.

## Web

Explore them on our website at [bullseye2d.org/demos](https://bullseye2d.org/demos) or run locally:

```bash
git clone https://github.com/bullseye2d/bullseye2d.git
cd bullseye2d/example
dart pub get
bullseye2d run web
```

Open your browser at `http://localhost:8080`.

## SDL3 (Desktop)

```bash
cd bullseye2d/example
dart pub get
bullseye2d run sdl3 hello_world
```

You can also start a specific demo directly:
```bash
dart run bin/main.dart hello_world
dart run bin/main.dart sprites
dart run bin/main.dart input
dart run bin/main.dart music_player
```

## Source Code

All demo logic is in [lib/demos/](lib/demos/) — shared between web and SDL3 with zero duplication.

## More Examples

### Soko64 - A tiny 64x64 Low-Res Sokoban game

Soko64 is a full sokoban game written in `Bullseye2D`:

You can play it [here](https://joemanaco.itch.io/soko64).

If you want to play around with the source, clone the repository:
```bash
git clone https://github.com/JochenHeizmann/soko64.git
cd soko64
dart pub get
bullseye2d run web
```

The whole game is in a single source file, `web/main.dart`.
