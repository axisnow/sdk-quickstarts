package com.axsecurity.sdk.axhttp.okhttp.demo

import android.app.Application
import com.axsecurity.sdk.base.AXConfig
import com.axsecurity.sdk.service.AXService

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // *** UNCOMMENT THE LINE BELOW FOR SDK ***
        // val accessKeyId = "<YOUR_ACCESS_KEY_ID>"
        // val accessKeySecret = "<YOUR_ACCESS_KEY_SECRET>"
        // val edgeNodes = arrayOf("<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>")
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
