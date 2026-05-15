package com.axsecurity.sdk.service.demo;

import android.app.Application;

// *** UNCOMMENT THE LINE BELOW FOR AgentSDK ***
// import com.axsecurity.sdk.service.AXService;
// import com.axsecurity.sdk.base.Config;

public class MyApplication extends Application {
    // *** UNCOMMENT THE LINE BELOW FOR AgentSDK ***
    // public static boolean s_initResult = false;

    @Override
    public void onCreate() {
        super.onCreate();

        // *** UNCOMMENT THE LINE BELOW FOR AgentSDK ***
        // String accessKeyID = "your accessKeyID of SDK Deployment";
        // String accessKeySecret = "your accessKeySecret of SDK Deployment";
        // String[] edgeAddresses = new String[] { "your edge IP or domain" };
        //
        // Config config = new Config.Builder()
        //     .accessKeyID(accessKeyID)
        //     .accessKeySecret(accessKeySecret)
        //     .edgeAddresses(edgeAddresses)
        //     .dnsConfig(new Config.DnsConfig.DnsBuilder()
        //         .addEdgeDohResolveDomain("*.example.com")
        //         .build())
        //     .secureProxyEnabled(true)
        //     .build();
        //
        // s_initResult = (AXService.initialize(this.getApplicationContext(), config) == 0);
    }
}
