# SDK 快速接入：iOS WebView (WKWebView) · Swift

[English](./README.en.md) | 简体中文

本快速接入指南面向使用 `WKWebView` 加载网页、且以 **Swift** 开发的原生 iOS 应用，帮助你让 WebView 的流量经由 SDK 的安全隧道转发。Objective-C 版本请参阅同级目录下的 [demo](../demo/)。

本页列出了完整的接入步骤；同时本目录的 [demo](./demo/) 工程提供了一份可运行的最小示例。该 demo **默认把 SDK 接入代码注释掉**，按源码中 `*** UNCOMMENT ... FOR SDK ***` 标记取消注释、并填入你的接入凭据，即可启用 SDK。

> **重要：iOS 版本要求。** WebView 接入依赖 `WKWebsiteDataStore.proxyConfigurations`，这是 **iOS 17.0** 起才提供的系统能力。因此本封装仅支持 **iOS 17.0 及以上**；在更低系统上，WebView 流量不会被代理（保持直连）。SDK 核心本身的最低支持版本为 iOS 12.0。

## 添加 SDK 依赖

将以下 framework 拷贝到你的工程目录（例如 `YourApp/Frameworks/`），并添加到目标 target 的 **Build Phases → Link Binary with Libraries** 中：

1. `AXSecurityWebView.xcframework` — SDK WebView 包装层
2. `AXSecurity.xcframework` — SDK 核心 SDK

在同一个 **Link Binary with Libraries** 中继续添加以下系统依赖：

3. `WebKit.framework` — WKWebView
4. `Network.framework` — 代理配置（`nw_proxy_config`）
5. `libz.tbd` — 压缩库
6. `libc++.tbd` — C++ 标准库
7. `libresolv.tbd` — DNS 解析
8. `DeviceCheck.framework` — Apple DeviceCheck 框架
9. `CoreTelephony.framework` — Apple CoreTelephony 框架

参考目录结构：

```
YourApp/
└── Frameworks/
    ├── AXSecurityWebView.xcframework
    └── AXSecurity.xcframework
```

> **关于 Swift import。** SDK 以 xcframework 形式分发，自带 Clang module。在 Swift 中：核心类型（`AXConfig`、`AXService`）来自 `AXSecurity` 模块；WebView 接入入口 `AXWebViewService` 来自 `AXSecurityWebView` 模块。因此在 Swift 文件里需按用到的类型分别 `import AXSecurity` / `import AXSecurityWebView`（与 Objective-C 只 import 伞头文件不同）。

## 初始化 SDK

在为任何 WebView 安装代理之前，必须在 App 启动时初始化 SDK，通常放在 `application(_:didFinishLaunchingWithOptions:)` 中：

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
        NSLog("SDK 初始化失败: \(r)")
    }
    return true
}
```

`initialize(_:)` 返回 `0` 表示成功，返回负数错误码表示失败。

> **重要：** `AXService.initialize(_:)` 必须在为 WebView 安装代理之前调用且仅调用一次。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AXConfig.accessKeyID` | AccessKey ID（必填），从控制台获取 |
| `AXConfig.accessKeySecret` | AccessKey Secret（必填），从控制台获取 |
| `AXConfig.edgeNodes` | 指向 AxisNow Edge DoH 服务的 EIP 或域名（必填），`[String]`，至少 1 个，推荐 2+ |

本 demo 仅使用上述最小必填字段。`AXConfig` 的完整选项（DNS 配置、加密隧道开关等）以及参数语义详见 SDK 接入指南。

## 为 WebView 安装代理

接入入口是 `AXWebViewService`。**推荐用法**：在你已有的 `WKWebView` 上调用 `install(on:)`，封装会把 SDK 本地 HTTP 代理写入该 WebView 的 `WKWebsiteDataStore`，**不会改动你的 `WKWebViewConfiguration`、`navigationDelegate` 或任何其它配置**。

```swift
import AXSecurityWebView

// 你自己创建的 WebView（可带自己的 delegate / 配置）
let webView: WKWebView = ...

if #available(iOS 17.0, *) {
    let rc = AXWebViewService.install(on: webView)
    if rc != 0 {
        NSLog("代理未生效，错误码: \(rc)")  // 例如 -101：SDK 尚未初始化
    }
}

// 安装之后再加载，代理对本次及后续导航生效
webView.load(URLRequest(url: URL(string: "https://your.page.example.com/")!))
```

> Objective-C 的 `+ (int)installOnWebView:` 在 Swift 中导入为返回 `Int32` 的普通方法 `install(on:)`（**非** throwing）：返回 `0` 表示成功，负数为错误码（与 SDK 统一码表一致）。

安装成功后，该 WebView 的**全部流量**——主文档导航与页面内的所有子资源——都会经由 SDK 本地代理转发。WebView 只走 HTTP/HTTPS，封装固定使用 HTTP CONNECT 代理（HTTPS 经 CONNECT 隧道转发），无需额外配置。

### 调用时机

- 必须在 `AXService.initialize(_:)` 返回 `0` **之后**安装。
- 建议在**首次 `load(_:)` 之前**安装；若在加载后才安装，请随后 `reload()` 一次。
- `install(on:)` 每次调用都会重新向 SDK 拉取当前代理地址，因此需要刷新时**再次调用**即可（无需单独的刷新 API）。

## 代理作用域（关于 dataStore）

代理写在 WebView 的 `WKWebsiteDataStore` 上，因此其作用域取决于你创建 WebView 时使用的 store：

- 使用 `WKWebsiteDataStore.nonPersistent()` 或自建 store → 代理**仅作用于该 WebView**（推荐，隔离清晰）。
- 使用默认持久化 store（`.default()`，进程内多个 WebView 共享）→ 安装代理会**影响所有使用默认 store 的 WebView**。

如需隔离，请用非持久化 store 创建 WebView（见 demo）。`WKWebView` 的 store 在创建后不可更换。

## 错误处理

`install(on:)` 返回 `Int32`：`0` 表示成功，负数为错误码（与 SDK 统一错误码表一致），失败原因同时通过 `os_log` 打印（标签 `[AXWebView]`）：

| 返回码 | 含义 | 处理方式 |
|--------|------|---------|
| `0` | 成功，已走 SDK 代理 | — |
| `-2` | 传入的 WebView 为 nil | 传入有效的 `WKWebView` |
| `-101` | SDK 未初始化，或本地代理尚不可用 | 确认 `AXService.initialize(_:)` 返回 `0` 后再调一次（可重复调用） |
| `-411` | 无法基于本地代理端点构造 `nw_proxy_config` | 检查 SDK 状态与 Edge 连通性 |

## 验证接入是否成功

运行 App，在 Xcode 控制台关注带 `[AXWebView]` 标签的日志。接入成功时你应看到：

1. `AXService.initialize(_:)` 未输出错误日志。
2. 安装时出现 `[AXWebView] proxy applied: 127.0.0.1:<port>`。

如有异常，参考下表排查：

| 现象 | 原因 | 处理方式 |
|------|------|---------|
| `AXService.initialize(_:)` 返回负数 | 凭证无效或 Edge 不可达 | 核对 `accessKeyID`、`accessKeySecret`、`edgeNodes` |
| 控制台出现 `[AXWebView] proxy unavailable` | 在 `AXService.initialize(_:)` 成功前安装 | 确认初始化返回 `0` 后再安装 |
| WebView 仍为直连 | 设备系统低于 iOS 17 | 本封装仅在 iOS 17+ 代理 WebView |

## 已知限制

1. **iOS < 17**：系统未提供 WebView 代理能力，流量保持直连，`install(on:)` 在此类设备上不生效。
2. **请求签名 / 追加头部**：当前版本仅提供代理转发，尚不支持对 WebView 请求做签名或改写头部。该能力规划在后续版本中，且**完全是封装库内部的增量改动**：签哪些请求、怎么签由 `AXService.initialize()` 统一配置，封装侧入口仍是 `install(on:)`，**接入代码无需任何改动**。需注意届时可签名的范围**仅限页面 JS 发起的 `fetch`/`XHR`/表单提交**，覆盖不了主文档导航与浏览器引擎加载的子资源。
3. **覆盖既有 proxyConfigurations**：安装时会将该 WebView 的 `proxyConfigurations` 设为 SDK 代理（覆盖你已有的同名设置）。

## 接口稳定性与演进约定

为保证 SDK 升级时**接入代码零改动**，本封装库遵循以下契约：

1. **`install(on:)` 是冻结的稳定入口。** 它永远只表示"为这个 WebView 开启 SDK 保护"，不承载业务参数；后续新增能力不会改变它的签名。
2. **所有可配置项都收敛到 `AXService.initialize(_:)`。** 例如上文「已知限制 #2」中规划的请求签名 / 改头——签哪些请求（host/path 白名单）、加什么头、密钥来源、取不到凭据时放行还是拦截——一律在 `initialize(_:)` 配置，绝不进 `install` 的参数。配置面与调用面解耦。
3. **只增不改（additive-only）。** 即便将来出现必须在 WebView 创建期介入的能力，也会以**新增可选 API** 的形式提供，而不修改 `install(on:)`；现有调用照常工作。
4. **调用时序契约保持不变。** 始终是"`AXService.initialize(_:)` 成功后、首次 `load(_:)` 前调用 `install(on:)`"。这条时序对未来能力（如页面内请求签名所需的 JS 注入）是前向兼容的，请勿打破。

**对你的意义：** 可以把 SDK 当作"代理 +（后续可能的）页面内请求签名"双路径来用，但接入面始终只有两处——`AXService.initialize(_:)`（配置）与 `AXWebViewService.install(on:)`（开启）。SDK 后续升级即为内部演进，你的接入代码无需改动。
