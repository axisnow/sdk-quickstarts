# SDK Quickstart: iOS WebView (WKWebView) · Swift

English | [简体中文](./README.md)

This quick-start guide targets native iOS apps written in **Swift** that load web pages with `WKWebView`, and helps you route the web view's traffic through the SDK secure tunnel. For the Objective-C version, see the [demo](../demo/) in the sibling directory.

This page lists the full integration steps; a runnable minimal sample is provided in the [demo](./demo/) project in this directory. The demo **ships with the SDK integration code commented out** — uncomment the lines marked `*** UNCOMMENT ... FOR SDK ***` and fill in your credentials to enable it.

> **Important: iOS version requirement.** WebView integration relies on `WKWebsiteDataStore.proxyConfigurations`, which Apple introduced in **iOS 17.0**. This wrapper therefore supports **iOS 17.0 and above** only; on earlier systems the web view's traffic is not proxied (it stays direct). The SDK core itself supports iOS 12.0+.

## Add the SDK dependencies

Copy the following frameworks into your project (e.g. `YourApp/Frameworks/`) and add them under your target's **Build Phases → Link Binary with Libraries**:

1. `AXSecurityWebView.xcframework` — SDK WebView wrapper
2. `AXSecurity.xcframework` — SDK core

In the same **Link Binary with Libraries** section, also add these system dependencies:

3. `WebKit.framework` — WKWebView
4. `Network.framework` — proxy configuration (`nw_proxy_config`)
5. `libz.tbd` — compression
6. `libc++.tbd` — C++ standard library
7. `libresolv.tbd` — DNS resolution
8. `DeviceCheck.framework` — Apple DeviceCheck
9. `CoreTelephony.framework` — Apple CoreTelephony

Reference layout:

```
YourApp/
└── Frameworks/
    ├── AXSecurityWebView.xcframework
    └── AXSecurity.xcframework
```

> **About Swift imports.** The SDK ships as xcframeworks that carry Clang modules. In Swift, the core types (`AXConfig`, `AXService`) come from the `AXSecurity` module, while the WebView entry point `AXWebViewService` comes from the `AXSecurityWebView` module. So in your Swift files, `import AXSecurity` and/or `import AXSecurityWebView` depending on which types you use (unlike Objective-C, where importing the umbrella header is enough).

## Initialize the SDK

Before installing the proxy on any web view, initialize the SDK once at app launch, typically in `application(_:didFinishLaunchingWithOptions:)`:

```swift
import AXSecurity

func application(_ application: UIApplication,
                 didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    let config = AXConfig()
    config.accessKeyID = "<YOUR_ACCESS_KEY_ID>"
    config.accessKeySecret = "<YOUR_ACCESS_KEY_SECRET>"
    config.edgeNodes = ["<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>"]

    let r = AXService.initialize(config)
    if r != 0 {
        NSLog("SDK initialize failed: \(r)")
    }
    return true
}
```

`initialize(_:)` returns `0` on success, or a negative error code on failure.

> **Important:** `AXService.initialize(_:)` must be called once, and before installing the proxy on any web view.

## Parameters

| Parameter | Description |
|-----------|-------------|
| `AXConfig.accessKeyID` | AccessKey ID (required), from the console |
| `AXConfig.accessKeySecret` | AccessKey Secret (required), from the console |
| `AXConfig.edgeNodes` | EIP(s) or domain(s) pointing to the AxisNow Edge DoH service (required), `[String]`, at least 1, 2+ recommended |

This demo uses only the minimal required fields. See the SDK integration guide for the full `AXConfig` options (DNS configuration, encrypted-tunnel toggle, etc.).

## Install the proxy on a web view

The entry point is `AXWebViewService`. **Recommended usage**: call `install(on:)` on a `WKWebView` you already own. The wrapper writes the SDK local HTTP proxy onto that web view's `WKWebsiteDataStore` and **leaves your `WKWebViewConfiguration`, `navigationDelegate` and everything else untouched**.

```swift
import AXSecurityWebView

// Your own web view (may carry your own delegate / configuration)
let webView: WKWebView = ...

if #available(iOS 17.0, *) {
    let rc = AXWebViewService.install(on: webView)
    if rc != 0 {
        NSLog("proxy not applied, code: \(rc)")  // e.g. -101: SDK not initialized yet
    }
}

// Load after installing so the proxy applies to this and subsequent navigations
webView.load(URLRequest(url: URL(string: "https://your.page.example.com/")!))
```

> The Objective-C `+ (int)installOnWebView:` is imported into Swift as a plain method `install(on:)` returning `Int32` (**not** throwing): `0` on success, a negative error code on failure (matching the unified SDK table).

Once installed, **all** of the web view's traffic — the top-level navigation and every sub-resource — is routed through the SDK local proxy. WebView traffic is HTTP/HTTPS only, so the wrapper fixes the transport to an HTTP CONNECT proxy (HTTPS is tunnelled via CONNECT); no extra configuration is needed.

### When to call it

- Install only **after** `AXService.initialize(_:)` returns `0`.
- Install **before** the first `load(_:)`; if you install after a load, `reload()` afterwards.
- `install(on:)` re-fetches the current proxy from the SDK on every call, so to refresh just **call it again** (no separate refresh API).

## Proxy scope (about the data store)

The proxy is set on the web view's `WKWebsiteDataStore`, so its scope follows the store you created the web view with:

- `WKWebsiteDataStore.nonPersistent()` or a custom store → the proxy applies **only to that web view** (recommended, clean isolation).
- The default persistent store (`.default()`, shared across web views) → installing the proxy affects **every web view using the default store**.

For isolation, create the web view with a non-persistent store (see the demo). A `WKWebView`'s data store cannot be swapped after creation.

## Error handling

`install(on:)` returns an `Int32`: `0` on success, a negative error code on failure (matching the unified SDK error-code table); the cause is also printed via `os_log` (tag `[AXWebView]`):

| Code | Meaning | What to do |
|------|---------|-----------|
| `0` | Success, routed through the SDK proxy | — |
| `-2` | The web view passed was nil | Pass a valid `WKWebView` |
| `-101` | SDK not initialized, or no local proxy yet | Confirm `AXService.initialize(_:)` returned `0`, then call again (re-callable) |
| `-411` | Could not build `nw_proxy_config` from the local proxy endpoint | Check SDK state and Edge connectivity |

## Verifying the integration

Run the app and watch the Xcode console for `[AXWebView]`-tagged logs. On success you should see:

1. No error logs from `AXService.initialize(_:)`.
2. `[AXWebView] proxy applied: 127.0.0.1:<port>` on install.

If something is off, use this table:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `AXService.initialize(_:)` returns negative | Invalid credentials or unreachable Edge | Check `accessKeyID`, `accessKeySecret`, `edgeNodes` |
| `[AXWebView] proxy unavailable` in console | Installed before `AXService.initialize(_:)` succeeded | Install after initialize returns `0` |
| Web view still connects directly | Device runs iOS < 17 | This wrapper only proxies the web view on iOS 17+ |

## Known limitations

1. **iOS < 17**: the OS exposes no WebView proxy capability, so traffic stays direct and `install(on:)` is a no-op on such devices.
2. **Request signing / header mutation**: this version provides proxying only; signing or rewriting WebView request headers is not yet supported. It is planned for a later version and is **entirely an internal addition to the wrapper**: which requests to sign and how is configured in `AXService.initialize()`, the entry point stays `install(on:)`, and **integration code does not change at all**. Note that the signable scope will be limited to **page-initiated `fetch`/`XHR`/form submissions** — it cannot cover the top-level navigation or sub-resources loaded by the browser engine.
3. **Overriding existing proxyConfigurations**: installing sets the web view's `proxyConfigurations` to the SDK proxy (overriding any entries you set yourself).

## Interface stability & evolution contract

To keep your integration code unchanged across SDK upgrades, the wrapper follows this contract:

1. **`install(on:)` is a frozen, stable entry point.** It always means just "turn on SDK protection for this web view" and carries no business parameters; future capabilities will not change its signature.
2. **All configurable options are funneled into `AXService.initialize(_:)`.** For example, the request signing / header mutation planned in Known limitation #2 above — which requests to sign (host/path allowlist), which headers to add, where secrets come from, whether to fail open or closed when no credential is available — are all configured in `initialize(_:)`, never in `install`'s parameters. Configuration and invocation stay decoupled.
3. **Additive-only.** Even if a future capability must hook into web-view creation time, it will be offered as a **new, optional API** rather than by changing `install(on:)`; existing calls keep working.
4. **The call-timing contract stays the same:** always "call `install(on:)` after `AXService.initialize(_:)` succeeds and before the first `load(_:)`." This ordering is forward-compatible with future capabilities (such as the JS injection needed for page-initiated request signing) — please don't break it.

**What this means for you:** you can treat the SDK as a "proxy + (possible future) page-initiated request signing" dual-path system, yet the integration surface is always just two places — `AXService.initialize(_:)` (configuration) and `AXWebViewService.install(on:)` (enable). Later SDK upgrades are internal evolution; your integration code does not change.
