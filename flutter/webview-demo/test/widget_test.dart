import 'package:flutter_test/flutter_test.dart';

import 'package:axsecurity_webview_demo/main.dart';

void main() {
  // The page embeds a platform InAppWebView, which has no widget-test stub, so
  // a full pump would fail off-device. This smoke test only checks construction.
  testWidgets('MyApp constructs', (tester) async {
    const app = MyApp();
    expect(app, isA<MyApp>());
  });
}
