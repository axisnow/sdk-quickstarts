# SDK Quickstart: Android Kotlin OkHttp

English | [简体中文](./README.md)

This quickstart is written specifically for native Android apps that are written in Kotlin and use OkHttp for making the API calls that you wish to protect with SDK. If this is not your situation then check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating SDK into your app. Additionally, a step-by-step tutorial guide using our [kotlin-okhttp-demo](kotlin-okhttp-demo/) is also available.

## Adding SDK Service Dependency

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

The following app permissions need to be available in the manifest to use SDK:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

Note that the minimum SDK version you can use with the SDK package is 21 (Android 5.0).

## Initializing SDK

In order to use SDK you must initialize it when your app is created, usually in the `onCreate` method:

```kotlin
import android.app.Application
import android.util.Log

import com.axsecurity.sdk.axhttp.okhttp.AXHTTPService
import com.axsecurity.sdk.base.AXConfig
import com.axsecurity.sdk.service.AXService

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        val accessKeyId = "<YOUR_ACCESS_KEY_ID>"
        val accessKeySecret = "<YOUR_ACCESS_KEY_SECRET>"
        val edgeNodes = arrayOf("<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>")
        val routingDomain = "routing Domain"

        val config = AXConfig.Builder()
            .accessKey(accessKeyId, accessKeySecret)
            .edgeNodes(edgeNodes)
            .routingDomain(routingDomain)
            .build()

        val result = AXService.initialize(applicationContext, config)
        if (result != 0) {
            Log.e("MyApp", "SDK initialization failed: $result")
        }
    }
}
```

The `initialize` method returns `0` on success or a negative error code on failure:

> **Important:** `AXService.initialize` must be called exactly once before any `AXHTTPService` method. Calling it more than once is not supported.

## Parameter Reference

| Parameter | Description |
|-----------|-------------|
| `AXConfig.Builder().accessKey(...)` | AccessKey ID and Secret (required), obtained from the console |
| `AXConfig.Builder().edgeNodes(...)` | EIP(s) or domain(s) pointing to the AxisNow Edge DoH service (required); pass an `Array<String>`; at least 1, 2+ recommended |

This demo uses the minimum required fields. The full `AXConfig.Builder` option set (DNS configuration, encrypted tunnel toggle, etc.) and parameter semantics are documented in the SDK integration guide.

## Using AXHTTPService

You can then make OkHttp API calls by using the `OkHttpClient` available from the `AXHTTPService`:

```kotlin
val client = AXHTTPService.getOkHttpClient()
```

This returns a cached `OkHttpClient` with SDK's local proxy automatically configured. Use this client for all API calls that you wish to protect.

## Custom OkHttp Builder

By default, `getOkHttpClient()` constructs a client with `OkHttpClient.Builder()`. However, your existing code may use a customized client with, for instance, different timeouts or other interceptors. For example, if you have existing code:

```kotlin
val client = OkHttpClient.Builder()
    .callTimeout(30, TimeUnit.SECONDS)
    .build()
```

Pass the modified builder to the `AXHTTPService` framework as follows:

```kotlin
val builder = OkHttpClient.Builder().callTimeout(30, TimeUnit.SECONDS)
AXHTTPService.setOkHttpClientBuilder(builder)
val client = AXHTTPService.getOkHttpClient()
```

> **Note:** Calling `setOkHttpClientBuilder` invalidates the cached client. A new one will be built on the next `getOkHttpClient()` call.

If your app needs custom SSL/TLS settings (e.g. certificate pinning), configure them directly on the `OkHttpClient.Builder` before passing it:

```kotlin
val builder = OkHttpClient.Builder()
    .callTimeout(30, TimeUnit.SECONDS)
    .sslSocketFactory(yourSslSocketFactory, yourTrustManager)
    .hostnameVerifier(yourHostnameVerifier)
AXHTTPService.setOkHttpClientBuilder(builder)
val client = AXHTTPService.getOkHttpClient()
```

## Error Handling

`AXHTTPService.getOkHttpClient()` returns `null` if the SDK is not initialized or the local proxy is not available. Always check the return value before making requests:

```kotlin
val client = AXHTTPService.getOkHttpClient()
if (client == null) {
    // SDK not ready — check initialization result or retry later
    return
}
```

Network errors during API calls are reported as standard OkHttp `IOException`s. Handle them as you normally would:

```kotlin
client.newCall(request).enqueue(object : Callback {
    override fun onResponse(call: Call, response: Response) {
        // handle response
    }

    override fun onFailure(call: Call, e: IOException) {
        // network error — check connectivity and retry if appropriate
    }
})
```

## Checking It Works

After integrating the SDK, run your app and check Logcat for the `AXHTTPService` tag. On a successful integration you should see:

1. No error logs from `AXHTTPService` during initialization.
2. API requests going through the SDK's local proxy and returning expected responses.

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `initialize` returns `-1` | Invalid credentials or unreachable Edge | Verify `accessKeyId`, `accessKeySecret`, and `edgeNodes` |
| `getOkHttpClient()` returns `null` | SDK not initialized or proxy not ready | Ensure `initialize` returned `0` before calling `getOkHttpClient()` |
| `Local HTTP proxy not available` in Logcat | Internal proxy failed to start | Check network permissions and Edge connectivity |
