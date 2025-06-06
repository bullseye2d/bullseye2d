/// {@category App}
///
/// The configuration settings for the application.
///
/// This class holds various parameters that can be used to initialize
/// and customize the application's behavior.
///
/// ```dart
/// class MyGame extends App {
/// }
///
/// void main() {
///   AppConfig config = AppConfig(
///     // Sets the CSS Selector to get the canvas element that the app should
///     // use to render itself
///     canvasElement: "#cssSelectorOfTheCanvas",
///
///     // You can increase the memory that is used for the renderer to bacht
///     // draw calls. If it is too small, it commits the queued calls to the
///     // GPU and logs a warning message to the developer console.
///     // In thise case you can improve the reserved memory here, to optimize
///     // youre rendering performance.
///     gfxBatchCapacityInBytes: 65536,
///
///     // By default, if your app looses focus it stops running. You can disable
///     // that, so your app continues to run even if it looses focus.
///     autoSuspend: false
///
///     // On iOS you need to rquest permission from the user to use the Gyroscope. If you
///     // set this to true, it will be handled automatically for you on the first user
///     // interaction (click).
///     autoRequestAccelerometerPermission: false
///   );
///
///   // Create an instance of you application with the desired configuration
///   // and run the app.
///   MyGame(config);
/// }
/// ```
class AppConfig {
  /// The CSS selector for the HTML canvas element where the application will be rendered.
  ///
  /// Defaults to `"#gameCanvas"`.
  String canvasElement;

  /// The capacity of the graphics batcher in bytes.
  ///
  /// This determines the maximum size of data that can be batched together
  /// for a single draw call, potentially affecting rendering performance.
  /// Larger values can reduce draw calls but increase memory per batch.
  ///
  /// The renderer automatically flushes the current render queue if it
  /// runs out of memory and logs a warning to the developer console.
  ///
  /// Defaults to `65536` bytes (64KB).
  int gfxBatchCapacityInBytes;

  /// Indicates whether the application should automatically suspend its operations
  /// when it is not active (e.g., when the browser tab loses focus).
  ///
  /// Defaults to `true`.
  bool autoSuspend;

  /// If set to true, it automatically requests the permission from the user to read out
  /// the accelerometer.
  ///
  /// Defaults to `false`.
  bool autoRequestAccelerometerPermission;

  /// Creates an instance of [AppConfig] with optional parameters.
  ///
  /// - [canvasElement]: The CSS selector for the HTML canvas. Defaults to `"#gameCanvas"`.
  /// - [gfxBatchCapacityInBytes]: The graphics batch capacity in bytes. Defaults to `65536`.
  /// - [autoSuspend]: Whether the application should auto-suspend. Defaults to `true`.
  /// - [autoRequestAccelerometerPermission]: Auto request Accelerometer Permission on first user interaction. Defaults to `false`.
  AppConfig({
    this.canvasElement = "#gameCanvas",
    this.gfxBatchCapacityInBytes = 65536,
    this.autoSuspend = true,
    this.autoRequestAccelerometerPermission = false,
  });
}
