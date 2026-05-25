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
// import java.net.HttpURLConnection;
// import java.net.InetSocketAddress;
// import java.net.Proxy;
// import java.net.URL;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.net.Socket;
import java.net.UnknownHostException;
import java.nio.charset.StandardCharsets;

public class MainActivity extends AppCompatActivity {
    private TextView m_textView;
    private final String mRequestHost = "your.server.domain"; // your server domain
    private final int mRequestPort = 7000; // your server port

    // *** UNCOMMENT THE LINE BELOW FOR SDK ***
    // private final String mDemoURL = "https://your.server.domain/"; // target URL for HTTP/Socks5 proxy demo

    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // *** UNCOMMENT THE LINES BELOW FOR SDK ***
        // m_textView = findViewById(R.id.log);
        // m_textView.setText("Init " + (MyApplication.s_initResult ? "OK" : "FAILED"));

        Button proxyBtn = findViewById(R.id.proxy);
        proxyBtn.setOnClickListener((View view) -> {

            // *** UNCOMMENT THE LINES BELOW FOR SDK ***
            // new Thread(() -> {
            //     AXLocalProxy localProxy = AXService.getLocalTCPProxy(mRequestHost, mRequestPort);
            //     String result;
            //     if (localProxy != null) {
            //         result = "AXLocalProxy: " + localProxy.getIp() + ":" + localProxy.getPort();
            //     } else {
            //         result = "GetLocalTCPProxy failed (returned null)";
            //     }
            //     String finalResult = result;
            //     runOnUiThread(() -> m_textView.setText(finalResult + "\n"));
            // }).start();
        });

        Button requestBtn = findViewById(R.id.request);
        requestBtn.setOnClickListener((View view) -> {
            new Thread(() -> {
                String message;
                try {
                    // *** UNCOMMENT THE LINES BELOW FOR SDK ***
                    // AXLocalProxy localProxy = AXService.getLocalTCPProxy(mRequestHost, mRequestPort);
                    // if (localProxy == null) {
                    //     runOnUiThread(() -> m_textView.setText("GetLocalTCPProxy failed\n"));
                    //     return;
                    // }
                    // Socket socket = new Socket(localProxy.getIp(), localProxy.getPort());

                    // *** COMMENT THE LINE BELOW FOR SDK ***
                    Socket socket = new Socket(mRequestHost, mRequestPort);

                    PrintWriter out = new PrintWriter(
                            new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8), true);
                    BufferedReader in = new BufferedReader(
                            new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
                    out.println("ping");
                    message = in.readLine();
                } catch (UnknownHostException e) {
                    message = "Unknown host: " + mRequestHost;
                    e.printStackTrace();
                } catch (IOException e) {
                    message = "I/O error: " + e.getMessage();
                    e.printStackTrace();
                }
                String finalMessage = message;
                runOnUiThread(() -> m_textView.setText("Server: " + finalMessage + "\n"));
            }).start();
        });

        Button httpReqBtn = findViewById(R.id.http_request);
        httpReqBtn.setOnClickListener((View view) -> {
            // *** UNCOMMENT THE LINES BELOW FOR SDK ***
            // new Thread(() -> runProxyRequest(Proxy.Type.HTTP)).start();
        });

        Button socks5ReqBtn = findViewById(R.id.socks5_request);
        socks5ReqBtn.setOnClickListener((View view) -> {
            // *** UNCOMMENT THE LINES BELOW FOR SDK ***
            // new Thread(() -> runProxyRequest(Proxy.Type.SOCKS)).start();
        });
    }

    // *** UNCOMMENT THE METHOD BELOW FOR SDK ***
    // @SuppressLint("SetTextI18n")
    // private void runProxyRequest(Proxy.Type type) {
    //     String tag = (type == Proxy.Type.HTTP) ? "HTTP" : "SOCKS5";
    //     AXLocalProxy lp = (type == Proxy.Type.HTTP)
    //             ? AXService.getLocalHTTPProxy()
    //             : AXService.getLocalSocks5Proxy();
    //     if (lp == null) {
    //         runOnUiThread(() -> m_textView.setText(
    //                 "GetLocal" + tag + "Proxy failed (returned null)\n"));
    //         return;
    //     }
    //
    //     String result;
    //     HttpURLConnection conn = null;
    //     try {
    //         Proxy javaProxy = new Proxy(type,
    //                 new InetSocketAddress(lp.getIp(), lp.getPort()));
    //         conn = (HttpURLConnection) new URL(mDemoURL).openConnection(javaProxy);
    //         conn.setRequestMethod("GET");
    //         conn.setConnectTimeout(10_000);
    //         conn.setReadTimeout(10_000);
    //         int code = conn.getResponseCode();
    //         String contentType = conn.getContentType();
    //         java.io.InputStream bodyStream = (code >= 200 && code < 400)
    //                 ? conn.getInputStream()
    //                 : conn.getErrorStream();
    //         StringBuilder body = new StringBuilder();
    //         if (bodyStream != null) {
    //             final int maxChars = 2048;
    //             try (BufferedReader reader = new BufferedReader(
    //                     new InputStreamReader(bodyStream, StandardCharsets.UTF_8))) {
    //                 char[] buf = new char[512];
    //                 int total = 0;
    //                 int n;
    //                 while (total < maxChars && (n = reader.read(buf)) != -1) {
    //                     int take = Math.min(n, maxChars - total);
    //                     body.append(buf, 0, take);
    //                     total += take;
    //                 }
    //                 if (total >= maxChars && reader.read() != -1) {
    //                     body.append("\n... (truncated)");
    //                 }
    //             }
    //         }
    //         result = "HTTP " + code
    //                 + (contentType != null ? " [" + contentType + "]" : "")
    //                 + "\n" + (body.length() == 0 ? "<empty body>" : body.toString());
    //     } catch (UnknownHostException e) {
    //         result = "Unknown host: " + e.getMessage();
    //         e.printStackTrace();
    //     } catch (IOException e) {
    //         result = "I/O error: " + e.getMessage();
    //         e.printStackTrace();
    //     } finally {
    //         if (conn != null) {
    //             conn.disconnect();
    //         }
    //     }
    //
    //     String finalResult = result;
    //     runOnUiThread(() -> m_textView.setText(tag + " via " + lp.getIp() + ":"
    //             + lp.getPort() + " -> " + finalResult + "\n"));
    // }
}
