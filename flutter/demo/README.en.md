# SDK Quickstart: Flutter HTTP Client

English | [简体中文](./README.md)

This quickstart is written specifically for Android and iOS apps that are implemented using [`Flutter`](https://flutter.dev/) and the [`HTTP Client`](https://pub.dev/documentation/http/latest/http/Client-class.html), the [`Dart IO HttpClient`](https://api.dart.dev/stable/2.16.2/dart-io/HttpClient-class.html) or [`Dio`](https://pub.dev/packages/dio). If this is not your situation then please check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating SDK into your app. Additionally, a step-by-step tutorial guide using our App Example is also available.

## Adding SDK Service Dependency

The SDK provides local plugin project files. This allows inclusion into the project by simply specifying a dependency in the `pubspec.yaml` files for the app. In the `dependencies:` section of `pubspec.yaml` file add the following package reference:

```yaml
  axsecurity_flutter_plugin:
    path: ./../axsecurity_flutter_plugin
```

The `axsecurity_flutter_plugin` package provides a number of accessible classes:

1. `AxService` provides a higher level interface to the underlying SDK SDK.
2. `AxClient` which is a drop-in replacement for `Client` from the Flutter [http](https://pub.dev/packages/http) package and internally uses an `AxHttpClient` object.

### Android Manifest Changes

The following app permissions need to be available in the manifest to use SDK:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

Note that the minimum SDK version you can use with the SDK package is 21 (Android 5.0).

### iOS Framework Dependencies

Add the following frameworks/libraries to the **Link Binary with Libraries** section of your project's **Build Phases**:

1. `libz.tbd` — compression library
2. `libc++.tbd` — C++ standard library
3. `DeviceCheck.framework` — Apple's DeviceCheck framework
4. `CoreTelephony.framework` — Apple's CoreTelephony framework
5. `libresolv.tbd` — DNS resolution

The minimum supported iOS version is 12.0.

## Initializing AxService

In order to use `AxService` you must initialize it once during app startup, before any other `AxService` or `AxClient` calls:

```Dart
import 'package:axsecurity_flutter_plugin/axsecurity_flutter_plugin.dart';
import 'package:flutter/services.dart';

int? result;
// Platform messages may fail, so we use a try/catch PlatformException.
// We also handle the message potentially returning null.
try {
    AxConfig cfg = AxConfig(
        accessKeyId: '<YOUR_ACCESS_KEY_ID>',
        accessKeySecret: '<YOUR_ACCESS_KEY_SECRET>',
        edgeNodes: ['<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>'],
    );

    result = await AxService.initialize(config: cfg);
} on PlatformException {
    result = -1;
}
if (result == 0) {
    // initialize success
}
```

`initialize` returns `0` on success or a negative error code on failure.

> **Important:** `initialize` must be called exactly once before any other `AxService` or `AxClient` operation. Calling it more than once is not supported.

> **Tip:** If you call `AxService.initialize` inside `main()` before `runApp()`, you must call `WidgetsFlutterBinding.ensureInitialized()` first. `AxService` talks to the native layer over a platform channel, which is unavailable until the binding is ready; otherwise it throws `Null check operator used on a null value` and the app launches to a blank screen:
>
> ```Dart
> void main() async {
>   WidgetsFlutterBinding.ensureInitialized();
>   // ... AxService.initialize(config: cfg) ...
>   runApp(const MyApp());
> }
> ```

## Parameter Reference

| Parameter | Description |
|-----------|-------------|
| `AxConfig(accessKeyId: ...)` | AccessKey ID (required), obtained from the console |
| `AxConfig(accessKeySecret: ...)` | AccessKey Secret (required), obtained from the console |
| `AxConfig(edgeNodes: ...)` | EIP(s) or domain(s) pointing to the AxisNow Edge DoH service (required); `List<String>`; at least 1, 2+ recommended |
| `AxConfig(dns: ...)` | DNS configuration (optional); construct an `AxDnsConfig`. Pass `edgeDohResolveDomains: [...]` to whitelist hosts for EdgeDoH; pass `edgeDohBypassDomains: [...]` to exempt specific hosts (bypass takes priority over the whitelist). Patterns are exact or `*.suffix` wildcards. **Without a whitelist, all hosts resolve via the OS DNS resolver** — explicitly add hosts you want to protect via EdgeDoH. |

For full parameter semantics, constraints, and default behavior, see Appendix A of the integration guide.

## Using SDK With HTTP Client

The `AxClient` declared in the `axsecurity_flutter_plugin` package can be used as a drop-in replacement for [`HTTP Client`](https://pub.dev/documentation/http/latest/http/Client-class.html) from the Flutter http package. It handles requests the same way as the standard client, but with the additional protection provided by SDK.

After creating the `AxClient` you can perform requests and await responses as normal, for example:

```Dart
http.Client client = AxClient();
http.Response response = await client.get(Uri.parse('https://your.domain/api'));
```

## Using SDK With Dio

It is also possible to use SDK with the [`Dio`](https://pub.dev/packages/dio) networking stack, since it uses `HttpClient` internally. When constructing a `Dio` object you need to override the underlying client used as follows:

```Dart
import 'package:dio/adapter.dart';
...
var dio = Dio();
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
  return AxHttpClient();
};
```

After creating the `Dio` you can perform requests and await responses as normal, for example:

```Dart
var response = await dio.get('https://your.domain/api');
```

## Using SDK With WebSocket

A WebSocket connection is established over an HTTP upgrade handshake, so routing it through the SDK only requires [`web_socket_channel`](https://pub.dev/packages/web_socket_channel) to use `AxHttpClient` as its underlying client — the handshake request then transparently goes through the SDK local proxy channel. Pass it via the `customClient` parameter of `IOWebSocketChannel.connect`:

```Dart
import 'package:web_socket_channel/io.dart';

final channel = IOWebSocketChannel.connect(
  Uri.parse('wss://your.domain/ws'),
  customClient: AxHttpClient(),
);
await channel.ready;

channel.sink.add('hello');
channel.stream.listen((data) {
  // handle server messages
});
```

Remember to close the connection when done:

```Dart
import 'package:web_socket_channel/status.dart' as ws_status;

await channel.sink.close(ws_status.normalClosure);
```

## Error Handling

`AxService.initialize` returns `null` if the platform channel call throws a `PlatformException`, or a negative integer if the native SDK rejects the configuration. Always check the return value before issuing any requests through `AxClient` or `AxHttpClient`:

```Dart
int? result;
try {
    result = await AxService.initialize(config: cfg);
} on PlatformException {
    result = -1;
}
if (result != 0) {
    // SDK not ready — check credentials, edge reachability, or retry later
    return;
}
```

Network errors during requests are surfaced through the standard http / Dio exception types. Handle them as you normally would:

```Dart
try {
    var response = await client.get(Uri.parse('https://your.domain/api'));
} on http.ClientException catch (e) {
    // network error — check connectivity and retry if appropriate
}
```

## Checking It Works

After integrating the SDK, run your app and watch the platform logs (Logcat on Android, Xcode console on iOS) for the `AXService` / `AXHTTPService` tags. On a successful integration you should see:

1. No error logs from `AXService` during initialization.
2. `AxService.initialize` resolves to `0`.
3. Requests issued via `AxClient` or `AxHttpClient` go through the SDK's local proxy and return expected responses.

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `initialize` returns a negative value | Invalid credentials or unreachable Edge | Verify `accessKeyId`, `accessKeySecret`, and `edgeNodes` |
| `initialize` resolves to `null` (`PlatformException`) | Native plugin not linked or build setup incomplete | Re-run `flutter pub get`; on iOS confirm the frameworks listed above are linked; on Android confirm the AAR is bundled |
| Requests time out or fail with `Connection refused` | Internal proxy failed to start | Check network permissions and Edge connectivity; ensure `initialize` returned `0` before issuing requests |

## Using the wrappers on the Android native layer (WebView / OkHttp / Retrofit)

This guide covers Flutter (Dart-layer) HTTP integration. If your Android project also uses `WebView`, `OkHttp`, or `Retrofit` on the **native layer** and you want that traffic to go through the SDK, the plugin bundles the matching native wrappers — but they are **off by default**. Enable the ones you need in your app's `android/gradle.properties`:

```properties
axsecurity.webview=true     # native WebView wrapper
axsecurity.okhttp=true      # native OkHttp wrapper
axsecurity.retrofit=true    # native Retrofit wrapper
```

With a flag set, the build pulls that wrapper's classes and runtime dependencies into your app. These flags affect the **Android native layer only**; the Dart networking above (http / Dio / WebSocket) needs none of them. See the "Bundled native wrappers" section of the plugin README for details.
