# Getting Started

## Prerequisites

Ensure you have the **Dart SDK** (>= 3.7.2) installed:
- https://dart.dev/get-dart

Install the **Bullseye2D CLI**:
```bash
dart pub global activate bullseye2d
```

## Create a new project

```bash
bullseye2d create ./my_game
cd ./my_game
```

This creates a project with the following structure:

```
my_game/
  assets/              # Shared assets (fonts, images, sounds)
    fonts/roboto/      # Default font included
  lib/
    game.dart          # Your game code
  web/
    index.html         # Web page with canvas
    main.dart          # Web entry point
    assets/            # Symlink to ../assets
  bin/
    main.dart          # SDL3 entry point
  pubspec.yaml
```

Your game logic goes in `lib/game.dart`. Both `web/main.dart` and `bin/main.dart` import it, so you write your game once and run it anywhere.

## Run on web

```bash
bullseye2d run web
```

Open your browser at `http://localhost:8080`.

```bash
# Specify a different port
bullseye2d run web --port 9090
```

You can also pass additional arguments to the underlying `webdev serve`:

```bash
# Automatically refresh browser when the app was rebuilt
bullseye2d run web -- --auto refresh
```

## Run with SDL3

```bash
bullseye2d run sdl3
```

This opens a desktop window using SDL3.

## Production Builds

### Web

```bash
bullseye2d build web
```

This generates an optimized production build in the `build/` folder.

### SDL3

```bash
bullseye2d build sdl3
```

This compiles an executable and bundles everything needed to distribute:

```
build/sdl3/
  my_game           # (or my_game.exe on Windows)
  assets/           # Bundled assets
  libSDL3.so        # SDL3 shared libraries (auto-bundled)
  libSDL3_image.so
  libSDL3_mixer.so
  libSDL3_ttf.so
```

## Desktop: SDL3

SDL3 builds use SDL3 for rendering, audio, and input. The required SDL3 shared libraries are **included in the repository** -- no manual setup required.

- `bullseye2d run sdl3` automatically configures library paths for development
- `bullseye2d build sdl3` bundles the libraries alongside the compiled executable

The SDL3 renderer uses SDL3's GPU abstraction, which auto-selects the best graphics backend for each platform (D3D12/Vulkan on Windows, Metal/Vulkan on macOS, Vulkan/OpenGL on Linux).
