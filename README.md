# What is Bullseye2D?
[![pub package](https://img.shields.io/pub/v/bullseye2d.svg)](https://pub.dev/packages/bullseye2d)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Bullseye2D is a 2D game library for the [**Dart Programming Language**](https://dart.dev). It provides a simple and straightforward API with high-performance rendering. Games built with Bullseye2D compile to **web browsers** (WebGL2) and **desktop** (Windows, Mac, Linux via SDL3) from a single codebase without code changes.

<div class="note warning">
  <p><strong>Disclaimer:</strong> This is still an alpha version of <strong>Bullseye2D</strong>.<br/>
    I might introduce breaking API changes in the future.</p>
</div>

Learn more about `Bullseye2D` on our [Homepage](https://bullseye2d.org)

## Supported Platforms

| Platform | Renderer | Audio | Status |
|----------|----------|-------|--------|
| Web (Chrome, Firefox, Safari) | WebGL2 | Web Audio API | Beta |
| Windows | SDL3 (D3D12/Vulkan/OpenGL) | SDL3_mixer | Beta |
| macOS | SDL3 (Metal/Vulkan/OpenGL) | SDL3_mixer | Beta |
| Linux | SDL3 (Vulkan/OpenGL) | SDL3_mixer | Beta |

# Installation

## 1. Install Dart SDK
Ensure you have the Dart SDK (>= 3.7.2) installed:

- https://dart.dev/get-dart

## 2. Install the Bullseye2D CLI

```bash
# webdev is requried to run the builds in the browser
dart pub global activate webdev

dart pub global activate bullseye2d
```

## 3. Create a project

```bash
bullseye2d create ./my_game
cd ./my_game
```

## 4. Run your game

```bash
# Run development server, test on the browser
bullseye2d run web

# Run the SDL3 Desktop Build
bullseye2d run sdl3
```

## 5. Build for distribution

```bash
# Build for web
bullseye2d build web

# Build SDL3 executable
bullseye2d build sdl3
```

## Desktop: SDL3

SDL3 builds use SDL3 for rendering, audio, and input. The required SDL3 shared libraries (SDL3, SDL3_image, SDL3_mixer, SDL3_ttf) are **included in the repository** -- no manual setup required.

- `bullseye2d run sdl3` automatically configures library paths for development
- `bullseye2d build sdl3` bundles the libraries alongside the compiled executable

# Examples

```bash
git clone git@github.com:bullseye2d/bullseye2d.git
cd bullseye2d/example
dart pub get

bullseye2d run web
bullseye2d run sdl3
```

You can also enjoy the demos on our [website](https://bullseye2d.org/demos).

Source code: [example](https://github.com/bullseye2d/bullseye2d/blob/main/example)

# Learning
`Bullseye2D` comes with comprehensive documentation. Read it [online](https://bullseye2d.org/docs) or serve it locally:

```bash
bullseye2d docs --serve
```

# Third-Party Licenses

See [LICENSE](https://github.com/bullseye2d/bullseye2d/blob/main/LICENSE) for the full text of all licenses, including third-party dependencies.

