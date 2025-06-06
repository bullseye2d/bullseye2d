// ignore_for_file: constant_identifier_names
/// {@category Input}
/// Represents physical key codes
enum KeyCodes {
  // dart format off
  A('KeyA'), B('KeyB'), C('KeyC'), D('KeyD'), E('KeyE'),
  F('KeyF'), G('KeyG'), H('KeyH'), I('KeyI'), J('KeyJ'),
  K('KeyK'), L('KeyL'), M('KeyM'), N('KeyN'), O('KeyO'),
  P('KeyP'), Q('KeyQ'), R('KeyR'), S('KeyS'), T('KeyT'),
  U('KeyU'), V('KeyV'), W('KeyW'), X('KeyX'), Y('KeyY'),
  Z('KeyZ'),

  Digit0('Digit0'), Digit1('Digit1'), Digit2('Digit2'), Digit3('Digit3'),
  Digit4('Digit4'), Digit5('Digit5'), Digit6('Digit6'), Digit7('Digit7'),
  Digit8('Digit8'), Digit9('Digit9'),

  F1('F1'), F2('F2'), F3('F3'), F4('F4'), F5('F5'), F6('F6'), F7('F7'),
  F8('F8'), F9('F9'), F10('F10'), F11('F11'), F12('F12'),

  Up('ArrowUp'), Down('ArrowDown'), Left('ArrowLeft'), Right('ArrowRight'),

  Space('Space'), Enter('Enter'), Escape('Escape'), Tab('Tab'), Backquote('Backquote'),
  Quote('Quote'), Semicolon('Semicolon'), Comma('Comma'), Period('Period'),
  Slash('Slash'), Backslash('Backslash'), Minus('Minus'), Equal('Equal'),
  BracketLeft('BracketLeft'), BracketRight('BracketRight'),
  ShiftLeft('ShiftLeft'), ShiftRight('ShiftRight'), ControlLeft('ControlLeft'),
  ControlRight('ControlRight'), AltLeft('AltLeft'), AltRight('AltRight'),
  MetaLeft('MetaLeft'), MetaRight('MetaRight'),
  Backspace('Backspace'), Delete('Delete'), Insert('Insert'),
  Home('Home'), End('End'), PageUp('PageUp'), PageDown('PageDown'),

  Num0('Numpad0'), Num1('Numpad1'), Num2('Numpad2'), Num3('Numpad3'),
  Num4('Numpad4'), Num5('Numpad5'), Num6('Numpad6'), Num7('Numpad7'),
  Num8('Numpad8'), Num9('Numpad9'),
  NumAdd('NumpadAdd'), NumSubtract('NumpadSubtract'), NumMultiply('NumpadMultiply'),
  NumDivide('NumpadDivide'), NumDecimal('NumpadDecimal'), NumComma('NumpadComma'),
  NumEnter('NumpadEnter'), NumEqual('NumpadEqual'),

  Unknown('Unknown');
  // dart format on

  /// The string representation of the key code
  final String code;

  /// Constructs a [KeyCodes] enum value.
  const KeyCodes(this.code);

  static final Map<String, KeyCodes> _codeMap = {for (var key in KeyCodes.values) key.code: key};

  /// Converts a string `code` to its corresponding [KeyCodes] enum value.
  ///
  /// Returns [KeyCodes.Unknown] if the provided `code` does not match any known key code.
  static KeyCodes fromCode(String code) {
    return _codeMap[code] ?? KeyCodes.Unknown;
  }
}
