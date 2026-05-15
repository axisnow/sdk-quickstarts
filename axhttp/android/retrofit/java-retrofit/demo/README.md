# AgentSDK Quickstart：Android Java Retrofit

[English](./README.en.md) | 简体中文

本快速接入文档面向使用 Java 开发、并通过 Retrofit 发起需要 AgentSDK 保护的 API 调用的原生 Android 应用。如果你的场景不符，请查看其他更适合的快速接入文档。

本页提供了将 AgentSDK 集成到你的应用中的全部步骤。此外，我们还提供了基于 [java-retrofit-demo](java-retrofit-demo/) 的分步教程示例。

## 添加 AgentSDK 服务依赖

在应用的 `build.gradle` 中添加依赖：

```groovy
dependencies {
    implementation fileTree(include: ['*.jar', '*.aar'], dir: 'libs')
}
```

然后将 `axsecurity-android-retrofit.aar` 和 `axsecurity-android-sdk.aar` 拷贝到应用的 `libs/` 目录：

```
app/
└── libs/
    ├── axsecurity-android-retrofit.aar
    └── axsecurity-android-sdk.aar
```

## 清单文件修改

在 `AndroidManifest.xml` 中声明以下权限：

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```
注意，AgentSDK 支持的最低 SDK 版本为 21（Android 5.0）。

## 初始化 AXHTTPService

使用 `AXHTTPService` 前，必须在应用创建时完成初始化，通常放在 `onCreate` 方法中：

```java
import android.app.Application;
import android.util.Log;

import com.axsecurity.sdk.axhttp.retrofit.AXHTTPService;
import com.axsecurity.sdk.base.Config;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();

        String accessKeyID = "your accessKeyID from SDK Deployment";
        String accessKeySecret = "your accessKeySecret from SDK Deployment";
        String[] edgeAddresses = {"edge IP"};

        Config config = new Config.Builder()
            .accessKeyID(accessKeyID)
            .accessKeySecret(accessKeySecret)
            .edgeAddresses(edgeAddresses)
            .build();

        int result = AXHTTPService.initialize(this.getApplicationContext(), config);
        if (result != 0) {
            Log.e("MyApp", "AgentSDK initialization failed: " + result);
        }
    }
}
```

`initialize` 方法成功时返回 `0`，失败时返回负数错误码。

> **重要提示：** `initialize` 必须在调用任何其他 `AXHTTPService` 方法之前**仅调用一次**，不支持多次调用。

## 参数说明

| 参数 | 说明 |
|------|------|
| `Config.Builder().accessKeyID(...)` | AccessKey ID（必填），从控制台获取 |
| `Config.Builder().accessKeySecret(...)` | AccessKey Secret（必填），从控制台获取 |
| `Config.Builder().edgeAddresses(...)` | Edge 节点地址列表（必填），传入 `String[]`，至少 1 个，推荐 2+ |

本 demo 仅使用上述最小必填字段。`Config.Builder` 的完整选项（DNS 配置、加密隧道开关等）以及参数语义详见 AgentSDK 接入指南。

## 使用 AXHTTPService

通过 `AXHTTPService` 获取 `Retrofit` 实例，即可发起受保护的 Retrofit API 调用。请使用长生命周期的 `Retrofit.Builder`，并缓存返回的 `Retrofit` 实例：

```java
public class ClientInstance {
    private static final String BASE_URL = "https://your.domain";
    private static Retrofit retrofit;

    public static Retrofit getRetrofitInstance() {
        if (retrofit == null) {
            Retrofit.Builder builder = new Retrofit.Builder()
                .baseUrl(BASE_URL)
                .addConverterFactory(GsonConverterFactory.create());
            retrofit = AXHTTPService.getRetrofit(builder);
        }
        return retrofit;
    }
}
```

该方法返回的 `Retrofit` 实例已自动配置 AgentSDK 本地代理并被缓存。所有需要保护的 API 调用都应使用这个实例。

> **注意：** 需要缓存返回的 `Retrofit` 实例，而不是 `Retrofit.Builder`。`AXHTTPService.getRetrofit` 内部按 builder 引用身份缓存，每次传入新构造的 builder 会使缓存条目在进程生命周期内持续累积。

## 自定义 OkHttp Builder

默认情况下，`getRetrofit(builder)` 使用 `new OkHttpClient.Builder()` 构造底层 client。但你现有的代码可能使用了自定义 client，例如不同的超时时间或其他拦截器。假设你原有代码如下：

```java
OkHttpClient client = new OkHttpClient.Builder()
    .connectTimeout(5, TimeUnit.SECONDS)
    .build();
Retrofit retrofit = new Retrofit.Builder()
    .baseUrl("https://your.domain/")
    .client(client)
    .build();
```

可以通过如下方式将自定义 builder 传递给 `AXHTTPService`：

```java
AXHTTPService.setOkHttpClientBuilder(
    new OkHttpClient.Builder().connectTimeout(5, TimeUnit.SECONDS));
Retrofit.Builder retrofitBuilder = new Retrofit.Builder()
    .baseUrl("https://your.domain/");
Retrofit retrofit = AXHTTPService.getRetrofit(retrofitBuilder);
```

> **注意：** 调用 `setOkHttpClientBuilder` 会使缓存的 client 失效。下次调用 `getRetrofit()` 时将重新构造一个新的 client。

如果应用需要自定义 SSL/TLS 设置（例如证书固定），请在传入 builder 前直接配置：

```java
OkHttpClient.Builder builder = new OkHttpClient.Builder()
    .connectTimeout(5, TimeUnit.SECONDS)
    .sslSocketFactory(yourSslSocketFactory, yourTrustManager)
    .hostnameVerifier(yourHostnameVerifier);
AXHTTPService.setOkHttpClientBuilder(builder);
Retrofit.Builder retrofitBuilder = new Retrofit.Builder()
    .baseUrl("https://your.domain/");
Retrofit retrofit = AXHTTPService.getRetrofit(retrofitBuilder);
```

## 错误处理

当 SDK 未初始化或本地代理不可用时，`AXHTTPService.getRetrofit(builder)` 会返回 `null`。发起请求前务必检查返回值：

```java
Retrofit retrofit = AXHTTPService.getRetrofit(builder);
if (retrofit == null) {
    // SDK not ready — check initialization result or retry later
    return;
}
```

API 调用过程中的网络错误会以标准 Retrofit/OkHttp `IOException` 的形式抛出，按常规方式处理即可：

```java
apiService.getResource().enqueue(new Callback<Resource>() {
    @Override
    public void onResponse(Call<Resource> call, Response<Resource> response) {
        // handle response
    }

    @Override
    public void onFailure(Call<Resource> call, Throwable t) {
        // network error — check connectivity and retry if appropriate
    }
});
```

## 验证接入是否成功

完成 SDK 集成后，运行应用并在 Logcat 中过滤 `AXHTTPService` 标签。接入成功时应观察到：

1. 初始化过程中无 `AXHTTPService` 相关错误日志；
2. API 请求通过 SDK 本地代理发出，并返回预期响应。

如果出现异常，请参考以下常见问题排查：

| 现象 | 原因 | 解决方案 |
|------|------|---------|
| `initialize` 返回 `-1` | 凭证错误或 Edge 不可达 | 检查 `accessKeyID`、`accessKeySecret` 和 `edgeAddresses` 是否正确 |
| `getRetrofit()` 返回 `null` | SDK 未初始化或代理未就绪 | 确保 `initialize` 返回 `0` 后再调用 `getRetrofit()` |
| Logcat 出现 `Local HTTP proxy not available` | 内部代理启动失败 | 检查网络权限和 Edge 连通性 |
