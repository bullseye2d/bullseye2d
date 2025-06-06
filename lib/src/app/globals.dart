import 'package:bullseye2d/bullseye2d.dart';

/// {@category Core_Systems}
/// Provides access to the device's accelerometer data.
///
/// Use this to detect device motion and orientation changes.
Accelerometer get accel => App.instance.accel;

/// {@category Core_Systems}
/// Manages audio playback for sounds and music.
///
/// Use this to play sound effects, background music, and manage audio channels.
Audio get audio => App.instance.audio;

/// {@category Core_Systems}
/// Handles gamepad input from connected controllers.
///
/// Use this to query button presses, joystick positions, and trigger states.
Gamepad get gamepad => App.instance.gamepad;

/// {@category Core_Systems}
/// The main graphics interface for rendering 2D primitives, textures, and text.
///
/// All drawing operations are performed through this object.
Graphics get gfx => App.instance.gfx;

/// {@category Core_Systems}
/// Manages keyboard input.
///
/// Use this to check for key presses, holds, and releases, and to read text input.
Keyboard get keyboard => App.instance.keyboard;

/// {@category Core_Systems}
/// Manages the loading of game assets.
///
/// Tracks the progress of asynchronous resource loading and provides
/// information about the loading state, which can be used to display
/// loading screens via the [App.onLoading] method.
Loader get loader => App.instance.loader;

/// {@category Core_Systems}
/// Manages mouse and touch input.
///
/// Use this to get cursor position, button states, and touch events.
Mouse get mouse => App.instance.mouse;

/// {@category Core_Systems}
/// Manages loading and caching of game resources like textures, fonts, and sounds.
///
/// Provides methods to load assets and automatically handles
/// progress tracking with the [loader].
ResourceManager get resources => App.instance.resources;
