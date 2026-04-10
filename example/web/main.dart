import 'package:web/web.dart' show window;
import 'package:bullseye_examples/demo_app.dart';

void main() {
  var params = Uri.dataFromString(window.location.search).queryParameters;
  DemoApp(initialDemo: params['app'] ?? 'hello_world');
}
