# SDK Quickstart: iOS Swift URLSession

English | [简体中文](./README.md)

This quickstart is written specifically for native iOS apps that are written in Swift and making the API calls using URLSession that you wish to protect with SDK. If this is not your situation then check if there is a more relevant quickstart guide available.

This page provides all the steps for integrating SDK into your app. Additionally, a step-by-step tutorial guide using our SDK swift-urlsession-demo is also available.
Note that the minimum requirement is iOS 12. You cannot use SDK in apps that support iOS versions older than this.

## ADDING SDK DEPENDENCY

Add the following frameworks/libraries to the ”Link Binary with Libraries" section of your project's “Build Phases”.
1.  `AXSecurityURLSession.xcframework` SDK URLSession Framework
2.  `AXSecurity.xcframework` SDK Core SDK
3.  `libz.tbd` compression library
4.  `libc++.tbd` C++ standard library
5.  `DeviceCheck.framework` Apple's DeviceCheck framework
6.  `CoreTelephony.framework` Apple's CoreTelephony framework
7.  `libresolv.tbd` DNS resolution

## INITIALIZING SDK

In order to use SDK you must initialize it when your app is created, usually in the `init` method:
``` swift
 init() {
    let config = AXConfig()
    config.accessKeyID = "<YOUR_ACCESS_KEY_ID>"
    config.accessKeySecret = "<YOUR_ACCESS_KEY_SECRET>"
    config.edgeNodes = ["<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>"]
    let result = AXService.initialize(config)
    if (result == 0) {
        //TODO SUCCESS
    } else {
        //TODO FAIL
    }
}
```

## Parameter Reference

| Parameter | Description |
|-----------|-------------|
| `AXConfig.accessKeyID` | AccessKey ID (required), obtained from the console |
| `AXConfig.accessKeySecret` | AccessKey Secret (required), obtained from the console |
| `AXConfig.edgeNodes` | EIP(s) or domain(s) pointing to the AxisNow Edge DoH service (required); `[String]`; at least 1, 2+ recommended |

This demo uses the minimum required fields. The full `AXConfig` option set (DNS configuration, encrypted tunnel toggle, etc.) and parameter semantics are documented in the SDK integration guide.

## USING AXURLSession

`AXURLSession`is a drop-in replacement for Apple's URLSession that provides enhanced NSURLSession protection. To migrate, simply replace all instances of URLSession with AXURLSession in your codebase.

```swift

let  defaultSession = AXURLSession(configuration: .default)

```