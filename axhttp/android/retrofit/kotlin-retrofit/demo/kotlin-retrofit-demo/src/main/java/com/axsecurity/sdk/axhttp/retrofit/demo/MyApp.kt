package com.axsecurity.sdk.axhttp.retrofit.demo

import android.app.Application
import com.axsecurity.sdk.base.AXConfig
import com.axsecurity.sdk.service.AXService

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // *** UNCOMMENT THE LINE BELOW FOR AXIS  STEP 1***
        // val accessKeyId = "your accessKeyId for SDK Deployment"
        // val accessKeySecret = "your accessKeySecret for SDK Deployment"
        // val edgeNodes = arrayOf("edge IP")

        // val config = AXConfig.Builder()
        //     .accessKey(accessKeyId, accessKeySecret)
        //     .edgeNodes(edgeNodes)
        //     .build()

        // if (AXService.initialize(applicationContext, config) == 0) {
        //     // TODO
        // } else {
        //     // TODO
        // }
    }
}
