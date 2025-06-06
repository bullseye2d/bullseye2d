import 'package:bullseye2d/bullseye2d.dart';
import 'package:web/web.dart';
import 'dart:js_interop';
import 'dart:js_util'; // ignore: deprecated_member_use
export 'dart:developer' show debugger;

//TODO: put everything in Logger class, but exposed global log method for easier usaage :)

final List<String> _logStack = [];
String _filterText = '';
bool _filterInverse = false;
bool _logStackTrace = false;

enum _Verbosity { nothing, info, warn, error, die }

/// {@category Debug}
/// Accepts a variable number of arguments for logging.
///
/// **Tag Management:**
/// *   **Pushing Tags:** If the first argument is a string starting with one or
///     more tags like `[Tag1][Tag2]`, these tags are pushed onto the `tag stack`.
///     The stack (`[Tag1::Tag2]`) is prepended to subsequent log messages.
/// *   **Popping Tags:** Calling `log()` with no arguments pops the most recent
///     tag from the `tag stack`.
/// *   **Temporary Tags:** If the first argument is a string like `[TempTag] :: message`,
///     `TempTag` is pushed onto the stack *only* for the duration of this single
///     log call. The stack state is restored afterwards.
/// *   **Tag-Only Calls:** Calls like `log('[PersistentTag]')` will push the tag
///     onto the stack permanently without printing any message.
/// *   If the first tag in a message is currently already on the top of the `tag stack`
///     it won't be pushed again.
///
/// **Output:**
/// *   The current tag stack (`[Tag1::Tag2] `) is always prepended to the message.
/// *   All arguments are converted to strings and joined with spaces.
/// *   Output is subject to filtering configured via `logFilter`.
final log = VarargsFunction(_log) as dynamic;

/// {@category Debug}
/// Behaves the same as [log], but uses info verbosity
final info = VarargsFunction(_info) as dynamic;

/// {@category Debug}
/// Behaves the same as [log], but uses warn verbosity
final warn = VarargsFunction(_warn) as dynamic;

/// {@category Debug}
/// Behaves the same as [log], but uses error verbosity
final error = VarargsFunction(_error) as dynamic;

/// {@category Debug}
/// Behaves the same as [error], but stops the application / launches the debugger
final die = VarargsFunction(_die) as dynamic;

/// {@category Debug}
/// Clears the tag stack
logReset() {
  _logStack.clear();
}

/// {@category Debug}
/// Disables all logging output
logOff() {
  logFilter("!");
}

/// {@category Debug}
/// Enables all logging output
logOn() {
  logFilter("");
}

/// {@category Debug}
/// Prepend source location to all messages
///
/// If set to true it shows the location from where the log message
/// is called from.
logEnableStacktrace(bool enable) {
  _logStackTrace = enable;
}

/// {@category Debug}
/// Configures log output filtering.
///
/// [filter]:
///   - If `null` or empty (`''`), all filtering is disabled, and all messages are shown.
///   - If non-empty and *not* starting with `!`, only log messages containing
///     this exact string will be shown.
///   - If non-empty and starting with `!`, only log messages *not* containing
///     the rest of the string (after `!`) will be shown (inverse filtering).
logFilter([String? filter]) {
  if (filter == null || filter.isEmpty) {
    _filterText = '';
    _filterInverse = false;
  } else {
    if (filter.startsWith('!')) {
      _filterInverse = true;
      _filterText = filter.substring(1);
    } else {
      _filterInverse = false;
      _filterText = filter;
    }
    if (_filterText.isEmpty) {
      _filterInverse = false;
    }
  }
}

_info(List arguments) {
  _log(arguments, _Verbosity.info);
}

_error(List arguments) {
  _log(arguments, _Verbosity.error);
}

_die(List arguments) {
  _log(arguments, _Verbosity.die);
}

_warn(List arguments) {
  _log(arguments, _Verbosity.warn);
}

String _formatStack() {
  if (_logStack.isEmpty) {
    return '';
  }
  return '[${_logStack.join('::')}]';
}

_log(List arguments, [_Verbosity verbosity = _Verbosity.nothing]) {
  if (arguments.isEmpty) {
    if (_logStack.isNotEmpty) {
      _logStack.removeLast();
    }
    return;
  }

  if (_logStackTrace) {
    final trace = StackTrace.current;
    final traceString = trace.toString();
    final lines = traceString.split('\n');
    var stacktrace = (lines.length < 5) ? '' : lines[4].replaceAllMapped(RegExp(r'^(.+?)\s(\d+):.*'), (match) => '[${match.group(1)!}:${match.group(2)!}]');
    if (stacktrace != "") {
      stacktrace = stacktrace.replaceFirst('bullseye/src/', '');
      arguments = ['$stacktrace :: ', ...arguments];
    }
  }

  List<String>? initialStackState;
  bool isTemporary = false;
  List<String> extractedTags = [];
  String firstArgStringContent = '';
  List<dynamic> remainingArgs = [];

  if (arguments[0] is String) {
    String currentArg = arguments[0] as String;
    String parseCursor = currentArg;

    final tagPattern = RegExp(r'^\[([^\]]+)\]');
    RegExpMatch? tagMatch;
    while ((tagMatch = tagPattern.firstMatch(parseCursor)) != null) {
      extractedTags.add(tagMatch!.group(1)!);
      parseCursor = parseCursor.substring(tagMatch.end);
    }

    final separatorPattern = RegExp(r'^\s*(::)\s*(.*)');
    final separatorMatch = separatorPattern.firstMatch(parseCursor);

    if (separatorMatch != null && extractedTags.isNotEmpty) {
      isTemporary = true;
      initialStackState = List.from(_logStack);
      firstArgStringContent = separatorMatch.group(2)!;
    } else {
      firstArgStringContent = parseCursor;
    }

    remainingArgs = arguments.sublist(1);
  } else {
    remainingArgs = arguments;
  }

  if (extractedTags.isNotEmpty) {
    for (final tag in extractedTags) {
      if (_logStack.isEmpty || _logStack.last != tag) {
        _logStack.add(tag);
      }
    }
  }

  bool onlyPermanentTagPush = extractedTags.isNotEmpty && firstArgStringContent.trim().isEmpty && remainingArgs.isEmpty && !isTemporary && arguments.length == 1 && arguments[0] is String;

  if (onlyPermanentTagPush) {
    return;
  }

  final String currentStackPrefix = _formatStack();

  String potentialOutputForFilter = currentStackPrefix;
  if (firstArgStringContent.isNotEmpty || remainingArgs.isNotEmpty) {
    potentialOutputForFilter += ' ';
  }
  potentialOutputForFilter += firstArgStringContent;
  if (firstArgStringContent.isNotEmpty && remainingArgs.isNotEmpty) {
    potentialOutputForFilter += ' ';
  }
  potentialOutputForFilter += remainingArgs.map((a) => a.toString()).join(' ');

  bool shouldPrintLog = true;
  if (_filterText.isNotEmpty) {
    bool containsFilter = potentialOutputForFilter.contains(_filterText);
    shouldPrintLog = _filterInverse ? !containsFilter : containsFilter;
  }

  if (shouldPrintLog && potentialOutputForFilter.trim().isNotEmpty) {
    final List<JSAny?> argsToLog = [];

    if (currentStackPrefix.isNotEmpty) {
      argsToLog.add(currentStackPrefix.toJS);
    }

    if (firstArgStringContent.isNotEmpty) {
      argsToLog.add(firstArgStringContent.toJS);
    }

    for (final arg in remainingArgs) {
      argsToLog.add(jsify(arg));
    }

    String consoleMethod;
    switch (verbosity) {
      case _Verbosity.error:
      case _Verbosity.die:
        consoleMethod = 'error';
        break;

      case _Verbosity.warn:
        consoleMethod = 'warn';
        break;

      case _Verbosity.info:
        consoleMethod = 'info';
        break;

      case _Verbosity.nothing:
        consoleMethod = 'log';
        break;
    }

    callMethod(console, consoleMethod, argsToLog);
    if (verbosity == _Verbosity.die) {
      // this will ensure that even if a die/exception is thrown from within
      // an async thread it will still stop execution of the app
      // debugger();
      throw Exception("Critical Error!");
    }
  }

  if (isTemporary && initialStackState != null) {
    _logStack.clear();
    _logStack.addAll(initialStackState);
  }
}
