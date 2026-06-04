# SDK Quickstart：Android Java HttpsURLConnection

[English](./README.en.md) | 简体中文

本快速开始文档面向使用 Java 编写、并通过 `HttpsURLConnection` 发起 API 请求、希望使用 SDK 进行保护的原生 Android 应用。如果你的情况不符合，请查阅其他更合适的快速开始指南。

本页介绍将 SDK 接入你的应用所需的全部步骤。此外还提供配套示例工程 [java-httpsurlconn-demo](java-httpsurlconn-demo/) 可供参考。

## 添加 SDK 服务依赖

在应用模块的 `build.gradle` 中添加依赖：

```groovy
dependencies {
    implementation fileTree(include: ['*.jar', '*.aar'], dir: 'libs')
}
```

然后将 `axsecurity-android-httpsurlconn.aar` 和 `axsecurity-android-sdk.aar` 拷贝到应用模块的 `libs/` 目录：

```
app/
└── libs/
    ├── axsecurity-android-httpsurlconn.aar
    └── axsecurity-android-sdk.aar
```

## 修改 Manifest

使用 SDK 需要在 Manifest 中声明以下权限：

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

SDK 支持的最低 SDK 版本为 21（Android 5.0）。

## 初始化 SDK

要使用 SDK，必须在应用启动时（通常在 `Application.onCreate` 中）完成初始化：

```java
import android.app.Application;
import android.util.Log;

import com.axsecurity.sdk.axhttp.httpsurlconn.AXHTTPService;
import com.axsecurity.sdk.base.AXConfig;
import com.axsecurity.sdk.service.AXService;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();

        String accessKeyId = "<YOUR_ACCESS_KEY_ID>";
        String accessKeySecret = "<YOUR_ACCESS_KEY_SECRET>";
        String[] edgeNodes = {"<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>"};

        AXConfig config = new AXConfig.Builder()
            .accessKey(accessKeyId, accessKeySecret)
            .edgeNodes(edgeNodes)
            .build();

        int result = AXService.initialize(this.getApplicationContext(), config);
        if (result != 0) {
            Log.e("MyApp", "SDK initialization failed: " + result);
        }
    }
}
```

`initialize` 方法在成功时返回 `0`，失败时返回负值错误码：

> **重要：** `AXService.initialize` 必须在调用任何 `AXHTTPService` 方法之前执行且仅执行一次，不支持重复调用。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AXConfig.Builder().accessKey(...)` | AccessKey ID 与 Secret（必填），从控制台获取 |
| `AXConfig.Builder().edgeNodes(...)` | 指向 AxisNow Edge DoH 服务的 EIP 或域名（必填），传入 `String[]`，至少 1 个，推荐 2+ |

本 demo 仅使用上述最小必填字段。`AXConfig.Builder` 的完整选项（DNS 配置、加密隧道开关等）以及参数语义详见 SDK 接入指南。

## 使用 AXHTTPService

完成初始化后，通过 `AXHTTPService` 获取 `HttpsURLConnection` 发起 API 请求：

```java
URL url = new URL("https://example.com");
HttpsURLConnection connection = AXHTTPService.getHttpsURLConnection(url);
```

返回的是一个标准的 `HttpsURLConnection`，已经绑定到目标 URL，并通过 HTTPS CONNECT 隧道经由 SDK 本地 HTTP 代理转发。可以像使用未经代理的 `HttpsURLConnection` 一样，在其上配置请求头、请求方法、超时时间等。

## 自定义 HttpsURLConnection

默认情况下，`getHttpsURLConnection(url)` 返回的 `HttpsURLConnection` 已经设置好本地代理。TLS 在应用与目标服务器之间端到端协商，代理不会终止 TLS。因此所有连接级的自定义配置都可以直接在返回的实例上完成，与未经代理的连接使用方式一致。例如原有代码：

```java
HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();
connection.setConnectTimeout(5_000);
connection.setReadTimeout(5_000);
```

替换为：

```java
HttpsURLConnection connection = AXHTTPService.getHttpsURLConnection(url);
connection.setConnectTimeout(5_000);
connection.setReadTimeout(5_000);
```

> **注意：** 每次调用 `getHttpsURLConnection(url)` 都会返回一个新的连接实例。请在返回对象上进行每次请求独立的配置。

如果应用需要自定义 SSL/TLS 配置（例如证书锁定 certificate pinning），直接在返回的 connection 上设置即可：

```java
HttpsURLConnection connection = AXHTTPService.getHttpsURLConnection(url);
connection.setSSLSocketFactory(yourSslSocketFactory);
connection.setHostnameVerifier(yourHostnameVerifier);
```

## 错误处理

当 SDK 未初始化或本地代理不可用时，`AXHTTPService.getHttpsURLConnection(url)` 会返回 `null`。发起请求前务必检查返回值：

```java
HttpsURLConnection connection = AXHTTPService.getHttpsURLConnection(url);
if (connection == null) {
    // SDK 未就绪 —— 检查初始化结果，或稍后重试
    return;
}
```

API 调用过程中的网络错误会以 `HttpsURLConnection` 方法抛出的标准 `IOException` 形式上报，像平常一样处理即可：

```java
try {
    connection.setRequestMethod("GET");
    connection.connect();
    int code = connection.getResponseCode();
    // 处理响应
} catch (IOException e) {
    // 网络错误 —— 检查网络连接，必要时重试
} finally {
    connection.disconnect();
}
```

## 验证集成是否生效

集成完成后运行应用，在 Logcat 中过滤 `AXHTTPService` 标签。集成成功时应当看到：

1. 初始化期间 `AXHTTPService` 没有错误日志。
2. API 请求经过 SDK 的本地代理并返回预期响应。

若出现异常，可参考下表排查常见问题：

| 现象 | 原因 | 解决方式 |
|------|------|----------|
| `initialize` 返回 `-1` | 凭证错误或 Edge 节点不可达 | 核对 `accessKeyId`、`accessKeySecret` 与 `edgeNodes` |
| `getHttpsURLConnection()` 返回 `null` | SDK 未初始化或代理未就绪 | 确认 `initialize` 已返回 `0` 再调用 `getHttpsURLConnection()` |
| Logcat 出现 `Local HTTP proxy not available` | 内部代理启动失败 | 检查网络权限与 Edge 节点连通性 |
