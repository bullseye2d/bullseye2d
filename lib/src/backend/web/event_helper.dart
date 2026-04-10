import 'package:web/web.dart';

/// {@category Utility}
/// Stops the propagation and prevents the default action of a browser [Event].
///
/// This is a common utility function to call on events (like mouse clicks,
/// key presses, or touch events) to prevent them from bubbling up the DOM
/// tree or triggering default browser behaviors (e.g., form submission,
/// context menu).
void stopEvent(Event event) {
  event.stopPropagation();
  event.preventDefault();
}
