import 'package:web/web.dart';

/// Provides utility methods for detecting the current platform.
class Platform {
  /// Checks if the current environment is running on an iOS device or simulator.
  ///
  /// Returns `true` if the platform is detected as iOS, `false` otherwise.
  static bool isIOS() {
    final platform = window.navigator.platform.toLowerCase();
    return ['ipad simulator', 'iphone simulator', 'ipod simulator', 'ipad', 'iphone', 'ipod'].contains(platform) ||
        (platform == 'macintel' && window.navigator.maxTouchPoints > 1);
  }
}
