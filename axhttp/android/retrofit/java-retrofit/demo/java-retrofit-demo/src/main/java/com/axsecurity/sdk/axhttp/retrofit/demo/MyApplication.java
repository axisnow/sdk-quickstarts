package com.axsecurity.sdk.axhttp.retrofit.demo;

import android.app.Application;

import com.axsecurity.sdk.axhttp.retrofit.AXHTTPService;
import com.axsecurity.sdk.base.Config;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        // *** COMMENT THE LINE BELOW FOR STEP 1***
        /*
        String accessKeyID = "your accessKeyID from SDK Deployment";
        String accessKeySecret = "your accessKeySecret from SDK Deployment";
        String[] edgeAddresses = { "edge IP" };
        Config config = new Config.Builder()
            .accessKeyID(accessKeyID)
            .accessKeySecret(accessKeySecret)
            .edgeAddresses(edgeAddresses)
            .build();
        if (AXHTTPService.initialize(this.getApplicationContext(), config) == 0) {
            //TODO
        } else {
            //TODO
        }
        */
    }
}
