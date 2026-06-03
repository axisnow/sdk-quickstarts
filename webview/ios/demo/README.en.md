# SDK Quickstart: iOS WebView (WKWebView)

English | [简体中文](./README.md)

This quick-start guide targets native iOS apps that load web pages with `WKWebView`, and helps you route the web view's traffic through the SDK secure tunnel. If your scenario differs, please consult the guide that fits it better.

This page lists the full integration steps; a runnable minimal sample is provided in the [demo](./demo/) project. The demo **ships with the SDK integration code commented out** — uncomment the lines marked `*** UNCOMMENT ... FOR SDK ***` and fill in your credentials to enable it.

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

## Initialize the SDK

Before installing the proxy on any web view, initialize the SDK once at app launch, typically in `application:didFinishLaunchingWithOptions:`:

```objc
#import <AXSecurityWebView/AXSecurityWebView.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    AXConfig *config = [[AXConfig alloc] init];
    config.accessKeyID     = @"accessKeyID from SDK deployment";
    config.accessKeySecret = @"accessKeySecret from SDK deployment";
    config.edgeNodes       = @[ @"edge node IP or domain" ];

    int r = [AXService initialize:config];
    if (r != 0) {
        NSLog(@"SDK initialize failed: %d", r);
    }
    return YES;
}
```

`initialize:` returns `0` on success, or a negative error code on failure.

> **Important:** `[AXService initialize:]` must be called once, and before installing the proxy on any web view.

## Parameters

| Parameter | Description |
|-----------|-------------|
| `AXConfig.accessKeyID` | AccessKey ID (required), from the console |
| `AXConfig.accessKeySecret` | AccessKey Secret (required), from the console |
| `AXConfig.edgeNodes` | Edge node addresses (required), `NSArray<NSString *>`, at least 1, 2+ recommended |

This demo uses only the minimal required fields. See the SDK integration guide for the full `AXConfig` options (DNS configuration, encrypted-tunnel toggle, etc.).

## Install the proxy on a web view

The entry point is `AXWebViewService`. **Recommended usage**: call `installOnWebView:` on a `WKWebView` you already own. The wrapper writes the SDK local HTTP proxy onto that web view's `WKWebsiteDataStore` and **leaves your `WKWebViewConfiguration`, `navigationDelegate` and everything else untouched**.

```objc
#import <AXSecurityWebView/AXSecurityWebView.h>

// Your own web view (may carry your own delegate / configuration)
WKWebView *webView = ...;

if (@available(iOS 17.0, *)) {
    int rc = [AXWebViewService installOnWebView:webView];
    if (rc != 0) {
        NSLog(@"proxy not applied, code: %d", rc);  // e.g. -101: SDK not initialized yet
    }
}

// Load after installing so the proxy applies to this and subsequent navigations
[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://your.page.example.com/"]]];
```

Once installed, **all** of the web view's traffic — the top-level navigation and every sub-resource — is routed through the SDK local proxy. WebView traffic is HTTP/HTTPS only, so the wrapper fixes the transport to an HTTP CONNECT proxy (HTTPS is tunnelled via CONNECT); no extra configuration is needed.

### When to call it

- Install only **after** `[AXService initialize:]` returns `0`.
- Install **before** the first `loadRequest:`; if you install after a load, `reload` afterwards.
- `installOnWebView:` re-fetches the current proxy from the SDK on every call, so to refresh just **call it again** (no separate refresh API).

## Proxy scope (about the data store)

The proxy is set on the web view's `WKWebsiteDataStore`, so its scope follows the store you created the web view with:

- `[WKWebsiteDataStore nonPersistentDataStore]` or a custom store → the proxy applies **only to that web view** (recommended, clean isolation).
- The default persistent store (`defaultDataStore`, shared across web views) → installing the proxy affects **every web view using the default store**.

For isolation, create the web view with a non-persistent store (see the demo). A `WKWebView`'s data store cannot be swapped after creation.

## Error handling

`installOnWebView:` returns an `int`: `0` on success, a negative error code on failure (matching the unified SDK error-code table); the cause is also printed via `os_log` (tag `[AXWebView]`):

| Code | Meaning | What to do |
|------|---------|-----------|
| `0` | Success, routed through the SDK proxy | — |
| `-2` | The web view passed was nil | Pass a valid `WKWebView` |
| `-101` | SDK not initialized, or no local proxy yet | Confirm `[AXService initialize:]` returned `0`, then call again (re-callable) |
| `-411` | Could not build `nw_proxy_config` from the local proxy endpoint | Check SDK state and Edge connectivity |

## Verifying the integration

Run the app and watch the Xcode console for `[AXWebView]`-tagged logs. On success you should see:

1. No error logs from `[AXService initialize:]`.
2. `[AXWebView] proxy applied: 127.0.0.1:<port>` on install.

If something is off, use this table:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `[AXService initialize:]` returns negative | Invalid credentials or unreachable Edge | Check `accessKeyID`, `accessKeySecret`, `edgeNodes` |
| `[AXWebView] proxy unavailable` in console | Installed before `[AXService initialize:]` succeeded | Install after initialize returns `0` |
| Web view still connects directly | Device runs iOS < 17 | This wrapper only proxies the web view on iOS 17+ |

## Known limitations

1. **iOS < 17**: the OS exposes no WebView proxy capability, so traffic stays direct and `installOnWebView:` is a no-op on such devices.
2. **Request signing / header mutation**: this version provides proxying only; signing or rewriting WebView request headers is not yet supported. It is planned for a later version and is **entirely an internal addition to the wrapper**: which requests to sign and how is configured in `AXService.initialize()`, the entry point stays `installOnWebView:`, and **integration code does not change at all**. Note that the signable scope will be limited to **page-initiated `fetch`/`XHR`/form submissions** — it cannot cover the top-level navigation or sub-resources loaded by the browser engine.
3. **Overriding existing proxyConfigurations**: installing sets the web view's `proxyConfigurations` to the SDK proxy (overriding any entries you set yourself).
