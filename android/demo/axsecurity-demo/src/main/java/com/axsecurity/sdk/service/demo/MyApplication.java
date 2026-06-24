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
        // String accessKeyId = "<YOUR_ACCESS_KEY_ID>";
        // String accessKeySecret = "<YOUR_ACCESS_KEY_SECRET>";
        // String[] edgeNodes = new String[] { "<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>" };
        //
        // AXConfig config = new AXConfig.Builder()
        //     .accessKey(accessKeyId, accessKeySecret)
        //     .edgeNodes(edgeNodes)
        //     .dns(new AXConfig.DnsConfig.Builder()
        //         .edgeDohResolveDomains("<YOUR_DOMAIN>")
        //         .build())
        //     .proxy(new AXConfig.ProxyConfig.Builder()
        //         .secureProxyEnabled(true)
        //         .build())
        //     .build();
        //
        // s_initResult = (AXService.initialize(this.getApplicationContext(), config) == 0);
    }
}
