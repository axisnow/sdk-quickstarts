# SDK 快速接入：Flutter WebView（flutter_inappwebview）

[English](./README.en.md) | 简体中文

本快速接入文档面向使用 [`flutter_inappwebview`](https://pub.dev/packages/flutter_inappwebview)
加载网页的 Flutter 应用，帮助你让 WebView 的流量经由 AxSecurity SDK 的本地代理转发，
从而获得调度、加速、EdgeDoH 防劫持解析与 SecureProxy 隧道加密能力。

对外只有一个入口 `AxService.installOnWebView(controller)`：它在 WebView 上启用 SDK 代理
（Android 进程级全局；iOS 17+ 默认 `WKWebsiteDataStore`），**不接管你的任何回调**——
你的 `InAppWebView` 仍完全由你掌控。

> **开箱即编**：本示例默认**不含 SDK**，SDK 接入代码全部注释，仅依赖 `flutter_inappwebview`
> 即可编译运行（纯 WebView 骨架）。按下面步骤取消注释即可接入。

## 启用 SDK（三处取消注释）

1. **`pubspec.yaml`**：取消 `axsecurity_flutter_plugin` 依赖的注释，然后 `flutter pub get`。
   > 该依赖会传递引入 `flutter_inappwebview`，并要求 **Android `compileSdk 34`、iOS 12+**
   > （本工程已配置好）。

2. **`lib/main.dart` 顶部**：取消 `import 'package:axsecurity_flutter_plugin/...'` 两行注释。

3. **初始化 + 安装代理**：取消 `main()` 里的 `AxService.initialize(...)` 与
   `_setUpAndLoad` 里的 `AxService.installOnWebView(controller)` 注释。

## 初始化 AxService

必须在**首个 WebView 加载之前**、仅初始化一次（放在 `main()`）：

```dart
WidgetsFlutterBinding.ensureInitialized();
await AxService.initialize(config: AxConfig(
  accessKeyId: '<YOUR_ACCESS_KEY_ID>',
  accessKeySecret: '<YOUR_ACCESS_KEY_SECRET>',
  edgeNodes: ['<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>'],
  dns: AxDnsConfig(edgeDohResolveDomains: ['<YOUR_DOMAIN>']),
  proxy: AxProxyConfig(secureProxyEnabled: true),
));
```

`initialize` 成功返回 `0`，失败返回负数。**未配置 `edgeDohResolveDomains` 白名单时所有域名走系统 DNS**，需要 EdgeDoH 防护的域名请显式加入。

## 为 WebView 安装代理（时序契约）

在 `onWebViewCreated` 里 **先 `await installOnWebView` 再 `loadUrl`**，且 `InAppWebView`
**不要设 `initialUrlRequest`**：

```dart
InAppWebView(
  // 不设 initialUrlRequest——否则会在代理生效前就开始加载
  onWebViewCreated: (controller) async {
    final rc = await AxService.installOnWebView(controller); // 1. 装代理（await 后已生效）
    await controller.loadUrl(                                // 2. 再加载
      urlRequest: URLRequest(url: WebUri(url)),
    );
  },
)
```

为什么是这个顺序：`await` 返回即代理已就位，首个请求不会直连泄漏；且将来的「请求签名」会在
`installOnWebView` 内部注入 document-start 的 fetch/XHR 桥，只有「安装在首次加载之前」才能覆盖首屏。
**接入代码无需为将来的签名能力改动**（签名策略统一走 `AxService.initialize(...)`）。

## 错误码

`installOnWebView` 不抛异常，返回 `int`：

| 返回码 | 含义 |
|------|------|
| `0` | 成功，已走 SDK 代理 |
| `-101` | SDK 未初始化 / 本地代理不可用（确认 `initialize` 返回 0） |
| `-401` | Android：设备 WebView 不支持 `PROXY_OVERRIDE`，或运行时缺 `androidx.webkit` |
| `-411` | iOS 低于 17（`proxyConfigurations` 不可用） |

## 运行

```bash
flutter pub get
flutter run                 # 或 task flutter:android:webview-demo / flutter:ios:webview-demo
```

> Android 构建需 JDK 17（Gradle 7.5 与 Flutter 默认 JDK 21 不兼容时，
> `flutter config --jdk-dir <JDK17>`）。

## 已知限制

- **进程级 / 默认 store**：Android 启用后影响进程内所有 WebView；iOS 仅覆盖默认
  `WKWebsiteDataStore`——inappwebview 开 `incognito: true`（非持久 store）或自定义 store
  **不生效**，且无法补（拿不到该实例）。
- **iOS 仅 17+**：低于 17 无代理（返回 `-411`）。
- **请求签名 / 改写头部**：一期不提供。代理在 HTTPS 下是 CONNECT 隧道、改不了请求头；
  该能力规划在后续版本，且完全是封装内部增量——接入代码（仍是 `installOnWebView`）无需改动。
- **协议**：HTTP/HTTPS/WebSocket 经 HTTP CONNECT 转发；WebRTC、QUIC/HTTP3(UDP) 等不经代理。
