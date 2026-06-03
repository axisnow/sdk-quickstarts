package com.axsecurity.sdk.webview.demo;

import android.net.http.SslError;
import android.os.Build;
import android.util.Log;
import android.webkit.SslErrorHandler;
import android.webkit.WebResourceError;
import android.webkit.WebResourceRequest;
import android.webkit.WebResourceResponse;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import androidx.annotation.RequiresApi;

public class DemoWebViewClient extends WebViewClient {

    private static final String TAG = "AXWebViewDemo";

    @Override
    public boolean shouldOverrideUrlLoading(WebView view, String url) {
        Log.i(TAG, "loading " + url);
        return false;
    }

    @RequiresApi(api = Build.VERSION_CODES.N)
    @Override
    public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
        Log.i(TAG, "loading " + request.getUrl());
        return false;
    }

    @Override
    public void onReceivedSslError(WebView view, SslErrorHandler handler, SslError error) {
        Log.e(TAG, "SSL error " + error);
        handler.cancel();
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    public void onReceivedError(WebView view, WebResourceRequest request, WebResourceError error) {
        super.onReceivedError(view, request, error);
        if (request.isForMainFrame()) {
            Log.e(TAG, "load error " + request.getUrl() + " : " + error.getDescription());
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    @Override
    public void onReceivedHttpError(WebView view, WebResourceRequest request, WebResourceResponse errorResponse) {
        if (request.isForMainFrame()) {
            int code = errorResponse != null ? errorResponse.getStatusCode() : 0;
            Log.e(TAG, "HTTP " + code + " " + request.getUrl());
        }
    }
}
