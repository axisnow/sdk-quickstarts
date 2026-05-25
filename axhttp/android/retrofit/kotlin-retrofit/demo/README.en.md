# SDK Quickstart: Android Kotlin Retrofit

English | [简体中文](./README.md)

This quickstart is written specifically for native Android apps that are written in Kotlin and use Retrofit for making the API calls that you wish to protect with SDK. If this is not your situation then check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating SDK into your app. Additionally, a step-by-step tutorial guide using our [kotlin-retrofit-demo](kotlin-retrofit-demo/) is also available.

> **Note:** The Kotlin Retrofit integration reuses the Java Retrofit library artifact (`axsecurity-android-retrofit.aar`). There is no separate Kotlin-specific library module; the Kotlin code below calls the same `AXHTTPService` class published from `axhttp/android/retrofit/java-retrofit/lib`.

## Adding SDK Service Dependency

Add the dependency in your app's `build.gradle`:

```groovy
dependencies {
    implementation fileTree(include: ['*.jar', '*.aar'], dir: 'libs')
}
```

Then copy `axsecurity-android-retrofit.aar` and `axsecurity-android-sdk.aar` to your app's `libs/` directory:

```
app/
└── libs/
    ├── axsecurity-android-retrofit.aar
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

import com.axsecurity.sdk.axhttp.retrofit.AXHTTPService
import com.axsecurity.sdk.base.AXConfig
import com.axsecurity.sdk.service.AXService

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        val accessKeyId = "your accessKeyId from SDK Deployment"
        val accessKeySecret = "your accessKeySecret from SDK Deployment"
        val edgeNodes = arrayOf("edge IP")

        val config = AXConfig.Builder()
            .accessKey(accessKeyId, accessKeySecret)
            .edgeNodes(edgeNodes)
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
| `AXConfig.Builder().edgeNodes(...)` | List of Edge node addresses (required); pass an `Array<String>`; at least 1, 2+ recommended |

This demo uses the minimum required fields. The full `AXConfig.Builder` option set (DNS configuration, encrypted tunnel toggle, etc.) and parameter semantics are documented in the SDK integration guide.

## Using AXHTTPService

You can then make Retrofit API calls by using the `Retrofit` instance available from the `AXHTTPService`. Pass a long-lived `Retrofit.Builder` and cache the returned `Retrofit`:

```kotlin
object ClientInstance {
    private const val BASE_URL = "https://your.domain"
    private var retrofit: Retrofit? = null

    val retrofitInstance: Retrofit?
        get() {
            if (retrofit == null) {
                val builder = Retrofit.Builder()
                    .baseUrl(BASE_URL)
                    .addConverterFactory(GsonConverterFactory.create())
                retrofit = AXHTTPService.getRetrofit(builder)
            }
            return retrofit
        }
}
```

This returns a cached `Retrofit` instance with SDK's local proxy automatically configured. Use this instance for all API calls that you wish to protect.

> **Note:** Cache the returned `Retrofit` instance rather than the `Retrofit.Builder`. `AXHTTPService.getRetrofit` caches internally by builder reference identity, so passing a freshly constructed builder on each call leaks entries for the lifetime of the process.

## Custom OkHttp Builder

By default, `getRetrofit(builder)` constructs the underlying client with `OkHttpClient.Builder()`. However, your existing code may use a customized client with, for instance, different timeouts or other interceptors. For example, if you have existing code:

```kotlin
val client = OkHttpClient.Builder()
    .callTimeout(30, TimeUnit.SECONDS)
    .build()
val retrofit = Retrofit.Builder()
    .baseUrl("https://your.domain/")
    .client(client)
    .build()
```

Pass the modified builder to the `AXHTTPService` framework as follows:

```kotlin
AXHTTPService.setOkHttpClientBuilder(
    OkHttpClient.Builder().callTimeout(30, TimeUnit.SECONDS))
val retrofitBuilder = Retrofit.Builder()
    .baseUrl("https://your.domain/")
val retrofit = AXHTTPService.getRetrofit(retrofitBuilder)
```

> **Note:** Calling `setOkHttpClientBuilder` invalidates the cached client. A new one will be built on the next `getRetrofit()` call.

If your app needs custom SSL/TLS settings (e.g. certificate pinning), configure them directly on the `OkHttpClient.Builder` before passing it:

```kotlin
val builder = OkHttpClient.Builder()
    .callTimeout(30, TimeUnit.SECONDS)
    .sslSocketFactory(yourSslSocketFactory, yourTrustManager)
    .hostnameVerifier(yourHostnameVerifier)
AXHTTPService.setOkHttpClientBuilder(builder)
val retrofitBuilder = Retrofit.Builder()
    .baseUrl("https://your.domain/")
val retrofit = AXHTTPService.getRetrofit(retrofitBuilder)
```

## Error Handling

`AXHTTPService.getRetrofit(builder)` returns `null` if the SDK is not initialized or the local proxy is not available. Always check the return value before making requests:

```kotlin
val retrofit = AXHTTPService.getRetrofit(builder)
if (retrofit == null) {
    // SDK not ready — check initialization result or retry later
    return
}
```

Network errors during API calls are reported as standard Retrofit/OkHttp `IOException`s. Handle them as you normally would:

```kotlin
apiService.getResource().enqueue(object : Callback<Resource> {
    override fun onResponse(call: Call<Resource>, response: Response<Resource>) {
        // handle response
    }

    override fun onFailure(call: Call<Resource>, t: Throwable) {
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
| `getRetrofit()` returns `null` | SDK not initialized or proxy not ready | Ensure `initialize` returned `0` before calling `getRetrofit()` |
| `Local HTTP proxy not available` in Logcat | Internal proxy failed to start | Check network permissions and Edge connectivity |
