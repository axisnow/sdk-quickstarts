package com.axsecurity.sdk.axhttp.retrofit.demo
import retrofit2.Call
import retrofit2.http.GET
import retrofit2.http.HeaderMap

interface DemoApiService {
    @get:GET("/v1/hello")
    val hello: Call<HelloModel>
}