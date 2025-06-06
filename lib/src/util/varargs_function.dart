/// @nodoc
/// {@category Utility}
class VarargsFunction {
  VarargsFunction(this._onCall);

  final dynamic Function(List arguments) _onCall;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (!invocation.isMethod || invocation.namedArguments.isNotEmpty) {
      return super.noSuchMethod(invocation);
    }
    final arguments = invocation.positionalArguments;
    return _onCall(arguments);
  }
}
