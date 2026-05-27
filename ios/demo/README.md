# SDK 快速接入：iOS ObjectiveC

[English](./README.en.md) | 简体中文

本快速接入指南面向使用 ObjectiveC 编写、通过 `NSURLSession` 发起 HTTP API 请求的原生 iOS 应用，帮助你为这些请求接入 SDK 的保护能力。如果你的场景与此不符，请查阅更贴近的接入指南。

本页列出了完整的接入步骤；同时我们在 [ios-demo](./Demo/) 中提供了一份手把手的教程示例。

请注意，SDK 的最低支持 iOS 版本为 12.0。若你的 App 需要支持更早的 iOS 版本，则无法使用 SDK。

## 添加 SDK 服务依赖

将 `AXSecurity.framework` 拷贝到你的工程目录（例如 `YourApp/Frameworks/`），并添加到目标 target 的 **Build Phases → Link Binary with Libraries** 中：

1. `AXSecurity.framework` — SDK 核心 SDK

在同一个 **Link Binary with Libraries** 中继续添加以下系统依赖：

2. `libz.tbd` — 压缩库
3. `libc++.tbd` — C++ 标准库
4. `libresolv.tbd` — DNS 解析
5. `DeviceCheck.framework` — Apple DeviceCheck 框架
6. `CoreTelephony.framework` — Apple CoreTelephony 框架

参考目录结构：

```
YourApp/
└── Frameworks/
    └── AXSecurity.framework
```

## 初始化 AXService

在使用 `AXService` 前，必须在 App 启动时完成初始化，通常放在 `application:didFinishLaunchingWithOptions:` 中。`AXService` 所有 API 均为类方法，无需创建实例：

```objc
#import <AXSecurity/axsecurity.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    AXConfig *config = [[AXConfig alloc] init];
    config.accessKeyID     = @"SDK 部署时获得的 accessKeyID";
    config.accessKeySecret = @"SDK 部署时获得的 accessKeySecret";
    config.edgeNodes       = @[ @"Edge 节点 IP 或域名" ];

    AXProxyConfig *proxy = [[AXProxyConfig alloc] init];
    proxy.secureProxyEnabled = YES;
    config.proxy = proxy;

    int r = [AXService initialize:config];
    if (r != 0) {
        NSLog(@"SDK 初始化失败: %d", r);
    }
    return YES;
}

@end
```

`initialize:` 返回 `0` 表示成功，返回负数错误码表示失败。

> **重要：** `initialize:` 必须在调用任何其他 `AXService` 方法之前调用且仅调用一次。不支持多次调用。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AXConfig.accessKeyID` | AccessKey ID（必填），从控制台获取 |
| `AXConfig.accessKeySecret` | AccessKey Secret（必填），从控制台获取 |
| `AXConfig.edgeNodes` | Edge 节点地址数组（必填），`NSArray<NSString *>`，至少 1 个，推荐 2+ |
| `AXConfig.proxy` | 代理配置（可选），通过 `AXProxyConfig` 构造。`AXProxyConfig.secureProxyEnabled` 控制加密隧道开关，显式设 `NO` 关闭。 |
| `AXConfig.dns` | DNS 配置（可选），通过 `AXDNSConfig` 构造。给 `edgeDohResolveDomains` 赋数组加入 EdgeDoH 白名单；给 `edgeDohBypassDomains` 赋数组为白名单中的主机豁免（bypass 优先于 resolve）。匹配规则为精确域名或 `*.suffix` 通配。**未配置白名单时所有主机走系统 DNS**，需要 EdgeDoH 防护的主机请显式加入。 |

完整参数语义、约束与默认行为见接入指南附录 A。

## 使用 AXService

`AXService` 提供 `getLocalHTTPProxy` 接口，返回 SDK 在本地启动的 HTTP 代理端点。将该端点写入 `NSURLSessionConfiguration.connectionProxyDictionary` 后，`NSURLSession` 发出的 HTTP/HTTPS 请求会经过 SDK 受保护通道转发，对业务代码透明。

```objc
AXLocalProxy *httpProxy = [AXService getLocalHTTPProxy];
if (httpProxy == nil) {
    // SDK 未就绪，检查初始化结果或稍后重试
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
                 // 处理响应 ...
               }];
[task resume];
```

> **提示：** `connectionProxyDictionary` 仅对该 `NSURLSession` 生效，不会污染共享的 `NSURLSessionConfiguration` 或全局代理设置。需要的话可以为不同业务创建多个 session。

### 其他代理端点

除 HTTP 代理外，`AXService` 还提供：

```objc
AXLocalProxy *socks5 = [AXService getLocalSocks5Proxy];
// 本地 SOCKS5 代理端点，可用于支持 SOCKS5 的客户端
```

### DNS 辅助方法

`AXService` 还提供了基于 SDK 受保护解析器的 DNS 能力：

```objc
NSArray<NSString *> *v4 = [AXService getIPv4sForHost:@"your.server.domain"];
NSArray<NSString *> *v6 = [AXService getIPv6sForHost:@"your.server.domain"];

[AXService clearDNSCache]; // 需要时清除缓存
```

## 错误处理

`[AXService getLocalHTTPProxy]`（以及其他 `getLocal...Proxy` 变体）在 SDK 未初始化或本地代理不可用时返回 `nil`。配置 `NSURLSession` 前务必判空：

```objc
AXLocalProxy *httpProxy = [AXService getLocalHTTPProxy];
if (httpProxy == nil) {
    // SDK 未就绪，检查初始化结果或稍后重试
    return;
}
```

请求层面的网络错误通过 `NSURLSession` completion handler 的 `NSError *error` 返回，按常规方式处理即可：

```objc
if (error != nil) {
    NSLog(@"http request error: %@", error.localizedDescription);
    return;
}
```

## 验证接入是否成功

集成 SDK 后，运行 App 并在 Xcode 控制台中关注带 `[AXService]` 标签的日志。接入成功时你应该看到：

1. App 启动过程中 `[AXService initialize:]` 无错误日志。
2. `getLocalHTTPProxy` 返回非空对象，其中包含回环 IP 和非零端口。
3. 通过该端点配置的 `NSURLSession` 请求返回业务服务端的预期响应（如 `200 OK`）。

如有异常，参考下表排查常见问题：

| 现象 | 原因 | 处理方式 |
|------|------|---------|
| `initialize:` 返回负数 | 凭证无效或 Edge 不可达 | 核对 `accessKeyID`、`accessKeySecret`、`edgeNodes` |
| `getLocalHTTPProxy` 返回 `nil` | SDK 未初始化或代理未就绪 | 确认 `initialize:` 返回 `0` 后再调用代理相关 API |
| 请求超时或报错 `Could not connect to the server` | 内部代理启动失败 | 检查 `initialize:` 返回码及 Edge 连通性 |
