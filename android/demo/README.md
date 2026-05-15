# AgentSDK Quickstart：Android Java

[English](./README.en.md) | 简体中文

本快速接入文档面向使用 Java 开发、并通过 TCP / Socket 层发起需要 AgentSDK 保护的 API 调用的原生 Android 应用。如果你的场景不符，请查看其他更适合的快速接入文档。

本页提供了将 AgentSDK 集成到你的应用中的全部步骤。此外，我们还提供了基于 [axsecurity-demo](axsecurity-demo/) 的分步教程示例。

## 添加 AgentSDK 服务依赖

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

注意：AgentSDK 支持的最低 Android SDK 版本为 21（Android 5.0）。

## 初始化 AXService

使用 `AXService` 前，必须在应用创建时完成初始化，通常放在 `onCreate` 方法中：

```java
import android.app.Application;
import android.util.Log;

import com.axsecurity.sdk.service.AXService;
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
            .dnsConfig(new Config.DnsConfig.DnsBuilder()
                .addEdgeDohResolveDomain("*.example.com")
                .build())
            .secureProxyEnabled(true)
            .build();

        int result = AXService.initialize(this.getApplicationContext(), config);
        if (result != 0) {
            Log.e("MyApp", "AgentSDK initialization failed: " + result);
        }
    }
}
```

`initialize` 方法成功时返回 `0`，失败时返回负数错误码。

> **重要提示：** `initialize` 必须在调用任何其他 `AXService` 方法之前**仅调用一次**，不支持多次调用。

## 参数说明

| 参数 | 说明 |
|------|------|
| `Config.Builder().accessKeyID(...)` | AccessKey ID（必填），从控制台获取 |
| `Config.Builder().accessKeySecret(...)` | AccessKey Secret（必填），从控制台获取 |
| `Config.Builder().edgeAddresses(...)` | Edge 节点地址列表（必填），传入 `String[]`，至少 1 个，推荐 2+ |
| `Config.Builder().dnsConfig(...)` | DNS 配置（可选），通过 `Config.DnsConfig.DnsBuilder` 构造。通过 `addEdgeDohResolveDomain(String)`（或批量 `edgeDohResolveDomains(String[])`）加入 EdgeDoH 白名单；通过 `addEdgeDohBypassDomain(String)` 为白名单中的域名豁免（bypass 优先于 resolve）。匹配规则为精确域名或 `*.suffix` 通配。**未配置白名单时所有域名走系统 DNS**，需要 EdgeDoH 防护的域名请显式加入。 |
| `Config.Builder().secureProxyEnabled(...)` | 加密隧道开关（可选），默认启用；显式传 `false` 关闭 |

完整参数语义、约束与默认行为见接入指南附录 A。

## 使用 AXService

`AXService` 提供 `getLocalTCPProxy` API，可针对指定的目标 host 和 port 获取本地代理端点。使用返回的 IP/端口通过标准 `Socket` API 建连后，SDK 会将流量透明地转发至受保护通道。

```java
String requestHost = "your.server.domain";
int requestPort = 7000;

LocalProxy localProxy = AXService.getLocalTCPProxy(requestHost, requestPort);
if (localProxy == null) {
    // SDK 未就绪，检查初始化结果或稍后重试
    return;
}

Socket socket = new Socket(localProxy.getServerIp(), localProxy.getServerPort());
// 通过 socket 读写数据
```

### 其他代理端点

除按 host 粒度的 TCP 代理外，`AXService` 还暴露了本地 HTTP 代理和本地 SOCKS5 代理。只要是支持 `java.net.Proxy` 的 Java HTTP 客户端都可以通过它们把流量接入 SDK。

```java
String demoURL = "https://your.server.domain/";

// HTTP 代理 —— 使用 Proxy.Type.HTTP
LocalProxy http = AXService.getLocalHTTPProxy();
if (http == null) { /* SDK 未就绪 */ return; }
Proxy httpProxy = new Proxy(Proxy.Type.HTTP,
        new InetSocketAddress(http.getServerIp(), http.getServerPort()));
HttpURLConnection c1 = (HttpURLConnection) new URL(demoURL).openConnection(httpProxy);

// SOCKS5 代理 —— 使用 Proxy.Type.SOCKS，HttpURLConnection 在该类型下即走 SOCKS5
LocalProxy socks5 = AXService.getLocalSocks5Proxy();
if (socks5 == null) { /* SDK 未就绪 */ return; }
Proxy socksProxy = new Proxy(Proxy.Type.SOCKS,
        new InetSocketAddress(socks5.getServerIp(), socks5.getServerPort()));
HttpURLConnection c2 = (HttpURLConnection) new URL(demoURL).openConnection(socksProxy);
```

可直接运行的按钮示例参见 [`axsecurity-demo/MainActivity.java`](axsecurity-demo/src/main/java/com/axsecurity/sdk/service/demo/MainActivity.java)。完成 SDK 初始化后，按文件内 `*** UNCOMMENT ... FOR AgentSDK ***` 提示取消注释即可启用 HTTPRequest / Socks5Request 两个按钮。

### DNS 辅助方法

`AXService` 还提供了基于 SDK 受保护解析器的 DNS 能力：

```java
String[] v4 = AXService.getIPv4sForHost("your.server.domain");
String[] v6 = AXService.getIPv6sForHost("your.server.domain");

AXService.clearDNSCache(); // 需要时清除缓存
```

## 错误处理

当 SDK 未初始化或本地代理不可用时，`AXService.getLocalTCPProxy()`（以及其他 `getLocal...Proxy` 方法）会返回 `null`。开启 socket 前务必检查返回值：

```java
LocalProxy localProxy = AXService.getLocalTCPProxy(requestHost, requestPort);
if (localProxy == null) {
    // SDK 未就绪，检查初始化结果或稍后重试
    return;
}
```

socket 上的网络错误会以标准 Java `IOException` 抛出，按常规方式处理即可：

```java
try {
    Socket socket = new Socket(localProxy.getServerIp(), localProxy.getServerPort());
    // ... 读写 ...
} catch (IOException e) {
    // 网络错误，按需检查连接状态并重试
}
```

## 验证接入是否成功

完成 SDK 集成后，运行应用并在 Logcat 中过滤 `AXService` 标签。接入成功时应观察到：

1. 初始化过程中无 `AXService` 相关错误日志；
2. `getLocalTCPProxy()` 返回非空 `LocalProxy`，且包含回环 IP 和非零端口；
3. 与该代理端点建立 socket 连接成功，并从业务服务端收到预期响应。

如果出现异常，请参考以下常见问题排查：

| 现象 | 原因 | 解决方案 |
|------|------|---------|
| `initialize` 返回负数 | 凭证错误或 Edge 不可达 | 检查 `accessKeyID`、`accessKeySecret` 和 `edgeAddresses` 是否正确 |
| `getLocalTCPProxy()` 返回 `null` | SDK 未初始化或代理未就绪 | 确保 `initialize` 返回 `0` 后再调用 `getLocalTCPProxy()` |
| Logcat 出现 `Local TCP proxy not available` | 内部代理启动失败 | 检查网络权限和 Edge 连通性 |
