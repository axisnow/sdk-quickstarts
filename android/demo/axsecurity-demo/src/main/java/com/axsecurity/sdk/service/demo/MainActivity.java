package com.axsecurity.sdk.service.demo;

import androidx.appcompat.app.AppCompatActivity;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

// *** UNCOMMENT THE LINES BELOW FOR SDK ***
// import com.axsecurity.sdk.service.AXService;
// import com.axsecurity.sdk.service.AXLocalProxy;
// import java.net.InetSocketAddress;
// import java.net.Proxy;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.UnknownHostException;
import java.nio.charset.StandardCharsets;

public class MainActivity extends AppCompatActivity {
    private TextView m_textView;
    private final String mDemoURL = "https://your.server.domain/"; // target URL for HTTP proxy demo

    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        m_textView = findViewById(R.id.log);

        // *** UNCOMMENT THE LINE BELOW FOR SDK ***
        // m_textView.setText("Init " + (MyApplication.s_initResult ? "OK" : "FAILED"));

        Button httpReqBtn = findViewById(R.id.http_request);
        httpReqBtn.setOnClickListener((View view) ->
                new Thread(this::runHttpRequest).start());
    }

    @SuppressLint("SetTextI18n")
    private void runHttpRequest() {
        String result;
        HttpURLConnection conn = null;
        try {
            // *** COMMENT THE LINE BELOW FOR SDK ***
            conn = (HttpURLConnection) new URL(mDemoURL).openConnection();

            // *** UNCOMMENT THE LINES BELOW FOR SDK ***
            // AXLocalProxy lp = AXService.getLocalHTTPProxy();
            // if (lp == null) {
            //     runOnUiThread(() -> m_textView.setText(
            //             "GetLocalHTTPProxy failed (returned null)\n"));
            //     return;
            // }
            // Proxy javaProxy = new Proxy(Proxy.Type.HTTP,
            //         new InetSocketAddress(lp.getIp(), lp.getPort()));
            // conn = (HttpURLConnection) new URL(mDemoURL).openConnection(javaProxy);

            conn.setRequestMethod("GET");
            conn.setConnectTimeout(10_000);
            conn.setReadTimeout(10_000);
            int code = conn.getResponseCode();
            String contentType = conn.getContentType();
            java.io.InputStream bodyStream = (code >= 200 && code < 400)
                    ? conn.getInputStream()
                    : conn.getErrorStream();
            StringBuilder body = new StringBuilder();
            if (bodyStream != null) {
                final int maxChars = 2048;
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(bodyStream, StandardCharsets.UTF_8))) {
                    char[] buf = new char[512];
                    int total = 0;
                    int n;
                    while (total < maxChars && (n = reader.read(buf)) != -1) {
                        int take = Math.min(n, maxChars - total);
                        body.append(buf, 0, take);
                        total += take;
                    }
                    if (total >= maxChars && reader.read() != -1) {
                        body.append("\n... (truncated)");
                    }
                }
            }
            result = "HTTP " + code
                    + (contentType != null ? " [" + contentType + "]" : "")
                    + "\n" + (body.length() == 0 ? "<empty body>" : body.toString());
        } catch (UnknownHostException e) {
            result = "Unknown host: " + e.getMessage();
            e.printStackTrace();
        } catch (IOException e) {
            result = "I/O error: " + e.getMessage();
            e.printStackTrace();
        } finally {
            if (conn != null) {
                conn.disconnect();
            }
        }

        String finalResult = result;
        runOnUiThread(() -> m_textView.setText(finalResult + "\n"));
    }
}
