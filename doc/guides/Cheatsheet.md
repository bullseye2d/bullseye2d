# Cheatsheet

<div class="note warning">
  <p><strong>Note:</strong> This is very work in progress. The plan is to create a quick reference card
with a list of all available commands in `Bullseye2D`.
</div>


| Member/Method                                                     | Description                                                                    |
|-------------------------------------------------------------------|--------------------------------------------------------------------------------|
| **App Lifecycle**                                     |                                                                                |
| `onCreate()`                                                  | Override this method for one-time setup logic when the app starts.             |
| `onUpdate()`                                                  | Override this method for game logic that runs every frame.                     |
| `onRender()`                                                  | Override this method for drawing and rendering operations every frame.         |
| `onSuspend()`                                                 | Override this method for logic to execute when the app loses focus or suspends.  |
| `onResume()`                                                  | Override this method for logic to execute when the app regains focus or resumes. |
| `onResize(int width, int height)`                             | Override this method to handle canvas resize events.                           |
| `onLoading()`                                                 | Override this to customize the loading screen; return `true` when done loading.  |
| **App Properties**                                     |                                                                                |
| `width`                                                       | Gets the current width of the game canvas in pixels.                           |
| `height`                                                      | Gets the current height of the game canvas in pixels.                          |
| `updateRate` (getter/setter)                                  | Gets or sets the desired game logic update rate in updates per second.         |
| `showMouse([Images? images, int frame = 0])`                  | Makes the system mouse cursor visible, optionally with a custom image.         |
| `hideMouse()`                                                 | Hides the system mouse cursor.                                                 |
| **Accelerometer (`accel`)**                                   |                                                                                |
| `accel.x`                                                     | Gets the current acceleration force along the X-axis (in Gs).                  |
| `accel.y`                                                     | Gets the current acceleration force along the Y-axis (in Gs).                  |
| `accel.z`                                                     | Gets the current acceleration force along the Z-axis (in Gs).                  |
| `accel.requestPermission()`                                   | Asynchronously requests permission to use the accelerometer (mainly for iOS).  |
| `accel.dispose()`                                             | Unregisters accelerometer event listeners.                                     |
| **Audio (`audio`)**                                           |                                                                                |
| `audio.musicPosition`                                         | Gets the current playback position of the music in seconds.                    |
| `audio.musicDuration`                                         | Gets the total duration of the current music in seconds.                       |
| `audio.musicProgress`                                         | Gets the current music playback progress (0.0 to 1.0).                         |
| `audio.musicVolume` (getter/setter)                           | Gets or sets the global music volume (0.0 to 1.0).                             |
| `audio.musicState`                                            | Gets the current state of the music player (e.g., playing, paused).            |
| `audio.initMusicVisualizer([int fftSize = 2048])`             | Initializes and returns an `AudioVisualizer` for the currently playing music.  |
| `audio.playSound(Sound sound, {int channel, bool loop, ...})` | Plays a `Sound` object, optionally on a specific channel and/or looped.      |
| `audio.playSoundOnTargetChannels(Sound sound, {List<int>? channels, ...})` | Plays a `Sound` on one of the specified available channels.                |
| `audio.stopChannel(int channelId)`                            | Stops playback on the specified audio channel.                                 |
| `audio.pauseChannel(int channelId)`                           | Pauses playback on the specified audio channel.                                |
| `audio.resumeChannel(int channelId)`                          | Resumes playback on a paused audio channel.                                    |
| `audio.setVolume(int channelId, double volume)`               | Sets the volume (0.0 to 1.0) for a specific audio channel.                     |
| `audio.setPan(int channelId, double pan)`                     | Sets the stereo panning (-1.0 left to 1.0 right) for a specific channel.       |
| `audio.setRate(int channelId, double rate)`                   | Sets the playback rate for a specific audio channel.                           |
| `audio.obtainFreeChannel([List<int>? targetChannels])`        | Finds and returns the ID of an available audio channel from the given list.    |
| `audio.playMusic(String path, bool loop, ...)`                | Loads and plays music from the given path, optionally looping.                 |
| `audio.stopMusic()`                                           | Stops the currently playing music.                                             |
| `audio.pauseMusic()`                                          | Pauses the currently playing music.                                            |
| `audio.resumeMusic()`                                         | Resumes the paused music.                                                      |
| **Gamepad (`gamepad`)**                                       |                                                                                |
| `gamepad.countDevices()`                                      | Returns the number of currently connected and recognized gamepads.             |
| `gamepad.joyDown(int port, GamepadButton btn)`                | Checks if the specified gamepad button on the given port is currently pressed. |
| `gamepad.joyHit(int port, GamepadButton btn)`                 | Checks if the specified gamepad button was just pressed in this frame.         |
| `gamepad.joyUp(int port, GamepadButton btn)`                  | Checks if the specified gamepad button was just released in this frame.        |
| `gamepad.joyX(int port, Joystick joystick)`                   | Gets the X-axis value (-1.0 to 1.0) of the specified joystick.                 |
| `gamepad.joyY(int port, Joystick joystick)`                   | Gets the Y-axis value (-1.0 to 1.0) of the specified joystick.                 |
| `gamepad.joyZ(int port, Trigger trigger)`                     | Gets the value (0.0 to 1.0) of the specified trigger.                          |
| `gamepad.angle(int port, Joystick joystick)`                  | Gets the angle (0-359 degrees) of the specified joystick.                      |
| **Graphics (`gfx`)**                                          |                                                                                |
| `gfx.dispose()`                                               | Releases WebGL resources (program, buffers, VAO).                              |
| `gfx.clear([double? r, ...])`                                 | Clears the drawing surface with the specified RGBA color.                      |
| `gfx.setColor([double r = 1.0, ...])`                         | Sets the current drawing color using RGBA values (0.0 to 1.0).                 |
| `gfx.setColorFrom(Color color)`                               | Sets the current drawing color using a `Color` (Vector4) object.               |
| `gfx.setBlendMode(BlendMode mode)`                            | Sets the blending mode for subsequent drawing operations.                      |
| `gfx.setLineWidth(double width)`                              | Sets the width for drawing lines.                                              |
| `gfx.setViewport(int x, int y, int width, int height)`        | Defines the rectangular area of the canvas where rendering will occur.         |
| `gfx.set2DProjection({double x, y, width, height})`           | Configures an orthographic projection for 2D rendering.                        |
| `gfx.setProjectionMatrix(Matrix4 matrix)`                     | Sets a custom projection matrix.                                               |
| `gfx.setScissor(int x, int y, int width, int height)`         | Enables and defines a scissor rectangle to clip rendering.                     |
| `gfx.resetScissor()`                                          | Disables scissor testing.                                                      |
| `gfx.resetMatrix()`                                           | Resets the current transformation matrix to identity.                          |
| `gfx.pushMatrix()`                                            | Saves the current transformation matrix onto a stack.                          |
| `gfx.popMatrix()`                                             | Restores the last saved transformation matrix from the stack.                  |
| `gfx.transform(double ix, iy, jx, jy, tx, ty)`                | Applies a 2D affine transformation to the current matrix.                      |
| `gfx.translate(double tx, double ty)`                         | Translates the current transformation matrix.                                  |
| `gfx.rotate(double degrees)`                                  | Rotates the current transformation matrix by the given angle in degrees.       |
| `gfx.scale(double sx, double sy)`                             | Scales the current transformation matrix.                                      |
| `gfx.drawPoint(double x, double y)`                           | Draws a single point at the specified coordinates.                             |
| `gfx.drawLine(double x1, y1, x2, y2, {ColorList? colors})`    | Draws a line between two points, optionally with per-vertex colors.            |
| `gfx.drawLines(List<double> vertices, {ColorList? colors})`   | Draws a series of connected lines (line strip).                                |
| `gfx.drawRect(double x, y, width, height, {Texture? t, ...})` | Draws a filled rectangle, optionally textured and with per-vertex colors.      |
| `gfx.drawOval(double x, y, rX, rY, {int segments, ...})`      | Draws a filled oval or ellipse.                                                |
| `gfx.drawCircle(double x, y, radius, {int segments, ...})`    | Draws a filled circle.                                                         |
| `gfx.drawPoly(List<double> vertices, {List<double>? uvs, ...})`| Draws a filled polygon from a list of vertices.                               |
| `gfx.drawTriangle(double x1,y1, x2,y2, x3,y3, u1,v1, ...)`    | Draws a textured triangle with specified vertex and UV coordinates.            |
| `gfx.drawTexture(Texture tex, {double? srcX, ...})`           | Draws a `Texture` or a portion of it at a specified location and size.         |
| `gfx.measureText(BitmapFont font, String text)`               | Calculates the width and height of a string if rendered with a `BitmapFont`.   |
| `gfx.drawText(BitmapFont font, String text, {double x, ...})` | Draws text using a `BitmapFont` with options for alignment and scaling.        |
| `gfx.drawImage(Images frames, [int frame, double x, ...])`   | Draws an `Image` (frame) with transformations (position, rotation, scale).     |
| `gfx.flush()`                                                 | Forces all batched drawing commands to be submitted to the GPU.                |
| **Keyboard (`keyboard`)**                                     |                                                                                |
| `keyboard.keyDown(KeyCodes key)`                              | Checks if the specified key is currently held down.                            |
| `keyboard.keyUp(KeyCodes key)`                                | Checks if the specified key was just released in this frame.                   |
| `keyboard.keyHit(KeyCodes key)`                               | Checks if the specified key was just pressed in this frame.                    |
| `keyboard.keyHitCountSinceLastFrame(KeyCodes key)`            | Gets how many times the specified key was pressed since the last frame.        |
| `keyboard.getCharBuffer()`                                    | Returns a string of all characters typed in the current frame.                 |
| `keyboard.getChar()`                                          | Retrieves and removes the next typed character from the input queue.           |
| `keyboard.peekChar(int index)`                                | Retrieves a typed character from the input queue by index without removing it. |
| **Loader (`loader`)**                                         |                                                                                |
| `loader.isEnabled` (getter/setter)                            | Gets or sets whether the resource loader is active.                            |
| `loader.loadingSequenceFinished` (getter/setter)              | Gets or sets if the `onLoading` method has indicated completion.               |
| `loader.loaded`                                               | Gets the total number of bytes loaded so far across all tracked items.         |
| `loader.total`                                                | Gets the total number of bytes for all tracked items.                          |
| `loader.done`                                                 | Returns `true` if all loading is complete or the loader is disabled.           |
| `loader.allItemsFinished`                                     | Returns `true` if all individual items have finished loading or failed.        |
| `loader.length`                                               | Gets the number of items currently being tracked by the loader.                |
| `loader.percent`                                              | Gets the overall loading progress as a value between 0.0 and 1.0.              |
| **Mouse (`mouse`)**                                           |                                                                                |
| `mouse.x`                                                     | Gets the current X-coordinate of the mouse cursor relative to the canvas.      |
| `mouse.y`                                                     | Gets the current Y-coordinate of the mouse cursor relative to the canvas.      |
| `mouse.scaleX`                                                | Gets the horizontal scaling factor for mouse coordinates.                      |
| `mouse.scaleY`                                                | Gets the vertical scaling factor for mouse coordinates.                        |
| `mouse.mouseWheel`                                            | Gets the mouse wheel scroll delta for the current frame (+1, -1, or 0).        |
| `mouse.mouseDown(MouseButton button)`                         | Checks if the specified mouse button is currently held down.                   |
| `mouse.mouseHit(MouseButton button)`                          | Checks if the specified mouse button was just pressed in this frame.           |
| `mouse.mouseUp(MouseButton button)`                           | Checks if the specified mouse button was just released in this frame.          |
| `mouse.touchDown(int touchIndex)`                             | Checks if the touch point at the given index is currently active.              |
| `mouse.touchHit(int touchIndex)`                              | Returns the number of times the touch point was initiated in this frame.       |
| `mouse.touchUp(int touchIndex)`                               | Checks if the touch point at the given index was just released.                |
| `mouse.touchX(int touchIndex)`                                | Gets the X-coordinate of the touch point at the given index.                   |
| `mouse.touchY(int touchIndex)`                                | Gets the Y-coordinate of the touch point at the given index.                   |
| **Resource Manager (`resources`)**                            |                                                                                |
| `resources.loadImage(String path, {int frameW, int frameH, ...})` | Loads an `Image` or `Images` (spritesheet) from a file.                      |
| `resources.loadFont(String path, double size, {bool antiAlias, ...})` | Loads a font file and generates a `BitmapFont` atlas.                        |
| `resources.loadSound(String path, {int retriggerDelayMs})`    | Loads a `Sound` effect from an audio file.                                     |
| `resources.loadString(String path)`                           | Asynchronously loads the content of a text file as a string.                   |
| **Global Functions**                                              |                                                                                |
| `log(dynamic arg1, ...)`                                          | General-purpose logging; can create/pop hierarchical log contexts.             |
| `info(dynamic arg1, ...)`                                         | Logs an informational message.                                                 |
| `warn(dynamic arg1, ...)`                                         | Logs a warning message.                                                        |
| `error(dynamic arg1, ...)`                                        | Logs an error message.                                                         |
| `die(dynamic arg1, ...)`                                          | Logs a critical error and throws an exception.                                 |
| `logReset()`                                                      | Clears the entire hierarchical log context stack.                              |
| `logOff()`                                                        | Disables all logging output.                                                   |
| `logOn()`                                                         | Enables logging output (clears any active filter).                             |
| `logEnableStacktrace(bool enable)`                                | Toggles the inclusion of a brief stack trace in log messages.                  |
| `logFilter([String? filter])`                                     | Filters log messages based on a string; prefix with '!' for inverse filter.  |
| `debugger()`                                                      | Programmatically triggers a breakpoint if a debugger is attached.              |
| `nextPowerOfTwo(int value)`                                       | Returns the smallest power of two greater than or equal to the input value.    |
| `atan2Degree(num y, num x)`                                       | Calculates the arc-tangent of y/x, returning the angle in degrees.             |
| `sinDegree(num degrees)`                                          | Calculates the sine of an angle provided in degrees.                           |
| `cosDegree(num degrees)`                                          | Calculates the cosine of an angle provided in degrees.                         |
| `tanDegree(num degrees)`                                          | Calculates the tangent of an angle provided in degrees.                        |
| `ColorFromInt(int value)`                                         | Creates a `Color` (Vector4) from an integer (currently always returns white).  |
| **Extension Methods**                                             |                                                                                |
| `Images.isLoading`                                           | (On `Images`) `true` if any image in the list is still loading.                |
| `Images.textures`                                            | (On `Images`) Returns a list of unique `Texture` objects from the images.      |
| `Images.texture`                                             | (On `Images`) Returns the `Texture` of the first image in the list.            |
| `Images.dispose()`                                           | (On `Images`) Disposes all images in the list.                                 |
| `Images.pivotX = double value`                               | (On `Images`) Sets the horizontal pivot point for all images in the list.      |
| `Images.pivotY = double value`                               | (On `Images`) Sets the vertical pivot point for all images in the list.        |
| `Images.first`                                               | (On `Images`) Gets the first `Image` in the list.                              |
| `Color.toUint8()`                                                 | (On `Color`/`Vector4`) Converts the RGBA color (0-1 range) to a packed int.    |
| `List<num>.sum()`                                                 | Calculates the sum of all numbers in the list.                                 |
| `List<num>.average()`                                             | Calculates the average of all numbers in the list.                             |
| `int.has(int flag)`                                               | Checks if a specific bit (flag) is set in the integer.                         |
| `int.hasAll(int flags)`                                           | Checks if all specified bits (flags) are set in the integer.                   |
