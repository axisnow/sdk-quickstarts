package com.axsecurity.sdk.axhttp.retrofit.demo;

import android.app.Application;

import com.axsecurity.sdk.base.AXConfig;
import com.axsecurity.sdk.service.AXService;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        // *** COMMENT THE LINE BELOW FOR STEP 1***
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
        */
    }
}
