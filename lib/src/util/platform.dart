import 'package:bullseye2d/src/backend/backend.dart';

/// {@category Utility}
/// Provides utility methods for detecting the current platform.
class Platform {
  static WindowBackend? _window;

  /// @nodoc
  /// Sets the window backend. Called during App initialization.
  static void init(WindowBackend window) {
    _window = window;
  }

  /// Returns the platform identifier string (e.g. "web", "ios", "windows", "macos", "linux").
  static String getPlatform() {
    return _window?.getPlatform() ?? 'unknown';
  }

  /// Returns `true` if running in a web browser.
  static bool isWeb() {
    return getPlatform() == 'web';
  }

  /// Returns `true` if the current platform is iOS.
  static bool isIOS() {
    return getPlatform() == 'ios';
  }

  /// Returns `true` if the current platform is Windows.
  static bool isWindows() {
    return getPlatform() == 'windows';
  }

  /// Returns `true` if the current platform is macOS.
  static bool isMacOS() {
    return getPlatform() == 'macos';
  }

  /// Returns `true` if the current platform is Linux.
  static bool isLinux() {
    return getPlatform() == 'linux';
  }

  /// Returns `true` if running on a desktop platform (Windows, macOS, or Linux).
  static bool isDesktop() {
    return isWindows() || isMacOS() || isLinux();
  }
}
