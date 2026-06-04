# SDK Quickstart：Android WebView

[English](./README.en.md) | 简体中文

本快速接入文档面向使用 Android `WebView` 加载网页的原生应用，帮助你让 WebView 的流量经由 AXSecurity SDK 的本地代理转发，从而获得调度、加速、EdgeDoH 防劫持解析与 SecureProxy 隧道加密能力。如果你的场景不符，请查看其他更适合的快速接入文档。

封装对外只有一个入口 `AXWebViewService.installOnWebView(webView, base)`：它**包装**你已有的 `WebViewClient`（回调照常转发）、把包装后的 client 直接挂到 WebView 上，并启用 SDK 的**进程级全局代理**——WebView 的全部流量（主文档导航 + 子资源 + JS `fetch`/`XHR`）经 SDK 本地 **HTTP** 代理（HTTP CONNECT，覆盖 HTTP / HTTPS / WebSocket）转发。

本页提供了完整的接入步骤；同时我们在 [webview-demo](webview-demo/) 工程中提供了一份可运行的最小示例。

> **无需单独初始化封装**：核心 SDK 已由 `AXService.initialize(...)` 启动，本封装按需读取其本地代理——与 `AXHTTPService.getOkHttpClient()` 同样的无 init 模型。

## 添加 SDK 服务依赖

发布包 `axsecurity-android-webview-<version>.zip` 内含两个 AAR：核心 SDK `axsecurity-android-sdk.aar` 与 WebView 封装 `axsecurity-android-webview.aar`（后者是不含 `.so` 的薄封装）。把这**两个** AAR 都放入你的 App 模块的 `libs/`：

```
app/
└── libs/
    ├── axsecurity-android-sdk.aar       # 核心 SDK
    └── axsecurity-android-webview.aar   # WebView 封装
```

并在 App 模块的 `build.gradle` 中引用它们：

```groovy
dependencies {
    implementation fileTree(dir: 'libs', include: ['*.aar'])
}
```

> 这两个 AAR 以本地文件引入，**不携带传递依赖**，因此 `androidx.webkit` 需在宿主工程显式添加，详见下一节。

## 依赖与清单文件

封装使用 `androidx.webkit` 为 WebView 做进程级代理覆写。由于上一节的 AAR 以本地文件引入、**不携带传递依赖**，需在 App 模块 `build.gradle` 中显式添加该依赖（最低 1.4.0，可使用更高的 1.x 版本），否则运行期会因缺少 `ProxyController` 抛 `NoClassDefFoundError`：

```groovy
implementation 'androidx.webkit:webkit:1.4.0'
```

`android.permission.INTERNET` 权限声明在封装 AAR 自带的清单中，会自动合并到宿主 App 清单，**宿主无需修改 `AndroidManifest.xml`**。

注意：SDK 支持的最低 Android SDK 版本为 21（Android 5.0）。

## 初始化 AXService

使用封装前，必须在应用创建时完成核心 SDK 的初始化，通常放在 `Application.onCreate` 中，且要早于任何 WebView 的创建：

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

> **重要提示：** `initialize` 必须在调用任何其他 `AXService` 方法（含为 WebView 安装代理）之前**仅调用一次**，不支持多次调用。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AXConfig.Builder().accessKey(...)` | AccessKey ID 与 Secret（必填），从控制台获取 |
| `AXConfig.Builder().edgeNodes(...)` | 指向 AxisNow Edge DoH 服务的 EIP 或域名（必填），传入 `String[]`，至少 1 个，推荐 2+ |
| `AXConfig.Builder().dns(...)` | DNS 配置（可选），通过 `AXConfig.DnsConfig.Builder` 构造。通过 `edgeDohResolveDomains(String...)` 加入 EdgeDoH 白名单；通过 `edgeDohBypassDomains(String...)` 为白名单中的域名豁免（bypass 优先于 resolve）。匹配规则为精确域名或 `*.suffix` 通配。**未配置白名单时所有域名走系统 DNS**，需要 EdgeDoH 防护的域名请显式加入。 |

完整参数语义、约束与默认行为见接入指南附录 A。

## 为 WebView 安装代理

一个 `WebView` 只能设置一个 `WebViewClient`，所以**包装**你已有的 client，而不是替换。`installOnWebView` 会替你把（包装后的）client 挂到 WebView 上，你不用再自己调 `setWebViewClient`：

```java
import com.axsecurity.sdk.webview.AXWebViewService;

int rc = AXWebViewService.installOnWebView(webView, myWebViewClient);
// 没有自己的 client 时，第二个参数传 null 即可

// 发起首次导航：用 load(...) 而非直接 webView.loadUrl(...)，见下方「首次加载时序」
AXWebViewService.load(webView, url);
```

- **成功（返回 `0`）**：已启用 SDK 全局代理，WebView 走 SDK 数据路径。
- **失败（返回负数错误码）**：WebView 直连，本调用**已自动把你的 client（`base`，为 null 时用一个普通 `WebViewClient`）挂上**兜底，失败原因记录在 logcat（tag `AXSDK`）。具体错误码见下方「错误处理」。

安装成功后，该 WebView 的全部流量——主文档导航与页面内的所有子资源——都会经由 SDK 本地代理转发。

> ⚠️ **首次加载时序**：`installOnWebView` 返回 `0`（成功）只表示代理设置**已发起**——底层 `ProxyController.setProxyOverride(...)` 是**异步**的，代理在其 completion 回调后才真正生效。若紧接着直接 `webView.loadUrl(...)`，**首次导航**有概率在代理生效前发出、走直连绕过 SDK（冷启动 / WebView 首次初始化时最易命中）。请用 `AXWebViewService.load(webView, url)` 发起加载：它会在代理生效后才真正 `loadUrl`，关闭这个窗口。代理不可用时 `load` 按直连立即加载、页面照常打开；极端机型上代理回调迟迟不来时，`load` 也会在短超时后降级直连（打 `AXSDK` error 日志），保证页面不会一直空白。回调在 WebView 的 UI 线程执行。竞态只存在于首次加载，后续导航无此问题。

> ⚠️ **不要在 `installOnWebView` 之后再自己 `setWebViewClient(...)`**：本封装已接管 client 的设置，再设会把 SDK 的 client 覆盖掉。

> **可重复调用**：若在 SDK 初始化之前就构造了 WebView，可在 `AXService.initialize(...)` 成功后再调一次 `installOnWebView`，把该 WebView 升级到走 SDK。

> **副作用**：成功时本调用会启用**进程级全局代理**（影响 App 内所有 WebView），且在调用时即生效。与 `getOkHttpClient()` 把代理配在返回对象上不同。

可直接运行的示例参见 [`webview-demo/src/main/java/com/axsecurity/sdk/webview/demo/DemoWebView.java`](webview-demo/src/main/java/com/axsecurity/sdk/webview/demo/DemoWebView.java)（在自定义 WebView 的 `init()` 中调用 `installOnWebView`）与 [`MyApplication.java`](webview-demo/src/main/java/com/axsecurity/sdk/webview/demo/MyApplication.java)（初始化 SDK）。

## 错误处理

`installOnWebView` 不抛异常（与 SDK 其它接口一致）：返回 `0` 表示成功，返回**负数错误码**表示代理未启用，此时已自动把 `base`（或普通 client）挂上兜底直连，失败原因记录在 logcat（tag `AXSDK`）。返回码与 SDK 统一错误码表一致：

| 返回码 | 含义 | 处理 |
|------|------|------|
| `0` | 成功，已走 SDK 代理 | — |
| `-2` | 参数非法（`webView` 为 null） | 传入有效的 WebView |
| `-101` | SDK 未初始化 / 本地代理不可用 | 确认 `AXService.initialize(...)` 返回 `0` 后再调一次（可重复调用） |
| `-401` | 设备 WebView 不支持 `PROXY_OVERRIDE` | 升级系统 WebView 组件；无法升级的设备降级直连 |

## 验证接入是否成功

客户端不打印面向 App 的调试日志，以**控制台请求日志**为准：触发 WebView 加载后，在控制台按 AccessKey / 时间过滤，确认请求经 SDK 数据路径、DNS 与隧道状态符合预期。详见接入指南 §4.4。

## 已知限制

- **依赖 WebView 版本而非系统版本**：`PROXY_OVERRIDE` 跟随可独立升级的 WebView 组件，而非系统 API level。极少数无法更新 WebView 的设备（无 GMS / 被冻结）会降级直连。
- **进程级全局**：启用后影响 App 内所有 WebView，无法只对单个实例生效。
- **混合框架**：Cordova / Capacitor / React Native / Flutter 的 `WebViewClient` 由框架持有、用不了 `installOnWebView`，一期暂不支持。
- **请求签名 / 改写头部**：一期不提供。代理在 HTTPS 下是 CONNECT 隧道，改不了请求头；该能力规划在后续版本，且完全是封装库内部的增量改动——接入代码（仍是 `installOnWebView`）无需改动，能力配置统一走 `AXService.initialize(...)`。
