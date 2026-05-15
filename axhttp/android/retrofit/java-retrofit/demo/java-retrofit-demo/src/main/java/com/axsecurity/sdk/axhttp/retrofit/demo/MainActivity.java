package com.axsecurity.sdk.axhttp.retrofit.demo;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

// *** UNCOMMENT THE LINE BELOW FOR AXHTTPService ***
//import com.axsecurity.sdk.axhttp.retrofit.AXHTTPService;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

import okhttp3.OkHttpClient;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class MainActivity extends AppCompatActivity {
    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button btn = findViewById(R.id.run_test_button);
        btn.setOnClickListener((View view) -> {
            doRequestResByAxisOkHttpClient();
        });
    }

    void doRequestResByAxisOkHttpClient() {
        OkHttpClient.Builder OkHttpClientBuilder = new OkHttpClient.Builder();
        OkHttpClientBuilder.readTimeout(60, TimeUnit.SECONDS);
        OkHttpClientBuilder.writeTimeout(60, TimeUnit.SECONDS);

        // *** UNCOMMENT THE LINE BELOW STEP 2***
        // AXHTTPService.setOkHttpClientBuilder(OkHttpClientBuilder);

        // make a new Request
        DemoApiService service = DemoClientInstance.getRetrofitInstance().create(DemoApiService.class);
        Call<HelloModel> call = service.getHello();
        call.enqueue(new Callback<HelloModel>() {
            @SuppressLint("SetTextI18n")
            @Override
            public void onResponse(Call<HelloModel> call, Response<HelloModel> response) {
                runOnUiThread(()->{
                    TextView textView = findViewById(R.id.textView);
                    try {
                        textView.setText("\nResponse code = " + response.code() +
                                        "\nResponse result = " + response.body() );
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }
                });
            }

            @SuppressLint("SetTextI18n")
            @Override
            public void onFailure(Call<HelloModel> call, Throwable t) {
                runOnUiThread(()->{
                    TextView textView = findViewById(R.id.textView);
                    textView.setText("Response error = " + t.toString());
                });
            }
        });
    }
}