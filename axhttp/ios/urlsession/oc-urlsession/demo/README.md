# SDK 快速接入：iOS ObjectiveC NSURLSession

[English](./README.en.md) | 简体中文

本快速接入指南面向使用 ObjectiveC 编写、通过 `NSURLSession` 发起 API 请求的原生 iOS 应用，帮助你为这些请求接入 SDK 的保护能力。如果你的场景与此不符，请查阅更贴近的接入指南。

本页列出了完整的接入步骤；同时我们在 [ios-urlsession-demo](./demo/) 中提供了一份手把手的教程示例。

请注意，SDK 的最低支持 iOS 版本为 12.0。若你的 App 需要支持更早的 iOS 版本，则无法使用 SDK。

## 添加 SDK 服务依赖

将以下 framework 拷贝到你的工程目录（例如 `YourApp/Frameworks/`），并添加到目标 target 的 **Build Phases → Link Binary with Libraries** 中：

1. `AXSecurityNSURLSession.framework` — SDK NSURLSession 包装层
2. `AXSecurity.framework` — SDK 核心 SDK

在同一个 **Link Binary with Libraries** 中继续添加以下系统依赖：

3. `libz.tbd` — 压缩库
4. `libc++.tbd` — C++ 标准库
5. `libresolv.tbd` — DNS 解析
6. `DeviceCheck.framework` — Apple DeviceCheck 框架
7. `CoreTelephony.framework` — Apple CoreTelephony 框架

参考目录结构：

```
YourApp/
└── Frameworks/
    ├── AXSecurityNSURLSession.framework
    └── AXSecurity.framework
```

## 初始化 SDK

在创建任何 `AXNSURLSession` 之前，必须在 App 启动时初始化 SDK，通常放在 `application:didFinishLaunchingWithOptions:` 中：

```objc
#import <AXSecurityNSURLSession/AXNSURLSessionHeader.h>

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    AXConfig *config = [[AXConfig alloc] init];
    config.accessKeyID     = @"SDK 部署时获得的 accessKeyID";
    config.accessKeySecret = @"SDK 部署时获得的 accessKeySecret";
    config.edgeNodes   = @[ @"Edge 节点 IP 或域名" ];

    int r = [AXService initialize:config];
    if (r != 0) {
        NSLog(@"SDK 初始化失败: %d", r);
    }
    return YES;
}
```

`initialize:` 返回 `0` 表示成功，返回负数错误码表示失败。

> **重要：** `[AXService initialize:]` 必须在构造任何 `AXNSURLSession` 之前调用且仅调用一次。不支持多次调用。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AXConfig.accessKeyID` | AccessKey ID（必填），从控制台获取 |
| `AXConfig.accessKeySecret` | AccessKey Secret（必填），从控制台获取 |
| `AXConfig.edgeNodes` | Edge 节点地址列表（必填），`NSArray<NSString *>`，至少 1 个，推荐 2+ |

本 demo 仅使用上述最小必填字段。`AXConfig` 的完整选项（DNS 配置、加密隧道开关等）以及参数语义详见 SDK 接入指南。

## 使用 AXNSURLSession

`AXNSURLSession` 是 Apple 原生 `NSURLSession` 的 drop-in 替换。迁移时，只需把 `[NSURLSession sessionWithConfiguration:...]` 替换为 `[AXNSURLSession sessionWithConfiguration:...]`，其他部分（task 创建、completion handler、delegate 回调等）无需改动。

```objc
NSURLSessionConfiguration *cfg =
    [NSURLSessionConfiguration defaultSessionConfiguration];
NSURLSession *session = [AXNSURLSession sessionWithConfiguration:cfg];

NSURLSessionDataTask *task =
    [session dataTaskWithURL:[NSURL URLWithString:@"https://your.api.example.com/ping"]
           completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
             // 处理响应
           }];
[task resume];
```

返回的对象是一个 `NSURLSession`，其所有流量会透明地经由 SDK 本地代理转发。像使用普通 `NSURLSession` 一样，让它与依赖它的业务功能保持相同的生命周期即可。

## 自定义 NSURLSessionConfiguration

`NSURLSessionConfiguration` 上的所有配置项 —— 超时、附加请求头、Cookie 策略、`URLCache`、最低 TLS 版本、`allowsCellularAccess` 等 —— 都会被透传到底层 session。示例：

```objc
NSURLSessionConfiguration *cfg =
    [NSURLSessionConfiguration defaultSessionConfiguration];
cfg.timeoutIntervalForRequest  = 10;
cfg.timeoutIntervalForResource = 30;
cfg.HTTPAdditionalHeaders      = @{ @"User-Agent" : @"MyApp/1.0" };

NSURLSession *session = [AXNSURLSession sessionWithConfiguration:cfg];
```

如果你的 App 需要自定义 TLS 处理 —— 例如证书 pinning，或接受非标准证书 —— 请传入实现了 `-URLSession:didReceiveChallenge:completionHandler:` 的 delegate：

```objc
NSURLSession *session =
    [AXNSURLSession sessionWithConfiguration:cfg
                                    delegate:self         // 你的 delegate
                               delegateQueue:nil];
```

你的 delegate 方法收到的 challenge 与直接用 `+[NSURLSession sessionWithConfiguration:delegate:delegateQueue:]` 创建 session 时完全一致。

## 错误处理

若 SDK 无法连接 Edge 节点或凭证非法，`[AXService initialize:]` 会返回非零状态码。请在构造 session 之前务必检查：

```objc
int r = [AXService initialize:config];
if (r != 0) {
    // SDK 未就绪 —— 暂时不要构造 AXNSURLSession
    return;
}
```

请求过程中的网络错误会以标准 `NSError` 的形式回调到你的 completion handler 或 delegate，错误码为常规的 `NSURLError*`。照常处理即可：

```objc
[[session dataTaskWithRequest:request
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
              if (error) {
                  // 网络错误 —— 检查连接并按需重试
                  return;
              }
              // 处理成功响应
            }] resume];
```

## 验证接入是否成功

集成 SDK 后，运行 App 并在 Xcode 控制台中关注带 `[AXNSURLSession]` 标签的日志。接入成功时你应该看到：

1. `[AXService initialize:]` 未输出错误日志。
2. 第一次创建 session 时出现一行 `[AXNSURLSession] inner session built, proxy=127.0.0.1:<port>`。
3. 后续复用该 session 时出现 `[AXNSURLSession] proxy unchanged=...` 日志。

如有异常，参考下表排查常见问题：

| 现象 | 原因 | 处理方式 |
|------|------|---------|
| `[AXService initialize:]` 返回负数 | 凭证无效或 Edge 不可达 | 核对 `accessKeyID`、`accessKeySecret`、`edgeNodes` |
| 控制台出现 `[AXNSURLSession] proxy lookup failed` | `AXNSURLSession` 在 `[AXService initialize:]` 成功前被构造 | 确认 `[AXService initialize:]` 返回 `0` 后再调用 `+sessionWithConfiguration:` |
| 请求超时或报错 `NSURLErrorCannotConnectToHost` | 本地代理未运行 | 检查 `[AXService initialize:]` 返回码及 Edge 连通性 |
| 自签名 / 内部证书 TLS 报错 | `AXNSURLSession` 不再旁路 TLS 校验 | 在自定义 delegate 中实现 `-URLSession:didReceiveChallenge:completionHandler:` |

## 不支持的能力

`AXNSURLSession` 通过 App 内嵌的本地 HTTP 代理转发流量。以下几种 `NSURLSession` 用法无法通过此方式拦截，请勿与 `AXNSURLSession` 一起使用：

1. **`[NSURLSession sharedSession]`** — 其 configuration 不可变，因此无法重定向流量。请始终通过 `+[AXNSURLSession sessionWithConfiguration:]` 或 `+[AXNSURLSession sessionWithConfiguration:delegate:delegateQueue:]` 构造 session。
2. **后台 session**（`+[NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:]`）— 这类 session 在系统的 `nsurlsessiond` 进程中运行，位于 App 进程之外，因此无法访问 App 内的本地代理。这是架构层面的不兼容。
3. **`NSURLSessionStreamTask`（裸 TCP）** — `connectionProxyDictionary` 对 stream task 不生效。`-streamTaskWithHostName:port:` 为了源码兼容性仍会返回 task，但其 TCP 连接会直连，不经本地代理。
4. **静默跳过 TLS 校验** — `AXNSURLSession` 不会代替你信任非法证书。若你的 App 需要信任自签名或其他非标准证书，请在自定义 delegate 中实现 `-URLSession:didReceiveChallenge:completionHandler:`。
5. **在 `[AXService initialize:]` 返回 `0` 之前构造 `AXNSURLSession`** — session 构造时会读取当时的本地代理地址。如果在 `[AXService initialize:]` 成功之前构造 `AXNSURLSession`，底层 session 可能因缺少代理地址而无法路由。请务必先完成初始化。
