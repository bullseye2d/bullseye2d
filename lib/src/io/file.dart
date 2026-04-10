import 'package:bullseye2d/src/backend/backend.dart';
import 'package:bullseye2d/src/loader.dart';
import 'package:bullseye2d/src/util/debug.dart';

/// {@category IO}
/// Asynchronously loads a string from the specified [url].
///
/// Delegates to the [FileBackend] for platform-specific loading.
Future<String> loadStringAsync(String url, Loader loadingInfo, {FileBackend? fileBackend}) async {
  final backend = fileBackend ?? _fileBackend;
  if (backend == null) {
    warn("FileBackend not initialized. Cannot load: $url");
    return "";
  }
  var loadingState = loadingInfo.add(url);
  try {
    final content = await backend.loadString(url);
    loadingState.completedOrFailed = true;
    return content;
  } catch (e) {
    warn("Could not load: $url ($e)");
    loadingState.completedOrFailed = true;
    return "";
  }
}

/// Global FileBackend instance set during App initialization.
FileBackend? _fileBackend;

/// @nodoc
/// Sets the global FileBackend for use by top-level file loading functions.
void initFileBackend(FileBackend backend) {
  _fileBackend = backend;
}
