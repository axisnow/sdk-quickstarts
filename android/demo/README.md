# SDK Quickstart：Android Java

[English](./README.en.md) | 简体中文

本快速接入文档面向使用 Java 开发、并通过 HTTP(S) / SOCKS5 代理发起需要 SDK 保护的 API 调用的原生 Android 应用。如果你的场景不符，请查看其他更适合的快速接入文档。

本页提供了将 SDK 集成到你的应用中的全部步骤。此外，我们还提供了基于 [axsecurity-demo](axsecurity-demo/) 的分步教程示例。

## 添加 SDK 服务依赖

在应用的 `build.gradle` 中添加依赖：

```groovy
dependencies {
    implementation fileTree(include: ['*.jar', '*.aar'], dir: 'libs')
}
```

然后将 `axsecurity-android-sdk.aar` 拷贝到应用的 `libs/` 目录：

```
app/
└── libs/
    └── axsecurity-android-sdk.aar
```

## 清单文件修改

在 `AndroidManifest.xml` 中声明以下权限：

```xml
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.INTERNET" />
```

注意：SDK 支持的最低 Android SDK 版本为 21（Android 5.0）。

## 初始化 AXService

使用 `AXService` 前，必须在应用创建时完成初始化，通常放在 `onCreate` 方法中：

```java
import android.app.Application;
import android.util.Log;

import com.axsecurity.sdk.service.AXService;
import com.axsecurity.sdk.base.AXConfig;

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
            .dns(new AXConfig.DnsConfig.Builder()
                .edgeDohResolveDomains("*.example.com")
                .build())
            .build();

        int result = AXService.initialize(this.getApplicationContext(), config);
        if (result != 0) {
            Log.e("MyApp", "SDK initialization failed: " + result);
        }
    }
}
```

`initialize` 方法成功时返回 `0`，失败时返回负数错误码。

> **重要提示：** `initialize` 必须在调用任何其他 `AXService` 方法之前**仅调用一次**，不支持多次调用。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AXConfig.Builder().accessKey(...)` | AccessKey ID 与 Secret（必填），从控制台获取 |
| `AXConfig.Builder().edgeNodes(...)` | 指向 AxisNow Edge DoH 服务的 EIP 或域名（必填），传入 `String[]`，至少 1 个，推荐 2+ |
| `AXConfig.Builder().dns(...)` | DNS 配置（可选），通过 `AXConfig.DnsConfig.Builder` 构造。通过 `edgeDohResolveDomains(String...)` 加入 EdgeDoH 白名单；通过 `edgeDohBypassDomains(String...)` 为白名单中的域名豁免（bypass 优先于 resolve）。两者均接受可变参数或 `String[]`。匹配规则为精确域名或 `*.suffix` 通配。**未配置白名单时所有域名走系统 DNS**，需要 EdgeDoH 防护的域名请显式加入。 |

完整参数语义、约束与默认行为见接入指南附录 A。

## 使用 AXService

`AXService` 提供 `getLocalHTTPProxy` API，返回本地 HTTP 代理端点。只要是支持 `java.net.Proxy` 的 Java HTTP 客户端，都可以通过该端点把流量接入 SDK，由 SDK 透明地转发至受保护通道。

```java
String demoURL = "https://your.server.domain/";

AXLocalProxy localProxy = AXService.getLocalHTTPProxy();
if (localProxy == null) {
    // SDK 未就绪，检查初始化结果或稍后重试
    return;
}

Proxy httpProxy = new Proxy(Proxy.Type.HTTP,
        new InetSocketAddress(localProxy.getIp(), localProxy.getPort()));
HttpURLConnection conn = (HttpURLConnection) new URL(demoURL).openConnection(httpProxy);
// 设置请求方法、超时，按常规方式读取响应
```

> **提示：** 如果你已经在使用 OkHttp、Retrofit 或 HttpsURLConnection 等主流 HTTP 客户端，推荐直接使用 SDK 配套的 **AxHTTP** 封装——它已经替你管理好 `getLocalHTTPProxy()`、`Proxy` 构造与客户端生命周期，无需再手写本节示例。

可直接运行的按钮示例参见 [`axsecurity-demo/MainActivity.java`](axsecurity-demo/src/main/java/com/axsecurity/sdk/service/demo/MainActivity.java)。默认 demo **不依赖 SDK** 即可编译运行，HTTPRequest 按钮会直连 `mDemoURL` 发请求。完成 SDK 初始化后，按文件内 `*** UNCOMMENT ... FOR SDK ***` 提示取消注释、并按 `*** COMMENT ... FOR SDK ***` 提示注释掉对应的默认实现，即可把请求切换到 SDK 提供的本地 HTTP 代理通道。

### 其他代理端点（SOCKS5）

除 HTTP 代理外，`AXService` 还暴露了本地 SOCKS5 代理（demo UI 中未直接演示，按需启用）。`HttpURLConnection` 在 `Proxy.Type.SOCKS` 类型下即走 SOCKS5：

```java
String demoURL = "https://your.server.domain/";

AXLocalProxy socks5 = AXService.getLocalSocks5Proxy();
if (socks5 == null) { /* SDK 未就绪 */ return; }
Proxy socksProxy = new Proxy(Proxy.Type.SOCKS,
        new InetSocketAddress(socks5.getIp(), socks5.getPort()));
HttpURLConnection conn = (HttpURLConnection) new URL(demoURL).openConnection(socksProxy);
```

### DNS 辅助方法

`AXService` 还提供了基于 SDK 受保护解析器的 DNS 能力：

```java
String[] v4 = AXService.getIPv4sForHost("your.server.domain");
String[] v6 = AXService.getIPv6sForHost("your.server.domain");

AXService.clearDNSCache(); // 需要时清除缓存
```

## 错误处理

当 SDK 未初始化或本地代理不可用时，`AXService.getLocalHTTPProxy()`（以及其他 `getLocal...Proxy` 方法）会返回 `null`。发起请求前务必检查返回值：

```java
AXLocalProxy localProxy = AXService.getLocalHTTPProxy();
if (localProxy == null) {
    // SDK 未就绪，检查初始化结果或稍后重试
    return;
}
```

代理通道上的网络错误会以标准 Java `IOException` 抛出，按常规方式处理即可：

```java
try {
    Proxy httpProxy = new Proxy(Proxy.Type.HTTP,
            new InetSocketAddress(localProxy.getIp(), localProxy.getPort()));
    HttpURLConnection conn = (HttpURLConnection) new URL(demoURL).openConnection(httpProxy);
    // ... 读写 ...
} catch (IOException e) {
    // 网络错误，按需检查连接状态并重试
}
```

## 验证接入是否成功

完成 SDK 集成后，运行应用并在 Logcat 中过滤 `AXService` 标签。接入成功时应观察到：

1. 初始化过程中无 `AXService` 相关错误日志；
2. `getLocalHTTPProxy()` 返回非空 `AXLocalProxy`，且包含回环 IP 和非零端口；
3. 通过该代理端点发起 HTTPS 请求成功，并从业务服务端收到预期响应。

如果出现异常，请参考以下常见问题排查：

| 现象 | 原因 | 解决方案 |
|------|------|---------|
| `initialize` 返回负数 | 凭证错误或 Edge 不可达 | 检查 `accessKeyId`、`accessKeySecret` 和 `edgeNodes` 是否正确 |
| `getLocalHTTPProxy()` 返回 `null` | SDK 未初始化或代理未就绪 | 确保 `initialize` 返回 `0` 后再调用 `getLocalHTTPProxy()` |
| Logcat 出现 `Local HTTP proxy not available` | 内部代理启动失败 | 检查网络权限和 Edge 连通性 |
