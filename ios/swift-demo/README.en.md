# SDK Quickstart: iOS Swift

English | [简体中文](./README.md)

This quickstart is for native iOS apps written in Swift that want to route `URLSession` HTTP requests and WebSocket connections through the SDK's local HTTP proxy. If your scenario is different, check for a more specific quickstart guide.

This page covers all the integration steps; the [ios-demo](./Demo/) walks through it step by step. The demo defaults to a direct-connection mode (compiles and runs as-is). Uncomment the blocks marked `*** UNCOMMENT THE LINES BELOW FOR SDK ***` and you're routing through the SDK.

Minimum supported iOS version is 12.0.

## Adding SDK Service Dependency

Copy `AXSecurity.xcframework` into your app's project directory (e.g. `YourApp/Frameworks/`) and add it to the **Link Binary with Libraries** section of your target's **Build Phases**, along with the system dependencies it needs:

1. `AXSecurity.xcframework` — SDK core
2. `libz.tbd` — compression library
3. `libc++.tbd` — C++ standard library
4. `libresolv.tbd` — DNS resolution
5. `DeviceCheck.framework` — Apple's DeviceCheck framework
6. `CoreTelephony.framework` — Apple's CoreTelephony framework

Reference layout:

```
YourApp/
└── Frameworks/
    └── AXSecurity.xcframework
```

`AXSecurity.xcframework` ships with a module map, so Swift can `import AXSecurity` directly — **no bridging header required**.

## Initializing AXService

`AXService` must be initialized before any other API call. All `AXService` APIs are class methods — no instance is required:

```swift
import AXSecurity

let config = AXConfig()
config.accessKeyID     = "your accessKeyID from SDK Deployment"
config.accessKeySecret = "your accessKeySecret from SDK Deployment"
config.edgeNodes       = ["edge IP or hostname"]

let proxy = AXProxyConfig()
proxy.secureProxyEnabled = true
config.proxy = proxy

let dns = AXDNSConfig()
dns.edgeDohResolveDomains = ["*.example.com"]
config.dns = dns

let r = AXService.initialize(config)
if r != 0 {
    NSLog("SDK initialization failed: %d", r)
}
```

`AXService.initialize(_:)` returns `0` on success or a negative error code on failure.

> **Important:** `initialize(_:)` must be called exactly once before any other `AXService` method.

## Parameter Reference

| Parameter | Description |
|-----------|-------------|
| `AXConfig.accessKeyID` | AccessKey ID (required), obtained from the console |
| `AXConfig.accessKeySecret` | AccessKey Secret (required), obtained from the console |
| `AXConfig.edgeNodes` | List of Edge node addresses (required); `[String]`; at least 1, 2+ recommended |
| `AXConfig.dns` | DNS configuration (optional); construct via `AXDNSConfig`. Assign `edgeDohResolveDomains` with an array to whitelist hosts for EdgeDoH; assign `edgeDohBypassDomains` to exempt specific hosts (bypass takes priority over the whitelist). Patterns are exact or `*.suffix` wildcards. **Without a whitelist, all hosts resolve via the OS DNS resolver** — explicitly add hosts you want to protect via EdgeDoH. |
| `AXConfig.proxy` | Proxy configuration (optional); construct via `AXProxyConfig`. `AXProxyConfig.secureProxyEnabled` toggles the encrypted tunnel — set `false` to disable. |

For full parameter semantics, constraints, and default behavior, see Appendix A of the integration guide.

## HTTP via URLSession + Local HTTP Proxy

`AXService.getLocalHTTPProxy()` returns the local HTTP proxy endpoint. Stamp it onto `URLSessionConfiguration.connectionProxyDictionary` and stock `URLSession` will route through the SDK's protected channel:

```swift
import AXSecurity

let cfg = URLSessionConfiguration.default
if let proxy = AXService.getLocalHTTPProxy(), proxy.port > 0, !proxy.ip.isEmpty {
    let port = Int(proxy.port)
    cfg.connectionProxyDictionary = [
        "HTTPEnable": 1,
        "HTTPProxy": proxy.ip,
        "HTTPPort": port,
        "HTTPSEnable": 1,
        "HTTPSProxy": proxy.ip,
        "HTTPSPort": port,
    ]
}
let session = URLSession(configuration: cfg)
let task = session.dataTask(with: url) { data, response, error in
    // ... handle response
}
task.resume()
```

When `getLocalHTTPProxy()` returns `nil` the SDK is either not initialized or the local proxy hasn't started. The example above leaves `connectionProxyDictionary` empty so the request falls through to a direct connection.

## WebSocket via Starscream + ProxyWebSocketEngine

A WebSocket handshake is just an HTTP Upgrade request, so it rides the same proxy plumbing as HTTP. But [Starscream](https://github.com/daltoniam/Starscream)'s default engine uses raw sockets / Network.framework — it **never goes through `URLSession`, so `connectionProxyDictionary` has no effect** — and its built-in `NativeEngine` hardcodes `URLSessionConfiguration.default` with no hook to inject a proxy. The key to SDK integration is therefore to feed Starscream a custom `Engine` that stamps the SDK proxy onto the `URLSessionConfiguration` internally — that is exactly what `ProxyWebSocketEngine` does.

> **Note:** `ProxyWebSocketEngine` is built on `URLSessionWebSocketTask`, which requires iOS 13.0+. The SDK itself supports iOS 12.0, but this WebSocket example is skipped on iOS 12 (the demo guards it with `#available(iOS 13.0, *)`).

Integration steps:

1. Add the Starscream dependency via SPM (already wired into this demo: `https://github.com/daltoniam/Starscream`, `upToNextMajor` from `4.0.6`).
2. Provide an `ProxyWebSocketEngine` that implements Starscream's `Engine` protocol and, in its `start(request:)`, stamps `getLocalHTTPProxy()` onto the `URLSessionConfiguration` (everything else mirrors Starscream's stock `NativeEngine`). To keep the demo simple, this class lives right inside `ViewController.swift`; its proxy-injection core is:

```swift
// inside ProxyWebSocketEngine.start(request:)
let cfg = URLSessionConfiguration.default
if let proxy = AXService.getLocalHTTPProxy(), proxy.port > 0, !proxy.ip.isEmpty {
    let port = Int(proxy.port)
    cfg.connectionProxyDictionary = [
        "HTTPEnable": 1,
        "HTTPProxy": proxy.ip,
        "HTTPPort": port,
        "HTTPSEnable": 1,
        "HTTPSProxy": proxy.ip,
        "HTTPSPort": port,
    ]
}
let session = URLSession(configuration: cfg, delegate: self, delegateQueue: OperationQueue())
let task = session.webSocketTask(with: request)
```

3. Use Starscream as usual; only pass the engine when building the `WebSocket`:

```swift
import Starscream

let request = URLRequest(url: URL(string: "wss://your.server.domain/ws")!)
let engine = ProxyWebSocketEngine() // injects the SDK proxy into the underlying URLSession
let socket = WebSocket(request: request, engine: engine)
socket.onEvent = { event in
    switch event {
    case .connected(let headers): break // connected
    case .text(let text): break          // text frame received
    case .disconnected(let reason, let code): break
    case .error(let error): break
    default: break
    }
}
socket.connect()
socket.write(string: "hello")
```

Proxy injection is transparent to your code: Starscream's API is unchanged, only the underlying traffic now flows through the SDK. When `getLocalHTTPProxy()` returns `nil` the engine falls back to a direct connection (see `ProxyWebSocketEngine.usedDirectFallback`).

## Error Handling

- `AXService.getLocalHTTPProxy()` returns `nil`: the SDK is not initialized or the local proxy hasn't started. With the code above, `URLSession` falls back to a direct connection; surface this to the user if needed.
- `URLSession.dataTask` reports failures through its `error` parameter — handle them as usual.

## Checking It Works

After integrating the SDK, run your app and watch the Xcode console for the `[AXService]` tag. On a successful integration you should see:

1. No error logs from `AXService.initialize(_:)` during app launch.
2. `getLocalHTTPProxy()` returning a non-`nil` `AXLocalProxy` whose `ip` is a loopback address and `port` is non-zero.
3. HTTP requests succeeding, with your server seeing the SDK-forwarded source IP.

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `initialize(_:)` returns a negative value | Invalid credentials or unreachable Edge | Verify `accessKeyID`, `accessKeySecret`, and `edgeNodes` |
| `getLocalHTTPProxy()` returns `nil` | SDK not initialized or proxy not ready | Ensure `initialize(_:)` returned `0` before calling the proxy APIs |
| HTTP requests time out or fail with `ECONNREFUSED` | Internal proxy failed to start | Check `initialize(_:)` return code and Edge connectivity |
