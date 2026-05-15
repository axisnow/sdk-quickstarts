package com.axsecurity.sdk.axhttp.httpsurlconn.demo;

import android.app.Application;

// *** UNCOMMENT THE LINE BELOW STEP 1***
//import com.axsecurity.sdk.axhttp.httpsurlconn.AXHTTPService;
//import com.axsecurity.sdk.base.Config;

public class MyApplication extends Application {

    @Override
    public void onCreate() {
        super.onCreate();
        // *** UNCOMMENT THE LINE BELOW STEP 1***
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
        * */
    }
}
