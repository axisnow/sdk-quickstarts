# SDK Quickstart：Android Kotlin OkHttp

[English](./README.en.md) | 简体中文

本快速接入文档面向使用 Kotlin 开发、并通过 OkHttp 发起需要 SDK 保护的 API 调用的原生 Android 应用。如果你的场景不符，请查看其他更适合的快速接入文档。

本页提供了将 SDK 集成到你的应用中的全部步骤。此外，我们还提供了基于 [kotlin-okhttp-demo](kotlin-okhttp-demo/) 的分步教程示例。

## 添加 SDK 服务依赖

在应用的 `build.gradle` 中添加依赖：

```groovy
dependencies {
    implementation fileTree(include: ['*.jar', '*.aar'], dir: 'libs')
}
```

然后将 `axsecurity-android-okhttp.aar` 和 `axsecurity-android-sdk.aar` 拷贝到应用的 `libs/` 目录：

```
app/
└── libs/
    ├── axsecurity-android-okhttp.aar
    └── axsecurity-android-sdk.aar
```

## 清单文件修改

在 `AndroidManifest.xml` 中声明以下权限：

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

注意：SDK 支持的最低 Android SDK 版本为 21（Android 5.0）。

## 初始化 SDK

使用 SDK 前，必须在应用创建时完成初始化，通常放在 `onCreate` 方法中：

```kotlin
import android.app.Application
import android.util.Log

import com.axsecurity.sdk.axhttp.okhttp.AXHTTPService
import com.axsecurity.sdk.base.AXConfig
import com.axsecurity.sdk.service.AXService

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        val accessKeyId = "your accessKeyId from SDK Deployment"
        val accessKeySecret = "your accessKeySecret from SDK Deployment"
        val edgeNodes = arrayOf("edge IP")
        val routingDomain = "routing Domain"

        val config = AXConfig.Builder()
            .accessKey(accessKeyId, accessKeySecret)
            .edgeNodes(edgeNodes)
            .routingDomain(routingDomain)
            .build()

        val result = AXService.initialize(applicationContext, config)
        if (result != 0) {
            Log.e("MyApp", "SDK initialization failed: $result")
        }
    }
}
```

`initialize` 方法成功时返回 `0`，失败时返回负数错误码。

> **重要提示：** `AXService.initialize` 必须在调用任何 `AXHTTPService` 方法之前**仅调用一次**，不支持多次调用。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AXConfig.Builder().accessKey(...)` | AccessKey ID 与 Secret（必填），从控制台获取 |
| `AXConfig.Builder().edgeNodes(...)` | Edge 节点地址列表（必填），传入 `Array<String>`，至少 1 个，推荐 2+ |

本 demo 仅使用上述最小必填字段。`AXConfig.Builder` 的完整选项（DNS 配置、加密隧道开关等）以及参数语义详见 SDK 接入指南。

## 使用 AXHTTPService

通过 `AXHTTPService` 获取 `OkHttpClient`，即可发起受保护的 OkHttp API 调用：

```kotlin
val client = AXHTTPService.getOkHttpClient()
```

该方法返回的 `OkHttpClient` 已自动配置 SDK 本地代理并被缓存。所有需要保护的 API 调用都应使用这个 client。

## 自定义 OkHttp Builder

默认情况下，`getOkHttpClient()` 使用 `OkHttpClient.Builder()` 构造 client。但你现有的代码可能使用了自定义 client，例如不同的超时时间或其他拦截器。假设你原有代码如下：

```kotlin
val client = OkHttpClient.Builder()
    .callTimeout(30, TimeUnit.SECONDS)
    .build()
```

可以通过如下方式将自定义 builder 传递给 `AXHTTPService`：

```kotlin
val builder = OkHttpClient.Builder().callTimeout(30, TimeUnit.SECONDS)
AXHTTPService.setOkHttpClientBuilder(builder)
val client = AXHTTPService.getOkHttpClient()
```

> **注意：** 调用 `setOkHttpClientBuilder` 会使缓存的 client 失效。下次调用 `getOkHttpClient()` 时将重新构造一个新的 client。

如果应用需要自定义 SSL/TLS 设置（例如证书固定），请在传入 builder 前直接配置：

```kotlin
val builder = OkHttpClient.Builder()
    .callTimeout(30, TimeUnit.SECONDS)
    .sslSocketFactory(yourSslSocketFactory, yourTrustManager)
    .hostnameVerifier(yourHostnameVerifier)
AXHTTPService.setOkHttpClientBuilder(builder)
val client = AXHTTPService.getOkHttpClient()
```

## 错误处理

当 SDK 未初始化或本地代理不可用时，`AXHTTPService.getOkHttpClient()` 会返回 `null`。发起请求前务必检查返回值：

```kotlin
val client = AXHTTPService.getOkHttpClient()
if (client == null) {
    // SDK not ready — check initialization result or retry later
    return
}
```

API 调用过程中的网络错误会以标准 OkHttp `IOException` 的形式抛出，按常规方式处理即可：

```kotlin
client.newCall(request).enqueue(object : Callback {
    override fun onResponse(call: Call, response: Response) {
        // handle response
    }

    override fun onFailure(call: Call, e: IOException) {
        // network error — check connectivity and retry if appropriate
    }
})
```

## 验证接入是否成功

完成 SDK 集成后，运行应用并在 Logcat 中过滤 `AXHTTPService` 标签。接入成功时应观察到：

1. 初始化过程中无 `AXHTTPService` 相关错误日志；
2. API 请求通过 SDK 本地代理发出，并返回预期响应。

如果出现异常，请参考以下常见问题排查：

| 现象 | 原因 | 解决方案 |
|------|------|---------|
| `initialize` 返回 `-1` | 凭证错误或 Edge 不可达 | 检查 `accessKeyId`、`accessKeySecret` 和 `edgeNodes` 是否正确 |
| `getOkHttpClient()` 返回 `null` | SDK 未初始化或代理未就绪 | 确保 `initialize` 返回 `0` 后再调用 `getOkHttpClient()` |
| Logcat 出现 `Local HTTP proxy not available` | 内部代理启动失败 | 检查网络权限和 Edge 连通性 |
