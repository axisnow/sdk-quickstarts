//
//  MyApplication.java
//  AXSecurityWebView demo
//
//  The SDK integration is shipped commented out. To enable it: uncomment the
//  marked lines below and fill in your deployment credentials. The SDK must be
//  initialized here (once, at launch) before the proxy is installed on any
//  WebView.
//

package com.axsecurity.sdk.webview.demo;

import android.app.Application;

// *** UNCOMMENT THE IMPORTS BELOW FOR SDK ***
// import android.util.Log;
// import com.axsecurity.sdk.base.AXConfig;
// import com.axsecurity.sdk.service.AXService;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();

        // Initialize the core SDK before any WebView is created. The AccessKey and
        // Edge nodes below come from your SDK Deployment (console).
        // *** UNCOMMENT THE LINES BELOW FOR SDK ***
        // String accessKeyId = "your accessKeyId from SDK Deployment";
        // String accessKeySecret = "your accessKeySecret from SDK Deployment";
        // String[] edgeNodes = { "your edge IP or domain" };
        // AXConfig.DnsConfig dns = new AXConfig.DnsConfig.Builder()
        //         .edgeDohResolveDomains("*.example.com")
        //         .build();
        // AXConfig config = new AXConfig.Builder()
        //         .accessKey(accessKeyId, accessKeySecret)
        //         .edgeNodes(edgeNodes)
        //         .dns(dns)
        //         .proxy(new AXConfig.ProxyConfig.Builder().secureProxyEnabled(true).build())
        //         .build();
        // if (AXService.initialize(getApplicationContext(), config) != 0) {
        //     Log.e("AXWebViewDemo", "AXService.initialize failed");
        // }
    }
}
