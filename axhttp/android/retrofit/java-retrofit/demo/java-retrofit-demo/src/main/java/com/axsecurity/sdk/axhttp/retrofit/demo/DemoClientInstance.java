package com.axsecurity.sdk.axhttp.retrofit.demo;

 // *** UNCOMMENT THE LINES BELOW FOR SDK ***
//import com.axsecurity.sdk.axhttp.retrofit.AXHTTPService;

import retrofit2.Retrofit;
import retrofit2.converter.gson.GsonConverterFactory;

public class DemoClientInstance {
    private static final String BASE_URL = "https://example.io";

  // *** COMMENT THE LINES BELOW FOR SDK ***
    private static Retrofit retrofit;
    public static Retrofit getRetrofitInstance() {
        if (retrofit == null) {
            retrofit = new retrofit2.Retrofit.Builder()
                    .baseUrl(BASE_URL)
                    .addConverterFactory(GsonConverterFactory.create())
                    .build();
        }
        return retrofit;
    }
    
     // *** UNCOMMENT THE LINES BELOW FOR SDK ***
    // private static Retrofit retrofit;
    // public static Retrofit getRetrofitInstance() {
    //     if (retrofit == null) {
    //         Retrofit.Builder builder = new retrofit2.Retrofit.Builder()
    //                 .baseUrl(BASE_URL)
    //                 .addConverterFactory(GsonConverterFactory.create());
    //         retrofit = AXHTTPService.getRetrofit(builder);
    //     }
    //     return retrofit;
    // }
}
