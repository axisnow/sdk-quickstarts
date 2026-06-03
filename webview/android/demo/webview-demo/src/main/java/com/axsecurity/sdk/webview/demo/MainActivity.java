package com.axsecurity.sdk.webview.demo;

import androidx.appcompat.app.AppCompatActivity;

import android.annotation.SuppressLint;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.WebView;
import android.widget.Button;
import android.widget.EditText;

import com.axsecurity.sdk.webview.AXWebViewService;

public class MainActivity extends AppCompatActivity {

    // Default URL loaded into the address bar — change to your test URL.
    private static final String DEFAULT_URL = "https://example.com/";

    private WebView mWebView;
    private EditText mUrl;

    @SuppressLint("SetTextI18n")
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mWebView = findViewById(R.id.webview);

        mUrl = findViewById(R.id.url);
        mUrl.setText(DEFAULT_URL);

        // The WebView client (and, once enabled, SDK proxy installation) is set up in
        // DemoWebView's init(); nothing to do here.

        Button loadBtn = findViewById(R.id.load);
        loadBtn.setOnClickListener((View v) -> {
            String url = mUrl.getText().toString().trim();
            if (!url.isEmpty()) {
                // load(...) issues loadUrl only after the SDK proxy is in effect, so even the
                // first navigation cannot leave before routing is set up.
                AXWebViewService.load(mWebView, url);
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mWebView != null) {
            mWebView.onResume();
            mWebView.resumeTimers();
        }
    }

    @Override
    protected void onPause() {
        if (mWebView != null) {
            mWebView.onPause();
            mWebView.pauseTimers();
        }
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        if (mWebView != null) {
            mWebView.loadUrl("about:blank");
            mWebView.stopLoading();
            ViewGroup parent = (ViewGroup) mWebView.getParent();
            if (parent != null) {
                parent.removeView(mWebView);
            }
            mWebView.destroy();
            mWebView = null;
        }
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        if (mWebView != null && mWebView.canGoBack()) {
            mWebView.goBack();
            return;
        }
        super.onBackPressed();
    }
}
