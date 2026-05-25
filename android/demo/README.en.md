# SDK Quickstart: Android Java

English | [简体中文](./README.md)

This quickstart is written specifically for native Android apps that are written in Java and make TCP/socket-level API calls that you wish to protect with SDK. If this is not your situation then check if there is a more relevant quickstart guide available.

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

        String accessKeyId = "your accessKeyId from SDK Deployment";
        String accessKeySecret = "your accessKeySecret from SDK Deployment";
        String[] edgeNodes = {"edge IP"};

        AXConfig config = new AXConfig.Builder()
            .accessKey(accessKeyId, accessKeySecret)
            .edgeNodes(edgeNodes)
            .dns(new AXConfig.DnsConfig.Builder()
                .addEdgeDohResolveDomain("*.example.com")
                .build())
            .secureProxyEnabled(true)
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
| `AXConfig.Builder().edgeNodes(...)` | List of Edge node addresses (required); pass a `String[]`; at least 1, 2+ recommended |
| `AXConfig.Builder().dns(...)` | DNS configuration (optional); construct via `AXConfig.DnsConfig.Builder`. Whitelist domains for EdgeDoH via `addEdgeDohResolveDomain(String)` (or bulk `edgeDohResolveDomains(String[])`); exempt specific domains via `addEdgeDohBypassDomain(String)` (bypass takes priority over whitelist). Patterns are exact or `*.suffix` wildcards. **Without a whitelist, all domains resolve via the system DNS** — explicitly add domains you want to protect via EdgeDoH. |
| `AXConfig.Builder().secureProxyEnabled(...)` | Encrypted tunnel toggle (optional); enabled by default; pass `false` to disable |

For full parameter semantics, constraints, and default behavior, see Appendix A of the integration guide.

## Using AXService

`AXService` provides the `getLocalTCPProxy` API to obtain the local proxy endpoint corresponding to a given target host and port. Connect to the returned IP/port using standard `Socket` APIs, and the SDK will transparently forward your traffic through the protected channel.

```java
String requestHost = "your.server.domain";
int requestPort = 7000;

AXLocalProxy localProxy = AXService.getLocalTCPProxy(requestHost, requestPort);
if (localProxy == null) {
    // SDK not ready — check initialization result or retry later
    return;
}

Socket socket = new Socket(localProxy.getIp(), localProxy.getPort());
// read or write data via socket
```

### Other Proxy Endpoints

In addition to per-host TCP proxy, `AXService` exposes a local HTTP proxy and a local SOCKS5 proxy. Both accept any Java HTTP client that supports `java.net.Proxy` and route traffic through the SDK.

```java
String demoURL = "https://your.server.domain/";

// HTTP proxy — use Proxy.Type.HTTP
AXLocalProxy http = AXService.getLocalHTTPProxy();
if (http == null) { /* SDK not ready */ return; }
Proxy httpProxy = new Proxy(Proxy.Type.HTTP,
        new InetSocketAddress(http.getIp(), http.getPort()));
HttpURLConnection c1 = (HttpURLConnection) new URL(demoURL).openConnection(httpProxy);

// SOCKS5 proxy — use Proxy.Type.SOCKS (HttpURLConnection speaks SOCKS5 via this type)
AXLocalProxy socks5 = AXService.getLocalSocks5Proxy();
if (socks5 == null) { /* SDK not ready */ return; }
Proxy socksProxy = new Proxy(Proxy.Type.SOCKS,
        new InetSocketAddress(socks5.getIp(), socks5.getPort()));
HttpURLConnection c2 = (HttpURLConnection) new URL(demoURL).openConnection(socksProxy);
```

A runnable end-to-end example that wires both endpoints to buttons is available in [`axsecurity-demo/MainActivity.java`](axsecurity-demo/src/main/java/com/axsecurity/sdk/service/demo/MainActivity.java) — uncomment the `*** UNCOMMENT ... FOR SDK ***` blocks after you finish initializing the SDK.

### DNS Helpers

`AXService` also provides DNS resolution backed by the SDK's protected resolver:

```java
String[] v4 = AXService.getIPv4sForHost("your.server.domain");
String[] v6 = AXService.getIPv6sForHost("your.server.domain");

AXService.clearDNSCache(); // invalidate cached entries if needed
```

## Error Handling

`AXService.getLocalTCPProxy()` (and the other `getLocal...Proxy` variants) return `null` when the SDK is not initialized or the local proxy is not available. Always check the return value before opening a socket:

```java
AXLocalProxy localProxy = AXService.getLocalTCPProxy(requestHost, requestPort);
if (localProxy == null) {
    // SDK not ready — check initialization result or retry later
    return;
}
```

Network errors on the resulting socket are reported as standard Java `IOException`s. Handle them as you normally would:

```java
try {
    Socket socket = new Socket(localProxy.getIp(), localProxy.getPort());
    // ... read/write ...
} catch (IOException e) {
    // network error — check connectivity and retry if appropriate
}
```

## Checking It Works

After integrating the SDK, run your app and check Logcat for the `AXService` tag. On a successful integration you should see:

1. No error logs from `AXService` during initialization.
2. `getLocalTCPProxy()` returning a non-null `AXLocalProxy` with a loopback IP and a non-zero port.
3. Socket connections to that proxy endpoint succeeding and returning expected responses from your server.

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `initialize` returns a negative value | Invalid credentials or unreachable Edge | Verify `accessKeyId`, `accessKeySecret`, and `edgeNodes` |
| `getLocalTCPProxy()` returns `null` | SDK not initialized or proxy not ready | Ensure `initialize` returned `0` before calling `getLocalTCPProxy()` |
| `Local TCP proxy not available` in Logcat | Internal proxy failed to start | Check network permissions and Edge connectivity |
