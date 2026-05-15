package com.axsecurity.sdk.axhttp.okhttp.demo;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.axsecurity.sdk.axhttp.okhttp.AXHTTPService;

import java.io.IOException;
import java.util.concurrent.TimeUnit;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

public class MainActivity extends AppCompatActivity {

    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button btn = findViewById(R.id.run_test_button);
        btn.setOnClickListener((View view) -> {

            OkHttpClient.Builder OkHttpClientBuilder = new OkHttpClient.Builder();
            OkHttpClientBuilder.readTimeout(60, TimeUnit.SECONDS);
            OkHttpClientBuilder.writeTimeout(60, TimeUnit.SECONDS);

            // *** COMMENT THE LINE BELOW FOR AgentSDK ***
            OkHttpClient client = OkHttpClientBuilder.build();

            // *** UNCOMMENT THE LINE BELOW FOR AgentSDK ***
            // AXHTTPService.setOkHttpClientBuilder(OkHttpClientBuilder);
            // OkHttpClient client = AXHTTPService.getOkHttpClient();

            // make a new Request
            Request request = new Request.Builder()
                    .url("https://example.com")
                    .build();

             client.newCall(request).enqueue(new Callback() {
                 @Override
                 public void onResponse(@NonNull Call call, @NonNull Response response) throws IOException {

                     runOnUiThread(()->{
                         TextView textView = findViewById(R.id.textView);
                         textView.setText("Response code = " + response.code());
                     });
                 }
                 @Override
                 public void onFailure(@NonNull Call call, @NonNull IOException e) {
                     runOnUiThread(()->{
                         TextView textView = findViewById(R.id.textView);
                         textView.setText("Response error = " + e.toString());
                     });
                 }
             });
        });
    }

}