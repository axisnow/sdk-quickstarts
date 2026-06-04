# SDK Quickstart: Android Java

English | [简体中文](./README.md)

This quickstart is written specifically for native Android apps that are written in Java and make HTTP(S) / SOCKS5 proxy-based API calls that you wish to protect with SDK. If this is not your situation then check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating SDK into your app. Additionally, a step-by-step tutorial guide using our [axsecurity-demo](axsecurity-demo/) is also available.

## Adding SDK Service Dependency

Add the dependency in your app's `build.gradle`:

```groovy
dependencies {
    implementation fileTree(include: ['*.jar', '*.aar'], dir: 'libs')
}
```

Then copy `axsecurity-android-sdk.aar` to your app's `libs/` directory:

```
app/
└── libs/
    └── axsecurity-android-sdk.aar
```

## Manifest Changes

The following app permissions need to be available in the manifest to use SDK:

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

Note that the minimum SDK version you can use with the SDK package is 21 (Android 5.0).

## Initializing AXService

In order to use the `AXService` you must initialize it when your app is created, usually in the `onCreate` method:

```java
import android.app.Application;
import android.util.Log;

import com.axsecurity.sdk.service.AXService;
import com.axsecurity.sdk.base.AXConfig;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();

        String accessKeyId = "<YOUR_ACCESS_KEY_ID>";
        String accessKeySecret = "<YOUR_ACCESS_KEY_SECRET>";
        String[] edgeNodes = {"<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>"};

        AXConfig config = new AXConfig.Builder()
            .accessKey(accessKeyId, accessKeySecret)
            .edgeNodes(edgeNodes)
            .dns(new AXConfig.DnsConfig.Builder()
                .edgeDohResolveDomains("*.example.com")
                .build())
            .build();

        int result = AXService.initialize(this.getApplicationContext(), config);
        if (result != 0) {
            Log.e("MyApp", "SDK initialization failed: " + result);
        }
    }
}
```

The `initialize` method returns `0` on success or a negative error code on failure.

> **Important:** `initialize` must be called exactly once before any other `AXService` method. Calling it more than once is not supported.

## Parameter Reference

| Parameter | Description |
|-----------|-------------|
| `AXConfig.Builder().accessKey(...)` | AccessKey ID and Secret (required), obtained from the console |
| `AXConfig.Builder().edgeNodes(...)` | EIP(s) or domain(s) pointing to the AxisNow Edge DoH service (required); pass a `String[]`; at least 1, 2+ recommended |
| `AXConfig.Builder().dns(...)` | DNS configuration (optional); construct via `AXConfig.DnsConfig.Builder`. Whitelist domains for EdgeDoH via `edgeDohResolveDomains(String...)`; exempt specific domains via `edgeDohBypassDomains(String...)` (bypass takes priority over whitelist). Both accept varargs or a `String[]`. Patterns are exact or `*.suffix` wildcards. **Without a whitelist, all domains resolve via the system DNS** — explicitly add domains you want to protect via EdgeDoH. |

For full parameter semantics, constraints, and default behavior, see Appendix A of the integration guide.

## Using AXService

`AXService` provides the `getLocalHTTPProxy` API that returns a local HTTP proxy endpoint. Any Java HTTP client that supports `java.net.Proxy` can route traffic through this endpoint, and the SDK will transparently forward it through the protected channel.

```java
String demoURL = "https://your.server.domain/";

AXLocalProxy localProxy = AXService.getLocalHTTPProxy();
if (localProxy == null) {
    // SDK not ready — check initialization result or retry later
    return;
}

Proxy httpProxy = new Proxy(Proxy.Type.HTTP,
        new InetSocketAddress(localProxy.getIp(), localProxy.getPort()));
HttpURLConnection conn = (HttpURLConnection) new URL(demoURL).openConnection(httpProxy);
// set request method, timeouts, and read the response as usual
```

> **Tip:** If you are already using a mainstream HTTP client such as OkHttp, Retrofit, or HttpsURLConnection, we recommend the companion **AxHTTP** wrappers instead — they handle `getLocalHTTPProxy()`, `Proxy` construction, and client lifecycle for you, so you don't have to repeat the boilerplate in this section.

A runnable example is available in [`axsecurity-demo/MainActivity.java`](axsecurity-demo/src/main/java/com/axsecurity/sdk/service/demo/MainActivity.java). The demo **builds and runs without the SDK** — the HTTPRequest button fires a direct HTTPS request to `mDemoURL` by default. Once the SDK is initialized, uncomment the `*** UNCOMMENT ... FOR SDK ***` blocks and comment out the matching `*** COMMENT ... FOR SDK ***` lines to route the request through the SDK's local HTTP proxy channel.

### Other Proxy Endpoints (SOCKS5)

In addition to the HTTP proxy, `AXService` also exposes a local SOCKS5 proxy (not wired into the demo UI — enable it on demand). `HttpURLConnection` speaks SOCKS5 when constructed with `Proxy.Type.SOCKS`:

```java
String demoURL = "https://your.server.domain/";

AXLocalProxy socks5 = AXService.getLocalSocks5Proxy();
if (socks5 == null) { /* SDK not ready */ return; }
Proxy socksProxy = new Proxy(Proxy.Type.SOCKS,
        new InetSocketAddress(socks5.getIp(), socks5.getPort()));
HttpURLConnection conn = (HttpURLConnection) new URL(demoURL).openConnection(socksProxy);
```

### DNS Helpers

`AXService` also provides DNS resolution backed by the SDK's protected resolver:

```java
String[] v4 = AXService.getIPv4sForHost("your.server.domain");
String[] v6 = AXService.getIPv6sForHost("your.server.domain");

AXService.clearDNSCache(); // invalidate cached entries if needed
```

## Error Handling

`AXService.getLocalHTTPProxy()` (and the other `getLocal...Proxy` variants) return `null` when the SDK is not initialized or the local proxy is not available. Always check the return value before issuing a request:

```java
AXLocalProxy localProxy = AXService.getLocalHTTPProxy();
if (localProxy == null) {
    // SDK not ready — check initialization result or retry later
    return;
}
```

Network errors on the proxied connection are reported as standard Java `IOException`s. Handle them as you normally would:

```java
try {
    Proxy httpProxy = new Proxy(Proxy.Type.HTTP,
            new InetSocketAddress(localProxy.getIp(), localProxy.getPort()));
    HttpURLConnection conn = (HttpURLConnection) new URL(demoURL).openConnection(httpProxy);
    // ... read/write ...
} catch (IOException e) {
    // network error — check connectivity and retry if appropriate
}
```

## Checking It Works

After integrating the SDK, run your app and check Logcat for the `AXService` tag. On a successful integration you should see:

1. No error logs from `AXService` during initialization.
2. `getLocalHTTPProxy()` returning a non-null `AXLocalProxy` with a loopback IP and a non-zero port.
3. HTTPS requests issued through that proxy endpoint succeeding and returning expected responses from your server.

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `initialize` returns a negative value | Invalid credentials or unreachable Edge | Verify `accessKeyId`, `accessKeySecret`, and `edgeNodes` |
| `getLocalHTTPProxy()` returns `null` | SDK not initialized or proxy not ready | Ensure `initialize` returned `0` before calling `getLocalHTTPProxy()` |
| `Local HTTP proxy not available` in Logcat | Internal proxy failed to start | Check network permissions and Edge connectivity |
