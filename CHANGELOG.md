## 1.0.12

- Feature: Helper class added to easily save data in the browser's local storage
- Tweak: Use Matrix3 Pool in graphics module to reduce GC pressure
- Fix: Catch NotSupportedError on Audio Playback

## 1.0.11

- Code style improvements and formatting

## 1.0.10

- Feature: Added `drawImageRect` method for drawing source portions of images to destination rectangles with automatic stretching
- Tweak: Improved `Rect` class with type-safe return types (returns `T` instead of `num`) and added helper setters and methods
- Tweak: Removed automatic `frames.isLoading` checks in drawing commands for better performance - developers are now responsible for checking loading state
- `soko64` added to examples readme file

## 1.0.9

- Fixed: When game was embedded in iFrame and looses focus it wasn't possible for it to get the focus back which led to the problem that no events were reaching the app.

## 1.0.8

- Fixed: Typo in Examples Readme
- Fixed: Various Links in Api Doc fixed

## 1.0.7

- Fixed: When loading an image / a texture no mipmaps were generated after loading (if requested via texture flags)

## 1.0.6

- Formatted dart code. 

## 1.0.5

- Readme page for example added

## 1.0.4

- Added `View source code` button to demo page.

## 1.0.3

- Remove `example` command. It was a bad idea in the first place, because the way I've implemented it assumes it could be run from local dart cache and dart doesn't like this (for good reasons). So I removed the command for now.

## 1.0.2

- Fixes `Cannot operate on packages inside the cache.` error on `example` command.

## 1.0.1

- Fixes an issue with the `example` command of the `bullseye2d` cli tool.

## 1.0.0

- Initial version.
