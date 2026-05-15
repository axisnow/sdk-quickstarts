package com.axsecurity.sdk.axhttp.retrofit.demo;
import java.util.Map;

import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.HeaderMap;

public interface DemoApiService {
    @GET("/v1/hello")
    Call<HelloModel> getHello();
}
