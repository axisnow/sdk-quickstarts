# SDK 快速接入：Flutter HTTP Client

[English](./README.en.md) | 简体中文

本快速接入指南面向使用 [`Flutter`](https://flutter.dev/) 开发、并通过 [`HTTP Client`](https://pub.dev/documentation/http/latest/http/Client-class.html)、[`Dart IO HttpClient`](https://api.dart.dev/stable/2.16.2/dart-io/HttpClient-class.html) 或 [`Dio`](https://pub.dev/packages/dio) 发起网络请求的 Android / iOS 应用。如果你的场景与此不符，请查阅更贴近的接入指南。

本页列出了将 SDK 集成到你的应用所需的全部步骤；同时我们还提供了基于示例工程的分步教程。

## 添加 SDK 服务依赖

SDK 以本地 plugin 工程的形式提供，可直接通过 `pubspec.yaml` 中的本地依赖引用。在应用的 `pubspec.yaml` 的 `dependencies:` 段下添加：

```yaml
  axsecurity_flutter_plugin:
    path: ./../axsecurity_flutter_plugin
```

`axsecurity_flutter_plugin` 包暴露了若干可直接使用的类：

1. `AxService` —— 对底层 SDK 的高层封装。
2. `AxClient` —— Flutter [http](https://pub.dev/packages/http) 包中 `Client` 的直接替代品；内部使用 `AxHttpClient` 实现。

### Android Manifest 修改

在 `AndroidManifest.xml` 中声明以下权限以使用 SDK：

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

注意：SDK 支持的最低 Android SDK 版本为 21（Android 5.0）。

### iOS Framework 依赖

在 Xcode 工程的 **Build Phases → Link Binary with Libraries** 中加入以下 framework / library：

1. `libz.tbd` —— 压缩库
2. `libc++.tbd` —— C++ 标准库
3. `DeviceCheck.framework` —— Apple DeviceCheck 框架
4. `CoreTelephony.framework` —— Apple CoreTelephony 框架
5. `libresolv.tbd` —— DNS 解析

iOS 最低支持版本为 12.0。

## 初始化 AxService

使用 `AxService` 前，必须在 App 启动时完成一次初始化，并在所有其他 `AxService` / `AxClient` 调用之前完成：

```Dart
import 'package:axsecurity_flutter_plugin/axsecurity_flutter_plugin.dart';
import 'package:flutter/services.dart';

int? result;
// Platform messages 可能失败，使用 try/catch 捕获 PlatformException，
// 并处理可能为 null 的返回值。
try {
    var accessKeyId = 'SDK 部署时获得的 accessKeyId';
    var accessKeySecret = 'SDK 部署时获得的 accessKeySecret';
    var edgeNodes = ['Edge 节点 IP'];

    AxConfig cfg = AxConfig(
        accessKeyId: accessKeyId,
        accessKeySecret: accessKeySecret,
        edgeNodes: edgeNodes,
    );

    result = await AxService.initialize(config: cfg);
} on PlatformException {
    result = -1;
}
if (result == 0) {
    // 初始化成功
}
```

`initialize` 成功时返回 `0`，失败时返回负数错误码。

> **重要：** `initialize` 必须在调用任何其他 `AxService` / `AxClient` 方法之前**仅调用一次**，不支持多次调用。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AxConfig(accessKeyId: ...)` | AccessKey ID（必填），从控制台获取 |
| `AxConfig(accessKeySecret: ...)` | AccessKey Secret（必填），从控制台获取 |
| `AxConfig(edgeNodes: ...)` | Edge 节点地址列表（必填），`List<String>`，至少 1 个，推荐 2+ |
| `AxConfig(dns: ...)` | DNS 配置（可选），通过 `AxDnsConfig` 构造。传入 `edgeDohResolveDomains: [...]` 将主机加入 EdgeDoH 白名单；传入 `edgeDohBypassDomains: [...]` 为白名单中的特定主机豁免（bypass 优先于 resolve）。匹配规则为精确域名或 `*.suffix` 通配。**未配置白名单时所有主机走系统 DNS**，需要 EdgeDoH 防护的主机请显式加入。 |

完整参数语义、约束与默认行为见接入指南附录 A。

## 配合 HTTP Client 使用

`axsecurity_flutter_plugin` 包中的 `AxClient` 可作为 Flutter http 包中 [`HTTP Client`](https://pub.dev/documentation/http/latest/http/Client-class.html) 的直接替代品。它处理请求的方式与标准 client 完全一致，但额外具备 SDK 提供的防护能力。

创建 `AxClient` 后即可像普通 `http.Client` 一样发起请求并 `await` 响应：

```Dart
http.Client client = AxClient();
http.Response response = await client.get(Uri.parse('https://your.domain/api'));
```

## 配合 Dio 使用

由于 [`Dio`](https://pub.dev/packages/dio) 内部基于 `HttpClient` 实现，因此也可以与 SDK 配合使用。在创建 `Dio` 对象时，按以下方式替换其底层使用的 client：

```Dart
import 'package:dio/adapter.dart';
...
var dio = Dio();
(dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
  return AxHttpClient();
};
```

创建 `Dio` 后即可像普通 Dio 一样发起请求并 `await` 响应：

```Dart
var response = await dio.get('https://your.domain/api');
```

## 错误处理

当 platform channel 抛出 `PlatformException` 时，`AxService.initialize` 会返回 `null`；当原生 SDK 拒绝配置时，会返回负数错误码。在通过 `AxClient` 或 `AxHttpClient` 发起任何请求前，务必检查返回值：

```Dart
int? result;
try {
    result = await AxService.initialize(config: cfg);
} on PlatformException {
    result = -1;
}
if (result != 0) {
    // SDK 未就绪，检查凭证、Edge 可达性，或稍后重试
    return;
}
```

请求过程中的网络错误会以标准 http / Dio 异常类型抛出，按常规方式处理即可：

```Dart
try {
    var response = await client.get(Uri.parse('https://your.domain/api'));
} on http.ClientException catch (e) {
    // 网络错误：检查连通性，必要时重试
}
```

## 验证接入是否成功

完成 SDK 集成后，运行应用并查看平台日志（Android 上的 Logcat、iOS 上的 Xcode 控制台），过滤 `AXService` / `AXHTTPService` 标签。接入成功时应观察到：

1. 初始化过程中无 `AXService` 相关错误日志；
2. `AxService.initialize` 返回 `0`；
3. 通过 `AxClient` 或 `AxHttpClient` 发起的请求经过 SDK 本地代理，并返回预期响应。

如果出现异常，请参考以下常见问题排查：

| 现象 | 原因 | 解决方案 |
|------|------|---------|
| `initialize` 返回负数 | 凭证错误或 Edge 不可达 | 检查 `accessKeyId`、`accessKeySecret` 和 `edgeNodes` 是否正确 |
| `initialize` 返回 `null`（`PlatformException`） | 原生插件未链接或构建配置不完整 | 重新执行 `flutter pub get`；iOS 端确认上述 framework 已链接；Android 端确认 AAR 已正确打包 |
| 请求超时或报 `Connection refused` | 内部代理启动失败 | 检查网络权限与 Edge 连通性；确保 `initialize` 返回 `0` 后再发起请求 |
