# SDK Quickstart: iOS ObjectiveC NSURLSession

English | [简体中文](./README.md)

This quickstart is written specifically for native iOS apps that are written in ObjectiveC and make their API calls using `NSURLSession` that you wish to protect with SDK. If this is not your situation then check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating SDK into your app. Additionally, a step-by-step tutorial guide using our [ios-urlsession-demo](./demo/) is also available.

Note that the minimum supported iOS version is 12.0. You cannot use SDK in apps that support iOS versions older than this.

## Adding SDK Service Dependency

Copy the following frameworks into your app's project directory (e.g. `YourApp/Frameworks/`) and add them to the **Link Binary with Libraries** section of your target's **Build Phases**:

1. `AXSecurityNSURLSession.xcframework` — SDK NSURLSession wrapper
2. `AXSecurity.xcframework` — SDK core SDK

Then add the following system dependencies to the same **Link Binary with Libraries** section:

3. `libz.tbd` — compression library
4. `libc++.tbd` — C++ standard library
5. `libresolv.tbd` — DNS resolution
6. `DeviceCheck.framework` — Apple's DeviceCheck framework
7. `CoreTelephony.framework` — Apple's CoreTelephony framework

Reference layout:

```
YourApp/
└── Frameworks/
    ├── AXSecurityNSURLSession.xcframework
    └── AXSecurity.xcframework
```

## Initializing SDK

In order to use SDK you must initialize it when your app is created, usually in `application:didFinishLaunchingWithOptions:`:

```objc
#import <AXSecurityNSURLSession/AXNSURLSessionHeader.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    AXConfig *config = [[AXConfig alloc] init];
    config.accessKeyID     = @"<YOUR_ACCESS_KEY_ID>";
    config.accessKeySecret = @"<YOUR_ACCESS_KEY_SECRET>";
    config.edgeNodes   = @[ @"<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>" ];

    int r = [AXService initialize:config];
    if (r != 0) {
        NSLog(@"SDK initialization failed: %d", r);
    }
    return YES;
}
```

`initialize:` returns `0` on success or a negative error code on failure.

> **Important:** `[AXService initialize:]` must be called exactly once before constructing any `AXNSURLSession`. Calling it more than once is not supported.

## Parameter Reference

| Parameter | Description |
|-----------|-------------|
| `AXConfig.accessKeyID` | AccessKey ID (required), obtained from the console |
| `AXConfig.accessKeySecret` | AccessKey Secret (required), obtained from the console |
| `AXConfig.edgeNodes` | EIP(s) or domain(s) pointing to the AxisNow Edge DoH service (required); `NSArray<NSString *>`; at least 1, 2+ recommended |

This demo uses the minimum required fields. The full `AXConfig` option set (DNS configuration, encrypted tunnel toggle, etc.) and parameter semantics are documented in the SDK integration guide.

## Using AXNSURLSession

`AXNSURLSession` is a drop-in replacement for Apple's `NSURLSession`. To migrate, replace each `[NSURLSession sessionWithConfiguration:...]` with `[AXNSURLSession sessionWithConfiguration:...]`. Everything else — task creation, completion handlers, delegate callbacks — stays the same.

```objc
NSURLSessionConfiguration *cfg =
    [NSURLSessionConfiguration defaultSessionConfiguration];
NSURLSession *session = [AXNSURLSession sessionWithConfiguration:cfg];

NSURLSessionDataTask *task =
    [session dataTaskWithURL:[NSURL URLWithString:@"https://your.api.example.com/ping"]
           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
             // handle response
           }];
[task resume];
```

The returned object is an `NSURLSession` that transparently routes all traffic through SDK's local proxy. Hold it for the lifetime of the feature that uses it, just like a normal `NSURLSession`.

## Custom NSURLSessionConfiguration

Any configuration you set on the `NSURLSessionConfiguration` — timeouts, additional headers, cookie policy, `URLCache`, TLS minimum version, `allowsCellularAccess`, etc. — is preserved and passed through to the underlying session. Example:

```objc
NSURLSessionConfiguration *cfg =
    [NSURLSessionConfiguration defaultSessionConfiguration];
cfg.timeoutIntervalForRequest  = 10;
cfg.timeoutIntervalForResource = 30;
cfg.HTTPAdditionalHeaders      = @{ @"User-Agent" : @"MyApp/1.0" };

NSURLSession *session = [AXNSURLSession sessionWithConfiguration:cfg];
```

If your app needs custom TLS handling — for example certificate pinning, or accepting a non-standard certificate — pass your own delegate that implements `-URLSession:didReceiveChallenge:completionHandler:`:

```objc
NSURLSession *session =
    [AXNSURLSession sessionWithConfiguration:cfg
                                    delegate:self         // your delegate
                               delegateQueue:nil];
```

Your delegate methods receive the original challenges exactly as if you had created the session with `+[NSURLSession sessionWithConfiguration:delegate:delegateQueue:]` directly.

## Error Handling

`[AXService initialize:]` returns a non-zero status if the SDK cannot reach the Edge or the credentials are invalid. Always check it before constructing sessions:

```objc
int r = [AXService initialize:config];
if (r != 0) {
    // SDK not ready — do not construct AXNSURLSession yet
    return;
}
```

Network errors during requests are reported as standard `NSError` instances on your completion handler or delegate, with the usual `NSURLError*` codes. Handle them as you normally would:

```objc
[[session dataTaskWithRequest:request
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
              if (error) {
                  // network error — check connectivity and retry if appropriate
                  return;
              }
              // handle success
            }] resume];
```

## Checking It Works

After integrating the SDK, run your app and watch the Xcode console for the `[AXNSURLSession]` tag. On a successful integration you should see:

1. No error logs from `[AXService initialize:]`.
2. A single `[AXNSURLSession] inner session built, proxy=127.0.0.1:<port>` line the first time you create a session.
3. `[AXNSURLSession] proxy unchanged=...` lines as subsequent requests reuse the session.

If something is wrong, look for these common issues:

| Symptom | Cause | Fix |
|---------|-------|-----|
| `[AXService initialize:]` returns a negative value | Invalid credentials or unreachable Edge | Verify `accessKeyID`, `accessKeySecret`, and `edgeNodes` |
| `[AXNSURLSession] proxy lookup failed` in console | `AXNSURLSession` constructed before `[AXService initialize:]` succeeded | Ensure `[AXService initialize:]` returned `0` before `+sessionWithConfiguration:` |
| Requests time out or fail with `NSURLErrorCannotConnectToHost` | Local proxy not running | Check `[AXService initialize:]` return code and Edge connectivity |
| TLS errors against a self-signed / internal certificate | `AXNSURLSession` no longer bypasses TLS trust | Implement `-URLSession:didReceiveChallenge:completionHandler:` on your own delegate |

## Unsupported Capabilities

`AXNSURLSession` routes traffic through the SDK's in-app local HTTP proxy. A few `NSURLSession` usages cannot be intercepted that way; do not use them with `AXNSURLSession`:

1. **`[NSURLSession sharedSession]`** — its configuration is immutable, so its traffic cannot be redirected. Always construct sessions via `+[AXNSURLSession sessionWithConfiguration:]` or `+[AXNSURLSession sessionWithConfiguration:delegate:delegateQueue:]`.
2. **Background sessions** (`+[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:]`) — these run in the system `nsurlsessiond` process outside your app, so they cannot reach the in-app local proxy. This is an architectural incompatibility.
3. **`NSURLSessionStreamTask`** (raw TCP) — `connectionProxyDictionary` does not apply to stream tasks. `-streamTaskWithHostName:port:` still returns a task for source compatibility, but the TCP stream goes direct, not through the local proxy.
4. **Silent TLS trust bypass** — `AXNSURLSession` does not accept invalid server certificates for you. If your app needs to trust a self-signed or otherwise non-standard certificate, implement `-URLSession:didReceiveChallenge:completionHandler:` on your own delegate.
5. **Constructing `AXNSURLSession` before `[AXService initialize:]` returns `0`** — session construction reads the local proxy address at the moment of the first call. If you construct `AXNSURLSession` before `[AXService initialize:]` succeeds, the underlying session may be built without proxy routing. Always initialize first.
