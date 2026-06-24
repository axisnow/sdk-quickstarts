# SDK Quickstart: Flutter WebView (flutter_inappwebview)

English | [简体中文](./README.md)

This quickstart is written for Flutter apps that load web pages with
[`flutter_inappwebview`](https://pub.dev/packages/flutter_inappwebview). It shows
how to route the WebView's traffic through the AxSecurity SDK local proxy, so it
gains scheduling, acceleration, EdgeDoH anti-hijack resolution, and SecureProxy
tunnel encryption.

There is a single entry point, `AxService.installOnWebView(controller)`: it
enables the SDK proxy on the WebView (process-wide on Android; the default
`WKWebsiteDataStore` on iOS 17+) and **does not take over any of your
callbacks** — your `InAppWebView` stays fully under your control.

> **Builds out of the box**: this sample ships **without the SDK** — all SDK
> integration code is commented out and it compiles/runs on
> `flutter_inappwebview` alone (a plain WebView skeleton). Uncomment the steps
> below to integrate.

## Enabling the SDK (three uncomments)

1. **`pubspec.yaml`**: uncomment the `axsecurity_flutter_plugin` dependency, then
   run `flutter pub get`.
   > This dependency transitively pulls in `flutter_inappwebview` and requires
   > **Android `compileSdk 34` and iOS 12+** (already configured in this
   > project).

2. **Top of `lib/main.dart`**: uncomment the two
   `import 'package:axsecurity_flutter_plugin/...'` lines.

3. **Initialize + install the proxy**: uncomment `AxService.initialize(...)` in
   `main()` and `AxService.installOnWebView(controller)` in `_setUpAndLoad`.

## Initializing AxService

Initialize exactly once, **before the first WebView load** (do it in `main()`):

```dart
WidgetsFlutterBinding.ensureInitialized();
await AxService.initialize(config: AxConfig(
  accessKeyId: '<YOUR_ACCESS_KEY_ID>',
  accessKeySecret: '<YOUR_ACCESS_KEY_SECRET>',
  edgeNodes: ['<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>'],
  dns: AxDnsConfig(edgeDohResolveDomains: ['<YOUR_DOMAIN>']),
  proxy: AxProxyConfig(secureProxyEnabled: true),
));
```

`initialize` returns `0` on success and a negative code on failure. **With no
`edgeDohResolveDomains` allowlist configured, every host goes through system
DNS** — add the hosts that need EdgeDoH protection explicitly.

## Installing the proxy on the WebView (the ordering contract)

In `onWebViewCreated`, **`await installOnWebView` first, then `loadUrl`**, and do
**not** set `initialUrlRequest` on the `InAppWebView`:

```dart
InAppWebView(
  // No initialUrlRequest — otherwise it would start loading before the proxy applies
  onWebViewCreated: (controller) async {
    final rc = await AxService.installOnWebView(controller); // 1. install (in effect once awaited)
    await controller.loadUrl(                                // 2. then load
      urlRequest: URLRequest(url: WebUri(url)),
    );
  },
)
```

Why this order: once the `await` returns, the proxy is in place, so the first
request cannot leak direct; and a future "request signing" capability will inject
a document-start fetch/XHR bridge inside `installOnWebView`, which can only cover
the first screen if it is installed before the first load. **Your integration
code needs no changes for that future signing capability** — the signing policy
is configured uniformly through `AxService.initialize(...)`.

## Result codes

`installOnWebView` does not throw; it returns an `int`:

| Code | Meaning |
|------|---------|
| `0` | Success — traffic now goes through the SDK proxy |
| `-101` | SDK not initialized / local proxy unavailable (confirm `initialize` returned 0) |
| `-401` | Android: the device WebView lacks `PROXY_OVERRIDE`, or `androidx.webkit` is missing at runtime |
| `-411` | iOS below 17 (`proxyConfigurations` unavailable) |

## Running

```bash
flutter pub get
flutter run                 # or task flutter:android:webview-demo / flutter:ios:webview-demo
```

> Android builds need JDK 17 (when Gradle 7.5 is incompatible with Flutter's
> default JDK 21, run `flutter config --jdk-dir <JDK17>`).

## Known limitations

- **Process-wide / default store**: once enabled on Android it affects every
  WebView in the process; on iOS it only covers the default
  `WKWebsiteDataStore` — an inappwebview created with `incognito: true` (a
  non-persistent store) or a custom store is **not** covered, and cannot be
  retrofitted (the instance is not reachable).
- **iOS 17+ only**: below 17 there is no proxy (returns `-411`).
- **Request signing / header rewriting**: not provided in this phase. Under
  HTTPS the proxy is a CONNECT tunnel and cannot alter request headers; this
  capability is planned for a later release and is entirely an internal addition
  to the wrapper — your integration code (still `installOnWebView`) needs no
  changes.
- **Protocols**: HTTP/HTTPS/WebSocket are forwarded via HTTP CONNECT; WebRTC,
  QUIC/HTTP3 (UDP), etc. do not go through the proxy.
