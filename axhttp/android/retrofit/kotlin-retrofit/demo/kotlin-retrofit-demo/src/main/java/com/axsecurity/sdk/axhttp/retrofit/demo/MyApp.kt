package com.axsecurity.sdk.axhttp.retrofit.demo

import android.app.Application
import com.axsecurity.sdk.axhttp.retrofit.AXHTTPService
import com.axsecurity.sdk.base.Config

class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()

        // *** UNCOMMENT THE LINE BELOW FOR AXIS  STEP 1***
        // val accessKeyID = "your accessKeyID for SDK Deployment"
        // val accessKeySecret = "your accessKeySecret for SDK Deployment"
        // val edgeAddresses = arrayOf("edge IP")

        // val config = Config.Builder()
        //     .accessKeyID(accessKeyID)
        //     .accessKeySecret(accessKeySecret)
        //     .edgeAddresses(edgeAddresses)
        //     .build()

        // if (AXHTTPService.initialize(applicationContext, config) == 0) {
        //     // TODO
        // } else {
        //     // TODO
        // }
    }
}