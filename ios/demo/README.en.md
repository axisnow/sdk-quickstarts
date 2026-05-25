# SDK Quickstart: iOS ObjectiveC

English | [简体中文](./README.md)

This quickstart is written specifically for native iOS apps that are written in ObjectiveC and make TCP / socket-level API calls that you wish to protect with SDK. If this is not your situation then check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating SDK into your app. Additionally, a step-by-step tutorial guide using our [ios-demo](./Demo/) is also available.

Note that the minimum supported iOS version is 12.0. You cannot use SDK in apps that support iOS versions older than this.

## Adding SDK Service Dependency

Copy `AXSecurity.framework` into your app's project directory (e.g. `YourApp/Frameworks/`) and add it to the **Link Binary with Libraries** section of your target's **Build Phases**:

1. `AXSecurity.framework` — SDK core SDK

Then add the following system dependencies to the same **Link Binary with Libraries** section:

2. `libz.tbd` — compression library
3. `libc++.tbd` — C++ standard library
4. `libresolv.tbd` — DNS resolution
5. `DeviceCheck.framework` — Apple's DeviceCheck framework
6. `CoreTelephony.framework` — Apple's CoreTelephony framework

Reference layout:

```
YourApp/
└── Frameworks/
    └── AXSecurity.framework
```

## Initializing AXService

In order to use `AXService` you must initialize it when your app is created, usually in `application:didFinishLaunchingWithOptions:`. All `AXService` APIs are class methods — no instance is needed:

```objc
#import <AXSecurity/axsecurity.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    AXConfig *config = [[AXConfig alloc] init];
    config.accessKeyID     = @"your accessKeyID from SDK Deployment";
    config.accessKeySecret = @"your accessKeySecret from SDK Deployment";
    config.edgeNodes   = @[ @"edge IP or hostname" ];

    int r = [AXService initialize:config];
    if (r != 0) {
        NSLog(@"SDK initialization failed: %d", r);
    }
    return YES;
}

@end
```

`initialize:` returns `0` on success or a negative error code on failure.

> **Important:** `initialize:` must be called exactly once before any other `AXService` method. Calling it more than once is not supported.

## Parameter Reference

| Parameter | Description |
|-----------|-------------|
| `AXConfig.accessKeyID` | AccessKey ID (required), obtained from the console |
| `AXConfig.accessKeySecret` | AccessKey Secret (required), obtained from the console |
| `AXConfig.edgeNodes` | List of Edge node addresses (required); `NSArray<NSString *>`; at least 1, 2+ recommended |
| `AXConfig.dns` | DNS configuration (optional); construct via `AXDNSConfig`. Whitelist hosts for EdgeDoH via `-addEdgeDohResolveDomain:` (or assign `edgeDohResolveDomains` directly); exempt specific hosts via `-addEdgeDohBypassDomain:` (bypass takes priority over the whitelist). Patterns are exact or `*.suffix` wildcards. **Without a whitelist, all hosts resolve via the OS DNS resolver** — explicitly add hosts you want to protect via EdgeDoH. |
| `AXConfig.secureProxyEnabled` | Encrypted tunnel toggle (optional); enabled by default; set `NO` to disable |

For full parameter semantics, constraints, and default behavior, see Appendix A of the integration guide.

## Using AXService

`AXService` provides the `getLocalTCPProxy:host:port:` API to obtain the local proxy endpoint corresponding to a given target host and port. Connect to the returned IP/port using standard POSIX sockets (or `NSStream`, `CFSocket`, etc.) and the SDK will transparently forward your traffic through the protected channel.

```objc
NSString *requestHost = @"your.server.domain";
int       requestPort = 7000;

AXLocalProxy proxy;
int res = [AXService getLocalTCPProxy:&proxy host:requestHost port:requestPort];
if (res < 0) {
    // SDK not ready — check initialization result or retry later
    return;
}

int sockFD = socket(AF_INET, SOCK_STREAM, 0);
if (sockFD < 0) {
    return;
}

struct sockaddr_in addr;
memset(&addr, 0, sizeof(addr));
addr.sin_family = AF_INET;
addr.sin_port   = htons(proxy.port);
inet_pton(AF_INET, proxy.ip, &addr.sin_addr);

if (connect(sockFD, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    close(sockFD);
    return;
}

// read or write data via sockFD ...
```

### Other Proxy Endpoints

In addition to per-host TCP proxy, `AXService` exposes:

```objc
AXLocalProxy http;
[AXService getLocalHTTPProxy:&http];    // local HTTP proxy endpoint

AXLocalProxy socks5;
[AXService getLocalSocks5Proxy:&socks5]; // local SOCKS5 proxy endpoint
```

Use these if you need to route a custom HTTP client or an arbitrary TCP client through the SDK as a system-style proxy.

### DNS Helpers

`AXService` also provides DNS resolution backed by the SDK's protected resolver:

```objc
NSArray<NSString *> *v4 = [AXService getIPv4sForHost:@"your.server.domain"];
NSArray<NSString *> *v6 = [AXService getIPv6sForHost:@"your.server.domain"];

[AXService clearDNSCache]; // invalidate cached entries if needed
```

## Error Handling

`[AXService getLocalTCPProxy:host:port:]` (and the other `getLocal...Proxy:` variants) return a negative status when the SDK is not initialized or the local proxy is not available. Always check the return value before opening a socket:

```objc
AXLocalProxy proxy;
int res = [AXService getLocalTCPProxy:&proxy host:requestHost port:requestPort];
if (res < 0) {
    // SDK not ready — check initialization result or retry later
    return;
}
```

Network errors on the resulting socket are surfaced through the standard POSIX `errno` / `strerror(errno)` mechanism. Handle them as you normally would:

```objc
if (connect(sockFD, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    NSLog(@"connect error: %s", strerror(errno));
    close(sockFD);
    return;
}
```

## Checking It Works

After integrating the SDK, run your app and watch the Xcode console for the `[AXService]` tag. On a successful integration you should see:

1. No error logs from `[AXService initialize:]` during app launch.
2. `getLocalTCPProxy:host:port:` returning `0` with a loopback IP and a non-zero port in `AXLocalProxy`.
3. Socket connections to that proxy endpoint succeeding and returning expected responses from your server.

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `initialize:` returns a negative value | Invalid credentials or unreachable Edge | Verify `accessKeyID`, `accessKeySecret`, and `edgeNodes` |
| `getLocalTCPProxy:host:port:` returns a negative value | SDK not initialized or proxy not ready | Ensure `initialize:` returned `0` before calling the proxy APIs |
| Connections time out or fail with `ECONNREFUSED` | Internal proxy failed to start | Check `initialize:` return code and Edge connectivity |
