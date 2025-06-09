# What is 🎯 Bullseye2D
[![pub package](https://img.shields.io/pub/v/bullseye2d.svg)](https://pub.dev/packages/bullseye2d)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Bullseye2D is a HTML5 game library for the [**Dart Progamming Language**](https://dart.dev). It provides a simple and straightforward API, with a fast WebGL2 renderer. You can learn it in an evening and start making games right from the start.

<div class="note warning">
  <p><strong>Disclaimer:</strong> This is an alpha version of <strong>Bullseye2D</strong>.<br/>
    I might introduce breaking API changes in the future.</p>
</div>

Learn more about `Bullseye2D` on our [Homepage](https://bullseye2d.org)

# Installation

## 1. Install Dart SDK
Ensure you have the Dart SDK installed. Here is a step by step guide to install Dart on your system:

- https://dart.dev/get-dart

## 2. Acitvate `webdev`

```bash
dart pub global activate webdev
```

## 3. Activate `bullseye2d`

```bash
dart pub global activate bullseye2d
```

# Examples

To run the examples you have the clone the repository.

```bash
git clone git@github.com:bullseye2d/bullseye2d.git
cd bullseye2d
cd example
dart pub get
webdev serve
```

You can also enjoy the demos on our [website](https://bullseye2d.org/demos).

You can have a look at the source code of the examples [here](https://github.com/bullseye2d/bullseye2d/blob/main/example/web).

# Learning
`Bullseye2D` comes with a comprehensive documentation. Read it [online](https://bullseye2d.org/docs) or use the following command to build the documentation and serve it locally on port 8080. Then open a browser on `localhost:8080` to learn about `Bullseye2D` or dive into the API Documentation.

```bash
bullseye2d docs --serve
```

# Create a new Project
To start a new `Bullseye2D` project, you can use the create command:

```bash
bullseye2d create ./hello_world
cd ./hello_world
webdev serve
```


