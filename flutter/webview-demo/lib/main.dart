import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// *** UNCOMMENT FOR SDK *** (also uncomment axsecurity_flutter_plugin in pubspec.yaml)
// import 'package:axsecurity_flutter_plugin/axsecurity_flutter_plugin.dart';
// import 'package:axsecurity_flutter_plugin/config.dart';

void main() {
  // *** UNCOMMENT FOR SDK *** — initialize ONCE, before the first WebView load.
  // Make main() async and await it:
  //
  //   WidgetsFlutterBinding.ensureInitialized();
  //   await AxService.initialize(config: AxConfig(
  //     accessKeyId: '<YOUR_ACCESS_KEY_ID>',
  //     accessKeySecret: '<YOUR_ACCESS_KEY_SECRET>',
  //     edgeNodes: ['<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>'],
  //     dns: AxDnsConfig(edgeDohResolveDomains: ['<YOUR_DOMAIN>']),
  //     proxy: AxProxyConfig(secureProxyEnabled: true),
  //   ));
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'AxSecurity WebView Quickstart',
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  // Default URL loaded into the address bar — change to your test URL.
  static const _defaultUrl = 'https://example.com';

  final _urlCtl = TextEditingController(text: _defaultUrl);
  InAppWebViewController? _controller;

  @override
  void dispose() {
    _urlCtl.dispose();
    super.dispose();
  }

  /// Issues the first load. The SDK integration lives here: uncomment the marked
  /// lines (plus the import and the pubspec dependency) to route the WebView
  /// through the AxSecurity proxy.
  ///
  /// Order matters — install BEFORE the first load so the first request can't
  /// leak direct (and so a future request-signing bridge covers the first page).
  /// That is why this widget does NOT set `initialUrlRequest`, and why the
  /// controller is published (assigned to `_controller`) only AFTER install —
  /// otherwise a refresh / address-bar submit could fire `_load` before the
  /// proxy is in place.
  Future<void> _setUpAndLoad(InAppWebViewController controller) async {
    // *** UNCOMMENT FOR SDK *** — apply the proxy, then publish the controller.
    // Only rc == 0 means the proxy is in effect (load won't leak direct); a
    // negative code means it is NOT active — see the plugin README "Handling the
    // result" for how to react (retry -402, fail-open vs strict). This sample
    // loads regardless for simplicity.
    // final rc = await AxService.installOnWebView(controller);
    // debugPrint('AxSecurity installOnWebView rc=$rc');

    _controller = controller;
    await _load();
  }

  Future<void> _load() async {
    final url = _urlCtl.text.trim();
    if (url.isEmpty) return;
    await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlCtl,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                        hintText: 'URL',
                      ),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    tooltip: 'Load',
                    onPressed: _load,
                  ),
                ],
              ),
            ),
            Expanded(
              child: InAppWebView(
                // No initialUrlRequest: the first load is issued from
                // _setUpAndLoad, after the (optional) SDK proxy is installed.
                initialSettings: InAppWebViewSettings(
                  mixedContentMode:
                      MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
                ),
                onWebViewCreated: _setUpAndLoad,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
