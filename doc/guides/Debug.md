# Debug Module

Bullseye2D includes a flexible logging utility. 

## Variable number of arguments

All `log*` functions accept a variable number of arumgents, so you can easily chain them together.

```dart
log("The player object", player);
// Output: The player object [Player ↓]
```

If one of the arguments is an object it will dumped as a JS-Object to the developer console, so you can examine it in detail (Dart's print function only prints a ref id in this case in general, which is not very useful).

## Easy to use tag stack

You can push and pop tags on the logging stack. This way you can add a category to the output without repeating it again and again. For pushing tags you start your message with a catgegory inside `[]` brackets.

```dart
log("[MyCategory] First message");
// Output: [MyCategory] First message

log("Second message")
// Output: [MyCategory] Second message

log();
// No output, pops 'MyCategory' from Stack

log("Other Message");
// Output: Other message


log("[TempCategory] :: Hello World");
// Output: [TempCategory] Hello World
// The '::' after the category tells, that
// you don't want to push the category on the stack

// [TempCategory] is NOT used in next log message
log("280");
// Output: 280
```

## Dynamic filtering

You can filter log messages:

```dart
logFilter("some Text");
log("This will not print anything to the developer console");
log("This will print some Text to the console");

logFilter("!any Text");
log("This will be printed to the developer console");
log("This won't print any text to the console");

logOn();  // Show all messages again
logOff(); // Dont show any log messages

log("[Player] Player spawned");
// Outputs: [Player] Player spawned;

log("[AI] Player AI created");
// Outputs: [Player][AI] Player AI created

logReset() // will clear the tag stack again
```

## Enable Stacktrace

You can add the location where each log message is called from:

```dart
logEnableStackTrace(true);
```

This could be of use if you're looking for a message in your code, but can't remember exectly from where it comes from.

## Verbosity

There are different verbosity levels of `log` functions. They use the build in levels of the browser, so you can also filter them in your developer console.


| Function     | Description                                                                             |
|--------------|-----------------------------------------------------------------------------------------|
| `log(...)`   | General purpose logging.                                                                |
| `info(...)`  | Informational messages.                                                                 |
| `warn(...)`  | Warnings.                                                                               |
| `error(...)` | Errors.                                                                                 |
| `die(...)`   | Critical errors; logs the message and then throws an exception to stop execution.       |

## Breakpoints

To manually trigger a breakpoint from code you can just call the `debugger` function in your code. The debugger will pause execution at exact this location.

```dart
debugger():
```

Some of these functions can also be achieved with the developer tools of your browser, but sometimes it's just easier to control it trough code.

