# AgentSDK 快速接入：iOS Swift URLSession

[English](./README.en.md) | 简体中文

本快速接入指南面向使用 Swift 编写、通过 `URLSession` 发起 API 请求的原生 iOS 应用，帮助你为这些请求接入 AgentSDK 的保护能力。如果你的场景与此不符，请查阅更贴近的接入指南。

本页列出了完整的接入步骤；同时我们在 swift-urlsession-demo 工程中提供了一份可运行的示例。

请注意，AgentSDK 的最低支持 iOS 版本为 12.0。若你的 App 需要支持更早的 iOS 版本，则无法使用 AgentSDK。

## 添加 AgentSDK AXURLSessionService 依赖

在目标 target 的 **Build Phases → Link Binary with Libraries** 中添加以下框架与库：

1. `AXSecurityURLSession.framework` — AgentSDK URLSession 包装框架
2. `AXSecurity.framework` — AgentSDK 核心 SDK
3. `libz.tbd` — 压缩库
4. `libc++.tbd` — C++ 标准库
5. `DeviceCheck.framework` — Apple DeviceCheck 框架
6. `CoreTelephony.framework` — Apple CoreTelephony 框架
7. `libresolv.tbd` — DNS 解析

## 初始化 AgentSDK AXURLSessionService

在使用 `AXURLSessionService` 前，需在 App 启动时完成初始化，通常放在 `@main` 类型的 `init` 或 `application:didFinishLaunchingWithOptions:` 中：

```swift
init() {
    let config = AXConfig()
    config.accessKeyId = "SDK 部署时获得的 accessKeyID"
    config.accessKeySecret = "SDK 部署时获得的 accessKeySecret"
    config.edgeAddresses = ["1**.**.**.**"] // IPv4 edge 节点地址
    let result = AXURLSessionService.initialize(with: config)
    if result == 0 {
        // TODO 初始化成功
    } else {
        // TODO 初始化失败
    }
}
```

`initialize(with:)` 返回 `0` 表示成功，返回负数错误码表示失败。

## 参数说明

| 参数 | 说明 |
|------|------|
| `AXConfig.accessKeyId` | AccessKey ID（必填），从控制台获取 |
| `AXConfig.accessKeySecret` | AccessKey Secret（必填），从控制台获取 |
| `AXConfig.edgeAddresses` | Edge 节点地址列表（必填），`[String]`，至少 1 个，推荐 2+ |

本 demo 仅使用上述最小必填字段。`AXConfig` 的完整选项（DNS 配置、加密隧道开关等）以及参数语义详见 AgentSDK 接入指南。

## 使用 AgentSDK AXURLSessionService

`AXURLSession` 是 Apple `URLSession` 的 drop-in 替换，在同一套 API 之上透明接管 HTTP/HTTPS 流量并经由 AgentSDK 本地代理转发。迁移时只需把工程里的 `URLSession` 替换为 `AXURLSession`：

```swift
let defaultSession = AXURLSession(configuration: .default)
```
