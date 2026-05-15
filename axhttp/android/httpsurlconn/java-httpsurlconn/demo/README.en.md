# AgentSDK Quickstart: Android Java HttpsURLConnection

English | [简体中文](./README.md)

This quickstart is written specifically for native Android apps that are written in Java and use `HttpsURLConnection` for making the API calls that you wish to protect with AgentSDK. If this is not your situation then check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating AgentSDK into your app. Additionally, a step-by-step tutorial guide using our [java-httpsurlconn-demo](java-httpsurlconn-demo/) is also available.

## Adding AgentSDK Service Dependency

Add the dependency in your app's `build.gradle`:

```groovy
dependencies {
    implementation fileTree(include: ['*.jar', '*.aar'], dir: 'libs')
}
```

Then copy `axsecurity-android-httpsurlconn.aar` and `axsecurity-android-sdk.aar` to your app's `libs/` directory:

```
app/
└── libs/
    ├── axsecurity-android-httpsurlconn.aar
    └── axsecurity-android-sdk.aar
```

## Manifest Changes

The following app permissions need to be available in the manifest to use AgentSDK:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

Note that the minimum SDK version you can use with the AgentSDK package is 21 (Android 5.0).

## Initializing AXHTTPService

In order to use the `AXHTTPService` you must initialize it when your app is created, usually in the `onCreate` method:

```java
import android.app.Application;
import android.util.Log;

import com.axsecurity.sdk.axhttp.httpsurlconn.AXHTTPService;
import com.axsecurity.sdk.base.Config;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();

        String accessKeyID = "your accessKeyID from SDK Deployment";
        String accessKeySecret = "your accessKeySecret from SDK Deployment";
        String[] edgeAddresses = {"edge IP"};

        Config config = new Config.Builder()
            .accessKeyID(accessKeyID)
            .accessKeySecret(accessKeySecret)
            .edgeAddresses(edgeAddresses)
            .build();

        int result = AXHTTPService.initialize(this.getApplicationContext(), config);
        if (result != 0) {
            Log.e("MyApp", "AgentSDK initialization failed: " + result);
        }
    }
}
```

The `initialize` method returns `0` on success or a negative error code on failure:

> **Important:** `initialize` must be called exactly once before any other `AXHTTPService` method. Calling it more than once is not supported.

## Parameter Reference

| Parameter | Description |
|-----------|-------------|
| `Config.Builder().accessKeyID(...)` | AccessKey ID (required), obtained from the console |
| `Config.Builder().accessKeySecret(...)` | AccessKey Secret (required), obtained from the console |
| `Config.Builder().edgeAddresses(...)` | List of Edge node addresses (required); pass a `String[]`; at least 1, 2+ recommended |

This demo uses the minimum required fields. The full `Config.Builder` option set (DNS configuration, encrypted tunnel toggle, etc.) and parameter semantics are documented in the AgentSDK integration guide.

## Using AXHTTPService

You can then make `HttpsURLConnection` API calls by using the connection available from the `AXHTTPService`:

```java
URL url = new URL("https://example.com");
HttpsURLConnection connection = AXHTTPService.getHttpsURLConnection(url);
```

This returns a standard `HttpsURLConnection` bound to the target URL and routed through AgentSDK's local HTTP proxy via an HTTPS CONNECT tunnel. Configure headers, request method, timeouts, etc. on it as you would with a non-proxied `HttpsURLConnection`.

## Customizing HttpsURLConnection

By default, `getHttpsURLConnection(url)` returns an `HttpsURLConnection` with the local proxy already set. TLS is negotiated end-to-end between your app and the origin server; the proxy does not terminate TLS. All connection-level customization is performed directly on the returned instance, just as you would with a non-proxied connection. For example, if you have existing code:

```java
HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
connection.setConnectTimeout(5_000);
connection.setReadTimeout(5_000);
```

Replace it with:

```java
HttpsURLConnection connection = AXHTTPService.getHttpsURLConnection(url);
connection.setConnectTimeout(5_000);
connection.setReadTimeout(5_000);
```

> **Note:** Each call to `getHttpsURLConnection(url)` returns a new connection instance. Apply any per-request configuration on the returned object.

If your app needs custom SSL/TLS settings (e.g. certificate pinning), configure them directly on the returned connection:

```java
HttpsURLConnection connection = AXHTTPService.getHttpsURLConnection(url);
connection.setSSLSocketFactory(yourSslSocketFactory);
connection.setHostnameVerifier(yourHostnameVerifier);
```

## Error Handling

`AXHTTPService.getHttpsURLConnection(url)` returns `null` if the SDK is not initialized or the local proxy is not available. Always check the return value before making requests:

```java
HttpsURLConnection connection = AXHTTPService.getHttpsURLConnection(url);
if (connection == null) {
    // SDK not ready — check initialization result or retry later
    return;
}
```

Network errors during API calls are reported as standard `IOException`s thrown by `HttpsURLConnection` methods. Handle them as you normally would:

```java
try {
    connection.setRequestMethod("GET");
    connection.connect();
    int code = connection.getResponseCode();
    // handle response
} catch (IOException e) {
    // network error — check connectivity and retry if appropriate
} finally {
    connection.disconnect();
}
```

## Checking It Works

After integrating the SDK, run your app and check Logcat for the `AXHTTPService` tag. On a successful integration you should see:

1. No error logs from `AXHTTPService` during initialization.
2. API requests going through the SDK's local proxy and returning expected responses.

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `initialize` returns `-1` | Invalid credentials or unreachable Edge | Verify `accessKeyID`, `accessKeySecret`, and `edgeAddresses` |
| `getHttpsURLConnection()` returns `null` | SDK not initialized or proxy not ready | Ensure `initialize` returned `0` before calling `getHttpsURLConnection()` |
| `Local HTTP proxy not available` in Logcat | Internal proxy failed to start | Check network permissions and Edge connectivity |
