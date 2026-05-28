# SDK Quickstart: iOS ObjectiveC

English | [简体中文](./README.md)

This quickstart is written specifically for native iOS apps that are written in ObjectiveC and make HTTP API calls via `NSURLSession` that you wish to protect with SDK. If this is not your situation then check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating SDK into your app. Additionally, a step-by-step tutorial guide using our [ios-demo](./Demo/) is also available.

Note that the minimum supported iOS version is 12.0. You cannot use SDK in apps that support iOS versions older than this.

## Adding SDK Service Dependency

Copy `AXSecurity.xcframework` into your app's project directory (e.g. `YourApp/Frameworks/`) and add it to the **Link Binary with Libraries** section of your target's **Build Phases**:

1. `AXSecurity.xcframework` — SDK core SDK

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
    └── AXSecurity.xcframework
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
    config.edgeNodes       = @[ @"edge IP or hostname" ];

    AXProxyConfig *proxy = [[AXProxyConfig alloc] init];
    proxy.secureProxyEnabled = YES;
    config.proxy = proxy;

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
| `AXConfig.proxy` | Proxy configuration (optional); construct via `AXProxyConfig`. `AXProxyConfig.secureProxyEnabled` toggles the encrypted tunnel — set `NO` to disable. |
| `AXConfig.dns` | DNS configuration (optional); construct via `AXDNSConfig`. Assign `edgeDohResolveDomains` with an array to whitelist hosts for EdgeDoH; assign `edgeDohBypassDomains` to exempt specific hosts (bypass takes priority over the whitelist). Patterns are exact or `*.suffix` wildcards. **Without a whitelist, all hosts resolve via the OS DNS resolver** — explicitly add hosts you want to protect via EdgeDoH. |

For full parameter semantics, constraints, and default behavior, see Appendix A of the integration guide.

## Using AXService

`AXService` exposes `getLocalHTTPProxy`, which returns the local HTTP proxy endpoint hosted by the SDK. Wire that endpoint into `NSURLSessionConfiguration.connectionProxyDictionary` and any HTTP/HTTPS request issued by the `NSURLSession` will be transparently forwarded through SDK's protected channel — no changes to your request code required.

```objc
AXLocalProxy *httpProxy = [AXService getLocalHTTPProxy];
if (httpProxy == nil) {
    // SDK not ready — check initialization result or retry later
    return;
}

NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
cfg.connectionProxyDictionary = @{
    @"HTTPEnable"  : @YES,
    @"HTTPProxy"   : httpProxy.ip,
    @"HTTPPort"    : @(httpProxy.port),
    @"HTTPSEnable" : @YES,
    @"HTTPSProxy"  : httpProxy.ip,
    @"HTTPSPort"   : @(httpProxy.port),
};

NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg];

NSURL *url = [NSURL URLWithString:@"https://your.server.domain/your/path"];
NSURLSessionDataTask *task =
    [session dataTaskWithRequest:[NSURLRequest requestWithURL:url]
               completionHandler:^(NSData *data, NSURLResponse *resp, NSError *error) {
                 // handle response ...
               }];
[task resume];
```

> **Tip:** `connectionProxyDictionary` only affects this specific `NSURLSession`; it does not pollute shared `NSURLSessionConfiguration` instances or global proxy settings. Create separate sessions per use case if needed.

### Other Proxy Endpoints

In addition to the HTTP proxy, `AXService` also exposes:

```objc
AXLocalProxy *socks5 = [AXService getLocalSocks5Proxy];
// Local SOCKS5 proxy endpoint for clients that speak SOCKS5
```

### DNS Helpers

`AXService` also provides DNS resolution backed by the SDK's protected resolver:

```objc
NSArray<NSString *> *v4 = [AXService getIPv4sForHost:@"your.server.domain"];
NSArray<NSString *> *v6 = [AXService getIPv6sForHost:@"your.server.domain"];

[AXService clearDNSCache]; // invalidate cached entries if needed
```

## Error Handling

`[AXService getLocalHTTPProxy]` (and the other `getLocal...Proxy` variants) return `nil` when the SDK is not initialized or the local proxy is not available. Always check for `nil` before configuring `NSURLSession`:

```objc
AXLocalProxy *httpProxy = [AXService getLocalHTTPProxy];
if (httpProxy == nil) {
    // SDK not ready — check initialization result or retry later
    return;
}
```

Per-request network errors are delivered through the `NSError *error` parameter of the `NSURLSession` completion handler. Handle them as you normally would:

```objc
if (error != nil) {
    NSLog(@"http request error: %@", error.localizedDescription);
    return;
}
```

## Checking It Works

After integrating the SDK, run your app and watch the Xcode console for the `[AXService]` tag. On a successful integration you should see:

1. No error logs from `[AXService initialize:]` during app launch.
2. `getLocalHTTPProxy` returning a non-nil object whose `ip` is a loopback address and `port` is non-zero.
3. `NSURLSession` requests issued through that proxy returning the expected response from your server (e.g. `200 OK`).

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `initialize:` returns a negative value | Invalid credentials or unreachable Edge | Verify `accessKeyID`, `accessKeySecret`, and `edgeNodes` |
| `getLocalHTTPProxy` returns `nil` | SDK not initialized or proxy not ready | Ensure `initialize:` returned `0` before calling the proxy APIs |
| Requests time out or fail with `Could not connect to the server` | Internal proxy failed to start | Check `initialize:` return code and Edge connectivity |
