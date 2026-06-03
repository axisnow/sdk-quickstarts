package com.axsecurity.sdk.webview.demo;

import android.annotation.SuppressLint;
import android.content.Context;
import android.util.AttributeSet;
import android.webkit.WebSettings;
import android.webkit.WebView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

// *** UNCOMMENT THE IMPORT BELOW FOR SDK ***
// import com.axsecurity.sdk.webview.AXWebViewService;

@SuppressLint("SetJavaScriptEnabled")
public class DemoWebView extends WebView {

    public DemoWebView(@NonNull Context context) {
        super(context);
        init();
    }

    public DemoWebView(@NonNull Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public DemoWebView(@NonNull Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        WebSettings s = getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setUseWideViewPort(true);
        s.setLoadWithOverviewMode(true);

        // By default the demo sets a plain client and loads pages directly. To enable the SDK,
        // installOnWebView wraps this client (callbacks still go to DemoWebViewClient) and routes
        // all WebView traffic through the SDK proxy; it requires a successful
        // AXService.initialize(...) first (see MyApplication). If the SDK isn't initialized or the
        // device WebView lacks proxy support, it falls back to the plain client (direct) and
        // returns false (an AXSDK error is logged).
        // *** COMMENT THE LINE BELOW FOR SDK ***
        setWebViewClient(new DemoWebViewClient());

        // *** UNCOMMENT THE LINE BELOW FOR SDK ***
        // AXWebViewService.installOnWebView(this, new DemoWebViewClient());
    }
}
