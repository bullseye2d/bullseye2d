import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart';
import 'dart:async';
import 'dart:js_interop';

/// {@category IO}
/// Asynchronously loads a string from the specified [url].
///
/// Parameters:
///  - [url]: The URL of the file to load.
///  - [loadingInfo]: A [Loader] instance to track the loading progress.
///
/// Returns a [Future] that completes with the string content of the file.
/// If the file cannot be loaded, the future completes with an empty string.
Future<String> loadStringAsync(String url, Loader loadingInfo) async {
  return load<String>(
    url,
    loadingInfo,
    responseType: "text",
    defaultValue: "",
    onError: null,
    onLoad: (response, complete, error) {
      complete((response as JSString).toDart);
    },
  );
}

/// {@category IO}
/// Asynchronously loads a file from the specified [path] and returns its content
/// as type [T].
///
/// Parameters:
///  - [path]: The URL or path to the file to load.
///  - [loadingInfo]: A [Loader] instance to track the loading progress.
///    The function will add a [LoaderItem] to this [Loader] to represent
///    the current loading operation.
///  - [responseType]: The expected type of the response from the server.
///    Defaults to "text". Common values include "arraybuffer", "blob", "json", "text".
///    This corresponds to `XMLHttpRequest.responseType`.
///  - [defaultValue]: A value of type [T] to be returned if the loading fails
///    and no specific [onError] handling completes the future differently.
///  - [onError]: An optional callback function that is invoked if an error
///    occurs during the loading process (e.g., network error, file not found).
///    It receives the error [Event]. If provided, this callback is responsible
///    for completing the future or allowing it to complete with [defaultValue].
///  - [onLoad]: An optional callback function that is invoked when the file has
///    been successfully loaded. It receives the raw [JSAny] response, a `completer`
///    function `Function(T)` to complete the Future with the processed data, and
///    an `onError` function `void Function(Event event)` to handle errors during processing.
///    This callback is responsible for processing the raw response and calling the
///    `completer` function with the final result of type [T].
///
/// Returns a [Future<T>] that completes with the processed file content.
/// If loading fails, it completes with [defaultValue] or as determined by [onError].
Future<T> load<T>(
  String path,
  Loader loadingInfo, {
  String responseType = "text",
  T? defaultValue,
  void Function(Event event)? onError,
  Function(JSAny response, Function(T) completer, void Function(Event event) onError)? onLoad,
}) async {
  var loadingState = loadingInfo.add(path);
  final completer = Completer<T>();
  final xhr = XMLHttpRequest();

  void progress(ProgressEvent event) {
    if (event.lengthComputable) {
      loadingState.loaded = event.loaded;
      loadingState.total = event.total;
      loadingState.completedOrFailed = event.type == 'loadend';
    }
  }

  void complete(T result) {
    completer.complete(result);
    loadingState.completedOrFailed = true;
  }

  void error(Event event) {
    warn("Could not load: $path (${xhr.status} : ${xhr.statusText})");
    loadingState.completedOrFailed = true;
    onError?.call(event);
    completer.complete(defaultValue);
  }

  void load(Event event) {
    if (xhr.status >= 200 && xhr.status < 300) {
      onLoad?.call(xhr.response!, complete, error);
    } else {
      error(event);
    }
  }

  xhr.open('GET', path);
  xhr.responseType = responseType;
  xhr.addEventListener('progress', progress.toJS);
  xhr.addEventListener('loadstart', progress.toJS);
  xhr.addEventListener('loadend', progress.toJS);
  xhr.addEventListener('load', load.toJS);
  xhr.addEventListener('error', error.toJS);
  xhr.addEventListener('abort', error.toJS);
  xhr.send();

  return completer.future;
}
