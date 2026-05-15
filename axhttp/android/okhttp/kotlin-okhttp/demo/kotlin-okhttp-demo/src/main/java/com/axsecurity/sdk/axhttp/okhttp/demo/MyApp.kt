package com.axsecurity.sdk.axhttp.okhttp.demo

import android.app.Application
import com.axsecurity.sdk.axhttp.okhttp.AXHTTPService
import com.axsecurity.sdk.base.Config

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // *** UNCOMMENT THE LINE BELOW FOR AgentSDK ***
        // val accessKeyID = "your accessKeyID from SDK Deployment"
        // val accessKeySecret = "your accessKeySecret from SDK Deployment"
        // val edgeAddresses = arrayOf("edge IP")
        // val routingDomain = "routing Domain"
        // val config = Config.Builder()
        //     .accessKeyID(accessKeyID)
        //     .accessKeySecret(accessKeySecret)
        //     .edgeAddresses(edgeAddresses)
        //     .routingDomain(routingDomain)
        //     .build()
        // if (AXHTTPService.initialize(applicationContext, config) == 0) {
        //     // TODO
        // } else {
        //     // TODO
        // }
    }
}