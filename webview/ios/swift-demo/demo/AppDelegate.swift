//
//  AppDelegate.swift
//  AXSecurityWebView swift demo
//
//  The SDK integration is shipped commented out. To enable it: uncomment the
//  marked lines below and fill in your deployment credentials. The SDK must be
//  initialized here (once, at launch) before the proxy is installed on any
//  WebView.
//

import UIKit

// *** UNCOMMENT THE LINE BELOW FOR SDK ***
// import AXSecurity

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // *** UNCOMMENT THE LINES BELOW FOR SDK ***
        // let config = AXConfig()
        // config.accessKeyID = "your accessKeyID of SDK Deployment"
        // config.accessKeySecret = "your accessKeySecret of SDK Deployment"
        // config.edgeNodes = ["your edge IP or domain"]
        //
        // let r = AXService.initialize(config)
        // if r != 0 {
        //     NSLog("[demo] AXService initialize failed: \(r)")
        // }

        return true
    }

    func application(_: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
