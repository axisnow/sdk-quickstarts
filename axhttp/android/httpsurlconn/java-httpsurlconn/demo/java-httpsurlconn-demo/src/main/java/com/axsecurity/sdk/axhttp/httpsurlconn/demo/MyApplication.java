package com.axsecurity.sdk.axhttp.httpsurlconn.demo;

import android.app.Application;

// *** UNCOMMENT THE LINE BELOW STEP 1***
//import com.axsecurity.sdk.base.AXConfig;
//import com.axsecurity.sdk.service.AXService;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        // *** UNCOMMENT THE LINE BELOW STEP 1***
        /*
        String accessKeyId = "your accessKeyId from SDK Deployment";
        String accessKeySecret = "your accessKeySecret from SDK Deployment";
        String[] edgeNodes = { "edge IP" };
        AXConfig config = new AXConfig.Builder()
            .accessKey(accessKeyId, accessKeySecret)
            .edgeNodes(edgeNodes)
            .build();
        if (AXService.initialize(this.getApplicationContext(), config) == 0) {
            //TODO
        } else {
            //TODO
        }
        * */
    }
}
