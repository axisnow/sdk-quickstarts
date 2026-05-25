package com.axsecurity.sdk.axhttp.okhttp.demo

import android.app.Application
import com.axsecurity.sdk.base.AXConfig
import com.axsecurity.sdk.service.AXService

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // *** UNCOMMENT THE LINE BELOW FOR SDK ***
        // val accessKeyId = "your accessKeyId from SDK Deployment"
        // val accessKeySecret = "your accessKeySecret from SDK Deployment"
        // val edgeNodes = arrayOf("edge IP")
        // val routingDomain = "routing Domain"
        // val config = AXConfig.Builder()
        //     .accessKey(accessKeyId, accessKeySecret)
        //     .edgeNodes(edgeNodes)
        //     .routingDomain(routingDomain)
        //     .build()
        // if (AXService.initialize(applicationContext, config) == 0) {
        //     // TODO
        // } else {
        //     // TODO
        // }
    }
}
