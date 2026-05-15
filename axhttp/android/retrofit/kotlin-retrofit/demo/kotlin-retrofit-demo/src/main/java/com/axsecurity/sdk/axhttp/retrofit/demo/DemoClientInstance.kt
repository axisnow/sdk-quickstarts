package com.axsecurity.sdk.axhttp.retrofit.demo
import com.axsecurity.sdk.axhttp.retrofit.AXHTTPService
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory


object DemoClientInstance {
    private const val BASE_URL = "https://example.io"

    private var retrofit: Retrofit? = null
    @JvmStatic
    val retrofitInstance: Retrofit?
        get() {
            if (retrofit == null) {
                retrofit = Retrofit.Builder()
                    .baseUrl(BASE_URL)
                    .addConverterFactory(GsonConverterFactory.create())
                    .build()
            }
            return retrofit
        }

    // *** UNCOMMENT THE LINES BELOW FOR AXIS ***
//    private var retrofit: Retrofit? = null
//    @JvmStatic
//    val retrofitInstance: Retrofit?
//        get() {
//            if (retrofit == null) {
//                val builder = Retrofit.Builder()
//                        .baseUrl(BASE_URL)
//                        .addConverterFactory(GsonConverterFactory.create())
//                retrofit = AXHTTPService.getRetrofit(builder)
//            }
//            return retrofit
//        }
}