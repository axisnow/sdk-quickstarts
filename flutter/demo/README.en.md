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
    var accessKeyId = 'your accessKeyId from SDK Deployment';
    var accessKeySecret = 'your accessKeySecret from SDK Deployment';
    var edgeNodes = ['edge IP'];

    AxConfig cfg = AxConfig(
        accessKeyId: accessKeyId,
        accessKeySecret: accessKeySecret,
        edgeNodes: edgeNodes,
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

## Parameter Reference

| Parameter | Description |
|-----------|-------------|
| `AxConfig(accessKeyId: ...)` | AccessKey ID (required), obtained from the console |
| `AxConfig(accessKeySecret: ...)` | AccessKey Secret (required), obtained from the console |
| `AxConfig(edgeNodes: ...)` | List of Edge node addresses (required); `List<String>`; at least 1, 2+ recommended |
| `AxConfig(dns: ...)` | DNS configuration (optional); construct an `AxDnsConfig`. Whitelist hosts for EdgeDoH via `addEdgeDohResolveDomain(...)` (or pass `edgeDohResolveDomains: [...]`); exempt specific hosts via `addEdgeDohBypassDomain(...)` (bypass takes priority over the whitelist). Patterns are exact or `*.suffix` wildcards. **Without a whitelist, all hosts resolve via the OS DNS resolver** — explicitly add hosts you want to protect via EdgeDoH. |
| `AxConfig(secureProxyEnabled: ...)` | Encrypted tunnel toggle (optional); enabled by default; pass `false` to disable |

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
