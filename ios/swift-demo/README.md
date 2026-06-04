# SDK 快速接入：iOS Swift

[English](./README.en.md) | 简体中文

本快速接入指南面向使用 Swift 编写的原生 iOS 应用，演示如何通过 SDK 的本地 HTTP 代理把 `URLSession` 的 HTTP 请求与 WebSocket 连接接入 SDK 保护通道。如果你的场景与此不符，请查阅更贴近的接入指南。

本页列出了完整的接入步骤；同时我们在 [ios-demo](./Demo/) 中提供了一份手把手的教程示例。Demo 默认是直连模式（编译即跑），按代码内的 `*** UNCOMMENT THE LINES BELOW FOR SDK ***` 标记取消注释后即接入 SDK。

请注意，SDK 的最低支持 iOS 版本为 12.0。

## 添加 SDK 服务依赖

将 `AXSecurity.xcframework` 拷贝到你的工程目录（例如 `YourApp/Frameworks/`），并添加到目标 target 的 **Build Phases → Link Binary with Libraries** 中：

1. `AXSecurity.xcframework` — SDK 核心
2. `libz.tbd` — 压缩库
3. `libc++.tbd` — C++ 标准库
4. `libresolv.tbd` — DNS 解析
5. `DeviceCheck.framework` — Apple DeviceCheck 框架
6. `CoreTelephony.framework` — Apple CoreTelephony 框架

参考目录结构：

```
YourApp/
└── Frameworks/
    └── AXSecurity.xcframework
```

`AXSecurity.xcframework` 内置 module map，Swift 中直接 `import AXSecurity` 即可使用，**无需创建 bridging header**。

## 初始化 AXService

在使用 `AXService` 前，必须在 App 启动时完成初始化。`AXService` 所有 API 均为类方法，无需创建实例：

```swift
import AXSecurity

let config = AXConfig()
config.accessKeyID     = "<YOUR_ACCESS_KEY_ID>"
config.accessKeySecret = "<YOUR_ACCESS_KEY_SECRET>"
config.edgeNodes       = ["<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>"]

let proxy = AXProxyConfig()
proxy.secureProxyEnabled = true
config.proxy = proxy

let dns = AXDNSConfig()
dns.edgeDohResolveDomains = ["*.example.com"]
config.dns = dns

let r = AXService.initialize(config)
if r != 0 {
    NSLog("SDK 初始化失败: %d", r)
}
```

`AXService.initialize(_:)` 返回 `0` 表示成功，返回负数错误码表示失败。

> **重要：** `initialize(_:)` 必须在调用任何其他 `AXService` 方法之前调用且仅调用一次。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AXConfig.accessKeyID` | AccessKey ID（必填），从控制台获取 |
| `AXConfig.accessKeySecret` | AccessKey Secret（必填），从控制台获取 |
| `AXConfig.edgeNodes` | 指向 AxisNow Edge DoH 服务的 EIP 或域名（必填），`[String]`，至少 1 个，推荐 2+ |
| `AXConfig.dns` | DNS 配置（可选），通过 `AXDNSConfig` 构造。给 `edgeDohResolveDomains` 赋数组加入 EdgeDoH 白名单；给 `edgeDohBypassDomains` 赋数组为白名单中的主机豁免（bypass 优先于 resolve）。匹配规则为精确域名或 `*.suffix` 通配。**未配置白名单时所有主机走系统 DNS**，需要 EdgeDoH 防护的主机请显式加入。 |
| `AXConfig.proxy` | 代理配置（可选），通过 `AXProxyConfig` 构造。`AXProxyConfig.secureProxyEnabled` 控制加密隧道开关，显式设 `false` 关闭。 |

完整参数语义、约束与默认行为见接入指南附录 A。

## HTTP 接入：URLSession + 本地 HTTP 代理

`AXService` 提供 `getLocalHTTPProxy()` 返回本地 HTTP 代理端点。把它写到 `URLSessionConfiguration.connectionProxyDictionary`，原生 `URLSession` 即可走 SDK 受保护通道：

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

`getLocalHTTPProxy()` 返回 `nil` 时表示 SDK 未就绪或本地代理未启动，此时 `connectionProxyDictionary` 不设置，请求直连。

## WebSocket 接入：Starscream + ProxyWebSocketEngine

WebSocket 握手本质上是一次 HTTP Upgrade 请求，因此复用与 HTTP 完全相同的代理通道。但 [Starscream](https://github.com/daltoniam/Starscream) 默认引擎走的是裸 socket / Network.framework，**不经过 `URLSession`，因此 `connectionProxyDictionary` 对它无效**；其自带的 `NativeEngine` 又把 `URLSessionConfiguration.default` 写死，没有注入代理的入口。所以接入 SDK 的关键，是给 Starscream 注入一个自定义 `Engine`，在它内部把 SDK 代理写进 `URLSessionConfiguration`——这正是 `ProxyWebSocketEngine` 的作用。

> **注意：** `ProxyWebSocketEngine` 基于 `URLSessionWebSocketTask`，要求 iOS 13.0+。SDK 本身支持 iOS 12.0，但本 WebSocket 示例在 iOS 12 上会跳过（Demo 已用 `#available(iOS 13.0, *)` 做了判断）。

接入步骤：

1. 通过 SPM 添加 Starscream 依赖（本 Demo 已在工程里配好：`https://github.com/daltoniam/Starscream`，`upToNextMajor` from `4.0.6`）。
2. 提供一个实现 Starscream `Engine` 协议的 `ProxyWebSocketEngine`，在其 `start(request:)` 里把 `getLocalHTTPProxy()` 注入 `URLSessionConfiguration`（其余逻辑与 Starscream 自带的 `NativeEngine` 一致）。为简化 Demo，该类直接内置在 `ViewController.swift` 里，其代理注入核心为：

```swift
// ProxyWebSocketEngine.start(request:) 内部
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

3. 业务侧照常使用 Starscream，只在构造 `WebSocket` 时传入该 engine：

```swift
import Starscream

let request = URLRequest(url: URL(string: "wss://your.server.domain/ws")!)
let engine = ProxyWebSocketEngine() // 内部把 SDK 代理注入底层 URLSession
let socket = WebSocket(request: request, engine: engine)
socket.onEvent = { event in
    switch event {
    case .connected(let headers): break // 连接成功
    case .text(let text): break          // 收到文本帧
    case .disconnected(let reason, let code): break
    case .error(let error): break
    default: break
    }
}
socket.connect()
socket.write(string: "hello")
```

代理注入对业务代码透明：Starscream 的 API 完全不变，只是底层流量改走 SDK。`getLocalHTTPProxy()` 返回 `nil` 时 engine 直连兜底（见 `ProxyWebSocketEngine.usedDirectFallback`）。

## 错误处理

- `AXService.getLocalHTTPProxy()` 返回 `nil`：SDK 未初始化或本地代理未启动。上面的写法下 `URLSession` 走直连兜底；可在 UI 上提示用户。
- `URLSession.dataTask` 完成回调里照常通过 `error` 参数处理网络错误。

## 验证接入是否成功

集成 SDK 后，运行 App 并在 Xcode 控制台中关注带 `[AXService]` 标签的日志。接入成功时你应该看到：

1. App 启动过程中 `AXService.initialize(_:)` 无错误日志。
2. `getLocalHTTPProxy()` 返回非 `nil` 的 `AXLocalProxy`，`ip` 是回环地址、`port` 非零。
3. HTTP 请求成功，业务服务端收到的来源 IP 为 SDK 转发后的 IP。

如有异常，参考下表排查常见问题：

| 现象 | 原因 | 处理方式 |
|------|------|---------|
| `initialize(_:)` 返回负数 | 凭证无效或 Edge 不可达 | 核对 `accessKeyID`、`accessKeySecret`、`edgeNodes` |
| `getLocalHTTPProxy()` 返回 `nil` | SDK 未初始化或代理未就绪 | 确认 `initialize(_:)` 返回 `0` 后再调用代理相关 API |
| HTTP 请求超时或报错 `ECONNREFUSED` | 内部代理启动失败 | 检查 `initialize(_:)` 返回码及 Edge 连通性 |
