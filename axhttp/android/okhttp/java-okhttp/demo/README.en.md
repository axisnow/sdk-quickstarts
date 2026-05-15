# AgentSDK Quickstart: Android Java OkHttp

English | [简体中文](./README.md)

This quickstart is written specifically for native Android apps that are written in Java and use OkHttp for making the API calls that you wish to protect with AgentSDK. If this is not your situation then check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating AgentSDK into your app. Additionally, a step-by-step tutorial guide using our [java-okhttp-demo](java-okhttp-demo/) is also available.

## Adding AgentSDK Service Dependency

Add the dependency in your app's `build.gradle`:

```groovy
dependencies {
    implementation fileTree(include: ['*.jar', '*.aar'], dir: 'libs')
}
```

Then copy `axsecurity-android-okhttp.aar` and `axsecurity-android-sdk.aar` to your app's `libs/` directory:

```
app/
└── libs/
    ├── axsecurity-android-okhttp.aar
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

import com.axsecurity.sdk.axhttp.okhttp.AXHTTPService;
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

You can then make OkHttp API calls by using the `OkHttpClient` available from the `AXHTTPService`:

```java
OkHttpClient client = AXHTTPService.getOkHttpClient();
```

This returns a cached `OkHttpClient` with AgentSDK's local proxy automatically configured. Use this client for all API calls that you wish to protect.

## Custom OkHttp Builder

By default, `getOkHttpClient()` constructs a client with `new OkHttpClient.Builder()`. However, your existing code may use a customized client with, for instance, different timeouts or other interceptors. For example, if you have existing code:

```java
OkHttpClient client = new OkHttpClient.Builder()
    .connectTimeout(5, TimeUnit.SECONDS)
    .build();
```

Pass the modified builder to the `AXHTTPService` framework as follows:

```java
AXHTTPService.setOkHttpClientBuilder(
    new OkHttpClient.Builder().connectTimeout(5, TimeUnit.SECONDS));
OkHttpClient client = AXHTTPService.getOkHttpClient();
```

> **Note:** Calling `setOkHttpClientBuilder` invalidates the cached client. A new one will be built on the next `getOkHttpClient()` call.

If your app needs custom SSL/TLS settings (e.g. certificate pinning), configure them directly on the `OkHttpClient.Builder` before passing it:

```java
OkHttpClient.Builder builder = new OkHttpClient.Builder()
    .connectTimeout(5, TimeUnit.SECONDS)
    .sslSocketFactory(yourSslSocketFactory, yourTrustManager)
    .hostnameVerifier(yourHostnameVerifier);
AXHTTPService.setOkHttpClientBuilder(builder);
OkHttpClient client = AXHTTPService.getOkHttpClient();
```

## Error Handling

`AXHTTPService.getOkHttpClient()` returns `null` if the SDK is not initialized or the local proxy is not available. Always check the return value before making requests:

```java
OkHttpClient client = AXHTTPService.getOkHttpClient();
if (client == null) {
    // SDK not ready — check initialization result or retry later
    return;
}
```

Network errors during API calls are reported as standard OkHttp `IOException`s. Handle them as you normally would:

```java
client.newCall(request).enqueue(new Callback() {
    @Override
    public void onResponse(Call call, Response response) throws IOException {
        // handle response
    }

    @Override
    public void onFailure(Call call, IOException e) {
        // network error — check connectivity and retry if appropriate
    }
});
```

## Checking It Works

After integrating the SDK, run your app and check Logcat for the `AXHTTPService` tag. On a successful integration you should see:

1. No error logs from `AXHTTPService` during initialization.
2. API requests going through the SDK's local proxy and returning expected responses.

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `initialize` returns `-1` | Invalid credentials or unreachable Edge | Verify `accessKeyID`, `accessKeySecret`, and `edgeAddresses` |
| `getOkHttpClient()` returns `null` | SDK not initialized or proxy not ready | Ensure `initialize` returned `0` before calling `getOkHttpClient()` |
| `Local HTTP proxy not available` in Logcat | Internal proxy failed to start | Check network permissions and Edge connectivity |
