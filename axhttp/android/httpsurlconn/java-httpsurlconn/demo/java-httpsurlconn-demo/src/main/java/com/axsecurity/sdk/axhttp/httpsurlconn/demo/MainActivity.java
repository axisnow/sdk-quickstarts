package com.axsecurity.sdk.axhttp.httpsurlconn.demo;
import androidx.appcompat.app.AppCompatActivity;

import android.annotation.SuppressLint;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import com.axsecurity.sdk.axhttp.httpsurlconn.AXHTTPService;

import java.io.BufferedInputStream;
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;

import javax.net.ssl.HttpsURLConnection;


public class MainActivity extends AppCompatActivity {
    private static String TAG = "MainActivity";

    private static final String URL = "https://example.io";
    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button btn = findViewById(R.id.run_test_button);

        btn.setOnClickListener((View view) -> {
            doRequest();
        });
    }

    private String readResponse(HttpsURLConnection connection) {
        String result = null;
        StringBuilder sb = new StringBuilder();
        InputStream is = null;
        try {
            is = new BufferedInputStream(connection.getInputStream());
            BufferedReader br = new BufferedReader(new InputStreamReader(is));
            String inputLine;
            while ((inputLine = br.readLine()) != null) {
                sb.append(inputLine);
            }
            result = sb.toString();
        } catch (Exception e) {
            Log.d(TAG, "Error Exception Read InputStream");
        } finally {
            if (is != null) {
                try {
                    is.close();
                } catch (IOException e) {
                    Log.d(TAG, "Error closing response InputStream");
                }
            }
        }
        return result;
    }


    void doRequest() {
        AsyncTask.execute(new Runnable() {
            @SuppressLint("SetTextI18n")
            @Override
            public void run() {
                try {
                    URL url = new URL(URL);

                    // *** COMMENT THE LINE BELOW FOR AgentSDK ***
                    HttpsURLConnection connection = (HttpsURLConnection) url.openConnection();

                    // *** UNCOMMENT THE LINE BELOW FOR AgentSDK ***
                    // HttpsURLConnection connection = AXHTTPService.getHttpsURLConnection(url);

                    connection.setRequestMethod("GET");
                    connection.connect();
                    int code = connection.getResponseCode();
                    if (code == 200) {
                        String msg = readResponse(connection);

                        runOnUiThread(()->{
                            TextView textView = findViewById(R.id.textView);
                            textView.setText("Response msg = " + msg);
                        });
                    }
                } catch (IOException e) {
                    Log.e(TAG, "Request failed", e);
                    runOnUiThread(()->{
                        TextView textView = findViewById(R.id.textView);
                        textView.setText("Request error = " + e.toString());
                    });
                }
            }
        });
    }
}
