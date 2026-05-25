package com.axsecurity.sdk.service.demo;

import android.app.Application;

// *** UNCOMMENT THE LINE BELOW FOR SDK ***
// import com.axsecurity.sdk.service.AXService;
// import com.axsecurity.sdk.base.AXConfig;

public class MyApplication extends Application {
    // *** UNCOMMENT THE LINE BELOW FOR SDK ***
    // public static boolean s_initResult = false;

    @Override
    public void onCreate() {
        super.onCreate();

        // *** UNCOMMENT THE LINE BELOW FOR SDK ***
        // String accessKeyId = "your accessKeyId of SDK Deployment";
        // String accessKeySecret = "your accessKeySecret of SDK Deployment";
        // String[] edgeNodes = new String[] { "your edge IP or domain" };
        //
        // AXConfig config = new AXConfig.Builder()
        //     .accessKey(accessKeyId, accessKeySecret)
        //     .edgeNodes(edgeNodes)
        //     .dns(new AXConfig.DnsConfig.Builder()
        //         .addEdgeDohResolveDomain("*.example.com")
        //         .build())
        //     .secureProxyEnabled(true)
        //     .build();
        //
        // s_initResult = (AXService.initialize(this.getApplicationContext(), config) == 0);
    }
}
