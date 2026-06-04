# SDK Quickstart: Android WebView

English | [简体中文](./README.md)

This quickstart targets native Android apps that load web pages in an Android `WebView`, and shows
how to route the WebView's traffic through the AXSecurity SDK local proxy — giving the WebView
context-aware routing, acceleration, EdgeDoH anti-hijack resolution, and SecureProxy tunnel
encryption. If your scenario differs, see the other quickstarts.

The wrapper exposes a single entry point, `AXWebViewService.installOnWebView(webView, base)`: it
**wraps** your existing `WebViewClient` (callbacks still forwarded), sets the wrapped client on the
WebView for you, and enables the SDK's **process-wide proxy**, so the WebView's full traffic
(main-frame navigation + sub-resources + JS `fetch`/`XHR`) is routed through the SDK local **HTTP**
proxy (HTTP CONNECT, covering HTTP / HTTPS / WebSocket).

This page lists every integration step; a runnable minimal example is provided in the
[webview-demo](webview-demo/) project.

> **No separate wrapper initialization**: the core SDK is started by `AXService.initialize(...)`, and
> this wrapper reads its local proxy on demand — the same init-free model as
> `AXHTTPService.getOkHttpClient()`.

## Add the SDK dependency

The release bundle `axsecurity-android-webview-<version>.zip` contains two AARs: the core SDK
`axsecurity-android-sdk.aar` and the WebView wrapper `axsecurity-android-webview.aar` (a thin
wrapper carrying no `.so`). Drop **both** AARs into your app module's `libs/`:

```
app/
└── libs/
    ├── axsecurity-android-sdk.aar       # core SDK
    └── axsecurity-android-webview.aar   # WebView wrapper
```

And reference them in your app module's `build.gradle`:

```groovy
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar'])
}
```

> These AARs are consumed as local files and **do not carry transitive dependencies**, so
> `androidx.webkit` must be added explicitly in the host project — see the next section.

## Dependency and manifest

The wrapper uses `androidx.webkit` to apply a process-wide proxy override to the WebView. Because
the AARs from the previous section are consumed as local files and **do not carry transitive
dependencies**, you must add this dependency explicitly in your app module's `build.gradle`
(minimum 1.4.0; any newer 1.x works), otherwise you will hit a `NoClassDefFoundError` for
`ProxyController` at runtime:

```groovy
implementation 'androidx.webkit:webkit:1.4.0'
```

The `android.permission.INTERNET` declaration lives in the wrapper AAR's own manifest and merges
into the host app manifest automatically, so the **host needs no `AndroidManifest.xml` changes**.

Note: the minimum supported Android SDK version is 21 (Android 5.0).

## Initialize AXService

Before using the wrapper, initialize the core SDK when the app is created — typically in
`Application.onCreate`, and before any WebView is created:

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

`initialize` returns `0` on success and a negative error code on failure.

> **Important:** `initialize` must be called **exactly once**, before any other `AXService` method
> (including installing the proxy on a WebView). Multiple calls are not supported.

## Parameters

| Parameter | Description |
|-----------|-------------|
| `AXConfig.Builder().accessKey(...)` | AccessKey ID and Secret (required), obtained from the console |
| `AXConfig.Builder().edgeNodes(...)` | EIP(s) or domain(s) pointing to the AxisNow Edge DoH service (required), a `String[]`, at least 1, 2+ recommended |
| `AXConfig.Builder().dns(...)` | DNS config (optional), built via `AXConfig.DnsConfig.Builder`. Use `edgeDohResolveDomains(String...)` to add the EdgeDoH allowlist; use `edgeDohBypassDomains(String...)` to exempt allowlisted domains (bypass takes precedence over resolve). Matching is by exact domain or `*.suffix` wildcard. **With no allowlist configured, all domains use system DNS** — add the domains that need EdgeDoH protection explicitly. |

For full parameter semantics, constraints, and defaults, see Appendix A of the integration guide.

## Install the proxy on a WebView

A `WebView` allows only one `WebViewClient`, so **wrap** your existing client instead of replacing
it. `installOnWebView` sets the (wrapped) client on the WebView for you — you no longer call
`setWebViewClient` yourself:

```java
import com.axsecurity.sdk.webview.AXWebViewService;

int rc = AXWebViewService.installOnWebView(webView, myWebViewClient);
// pass null as the second argument if the app has no client of its own

// Start the first navigation via load(...) instead of webView.loadUrl(...); see "First-load timing"
AXWebViewService.load(webView, url);
```

- **Success (`0`)**: the SDK global proxy is enabled and the WebView runs through the SDK data
  path.
- **Failure (negative error code)**: the WebView runs direct; the call has already attached your
  client (`base`, or a plain `WebViewClient` when `base` is null) as a fallback, and the cause is
  logged to logcat (tag `AXSDK`). See the codes under "Error handling" below.

On success, the WebView's full traffic — main-frame navigation and every in-page sub-resource — is
routed through the SDK local proxy.

> ⚠️ **First-load timing**: a `0` (success) return means the proxy override was only *initiated* — the
> underlying `ProxyController.setProxyOverride(...)` is **asynchronous** and takes effect only after
> its completion callback fires. Calling `webView.loadUrl(...)` right after `installOnWebView` can
> let the **first** navigation leave before the proxy applies, leaking a direct connection that
> bypasses the SDK (most likely on cold start / first WebView initialization). Use
> `AXWebViewService.load(webView, url)` instead: it issues the `loadUrl` only once the proxy is in
> effect, closing the window. When the proxy is unavailable, `load` falls back to a direct load
> immediately so the page still opens; and if the proxy callback never arrives on an extreme device,
> `load` falls back to direct after a short timeout (logged at `AXSDK`) so the page cannot hang. The
> load is dispatched on the WebView's UI thread. The race only affects the first navigation —
> subsequent ones are unaffected.

> ⚠️ **Do not call `setWebViewClient(...)` yourself after `installOnWebView`**: the wrapper owns the
> client; setting your own afterwards clobbers the SDK's client.

> **Re-callable**: if a WebView is constructed before the SDK is initialized, call `installOnWebView`
> again after `AXService.initialize(...)` succeeds to upgrade that WebView onto the SDK.

> **Side effect**: on success this enables the **process-wide** proxy (affects every WebView in the
> process), at call time — unlike `getOkHttpClient()`, which carries the proxy on the returned object.

A runnable example is in
[`webview-demo/src/main/java/com/axsecurity/sdk/webview/demo/DemoWebView.java`](webview-demo/src/main/java/com/axsecurity/sdk/webview/demo/DemoWebView.java)
(calls `installOnWebView` in the custom WebView's `init()`) and
[`MyApplication.java`](webview-demo/src/main/java/com/axsecurity/sdk/webview/demo/MyApplication.java)
(initializes the SDK).

## Error handling

`installOnWebView` does not throw (consistent with the rest of the SDK): a `0` return means success,
a **negative error code** means the proxy was not enabled — the call has already attached `base` (or
a plain client) so the WebView runs direct, with the cause logged to logcat (tag `AXSDK`). The codes
match the unified SDK error-code table:

| Code | Meaning | Fix |
|------|---------|-----|
| `0` | Success, routed through the SDK proxy | — |
| `-2` | Invalid argument (`webView` was null) | Pass a valid WebView |
| `-101` | SDK not initialized / local proxy unavailable | Confirm `AXService.initialize(...)` returned `0`, then call again (re-callable) |
| `-401` | Device WebView lacks `PROXY_OVERRIDE` | Update the system WebView component; devices that cannot update fall back to direct |

## Verifying integration

The client prints no app-facing debug logs; rely on the **console request log**. Trigger a WebView
load, filter by AccessKey / time in the console, and confirm requests traverse the SDK data path
with the expected DNS and tunnel state. See the integration guide §4.4.

## Known limitations

- **Tied to WebView version, not OS version**: `PROXY_OVERRIDE` follows the independently-updatable
  WebView component, not the system API level. The rare device that cannot update WebView (no GMS /
  frozen) falls back to direct.
- **Process-wide**: once enabled it affects every WebView in the app; it cannot target a single
  instance.
- **Hybrid frameworks**: Cordova / Capacitor / React Native / Flutter own their `WebViewClient`, so
  `installOnWebView` does not apply — not supported in phase 1.
- **Request signing / header rewriting**: not in phase 1. Over HTTPS the proxy is a CONNECT tunnel
  and cannot modify request headers. This is planned for a later version as a wrapper-internal change
  — the integration code (still `installOnWebView`) stays unchanged, with capability configuration
  going through `AXService.initialize(...)`.
