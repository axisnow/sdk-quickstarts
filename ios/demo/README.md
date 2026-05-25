# SDK 快速接入：iOS ObjectiveC

[English](./README.en.md) | 简体中文

本快速接入指南面向使用 ObjectiveC 编写、通过 TCP / Socket 层发起 API 请求的原生 iOS 应用，帮助你为这些请求接入 SDK 的保护能力。如果你的场景与此不符，请查阅更贴近的接入指南。

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
    config.edgeNodes   = @[ @"Edge 节点 IP 或域名" ];

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
| `AXConfig.dns` | DNS 配置（可选），通过 `AXDNSConfig` 构造。通过 `-addEdgeDohResolveDomain:`（或直接给 `edgeDohResolveDomains` 赋值）加入 EdgeDoH 白名单；通过 `-addEdgeDohBypassDomain:` 为白名单中的主机豁免（bypass 优先于 resolve）。匹配规则为精确域名或 `*.suffix` 通配。**未配置白名单时所有主机走系统 DNS**，需要 EdgeDoH 防护的主机请显式加入。 |
| `AXConfig.secureProxyEnabled` | 加密隧道开关（可选），默认启用；显式设 `NO` 关闭 |

完整参数语义、约束与默认行为见接入指南附录 A。

## 使用 AXService

`AXService` 提供 `getLocalTCPProxy:host:port:` 接口，可针对指定的目标 host 和 port 获取本地代理端点。使用返回的 IP/端口通过标准 POSIX socket（或 `NSStream`、`CFSocket` 等）建立连接后，SDK 会将流量透明地经由受保护通道转发。

```objc
NSString *requestHost = @"your.server.domain";
int       requestPort = 7000;

AXLocalProxy proxy;
int res = [AXService getLocalTCPProxy:&proxy host:requestHost port:requestPort];
if (res < 0) {
    // SDK 未就绪，检查初始化结果或稍后重试
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

// 通过 sockFD 读写数据 ...
```

### 其他代理端点

除按 host 粒度的 TCP 代理外，`AXService` 还提供：

```objc
AXLocalProxy http;
[AXService getLocalHTTPProxy:&http];    // 本地 HTTP 代理端点

AXLocalProxy socks5;
[AXService getLocalSocks5Proxy:&socks5]; // 本地 SOCKS5 代理端点
```

如果需要将自定义 HTTP 客户端或任意 TCP 客户端以系统代理方式接入 SDK，可使用这两个端点。

### DNS 辅助方法

`AXService` 还提供了基于 SDK 受保护解析器的 DNS 能力：

```objc
NSArray<NSString *> *v4 = [AXService getIPv4sForHost:@"your.server.domain"];
NSArray<NSString *> *v6 = [AXService getIPv6sForHost:@"your.server.domain"];

[AXService clearDNSCache]; // 需要时清除缓存
```

## 错误处理

当 SDK 未初始化或本地代理不可用时，`[AXService getLocalTCPProxy:host:port:]`（以及其他 `getLocal...Proxy:` 方法）会返回负数状态码。开启 socket 前务必检查返回值：

```objc
AXLocalProxy proxy;
int res = [AXService getLocalTCPProxy:&proxy host:requestHost port:requestPort];
if (res < 0) {
    // SDK 未就绪，检查初始化结果或稍后重试
    return;
}
```

socket 上的网络错误会通过标准 POSIX 的 `errno` / `strerror(errno)` 反馈，按常规方式处理即可：

```objc
if (connect(sockFD, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    NSLog(@"connect error: %s", strerror(errno));
    close(sockFD);
    return;
}
```

## 验证接入是否成功

集成 SDK 后，运行 App 并在 Xcode 控制台中关注带 `[AXService]` 标签的日志。接入成功时你应该看到：

1. App 启动过程中 `[AXService initialize:]` 无错误日志。
2. `getLocalTCPProxy:host:port:` 返回 `0`，并在 `AXLocalProxy` 中得到回环 IP 和非零端口。
3. 与该代理端点建立 socket 连接成功，并从业务服务端收到预期响应。

如有异常，参考下表排查常见问题：

| 现象 | 原因 | 处理方式 |
|------|------|---------|
| `initialize:` 返回负数 | 凭证无效或 Edge 不可达 | 核对 `accessKeyID`、`accessKeySecret`、`edgeNodes` |
| `getLocalTCPProxy:host:port:` 返回负数 | SDK 未初始化或代理未就绪 | 确认 `initialize:` 返回 `0` 后再调用代理相关 API |
| 连接超时或报错 `ECONNREFUSED` | 内部代理启动失败 | 检查 `initialize:` 返回码及 Edge 连通性 |
