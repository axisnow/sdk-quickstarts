//
//  ViewController.swift
//  AXSecurityWebView swift demo
//
//  Minimal integration: build your own WKWebView, then install the SDK proxy
//  onto it before loading a page. The SDK integration is shipped commented out;
//  uncomment the marked lines below (and the SDK setup in AppDelegate.swift) to
//  route the WebView through the SDK secure tunnel.
//

import UIKit
import WebKit

// *** UNCOMMENT THE LINE BELOW FOR SDK ***
// import AXSecurityWebView

private let demoURL = "https://example.com/"

class ViewController: UIViewController {
    private var webView: WKWebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        // 1) Create your own web view however you normally would. Using a
        //    non-persistent data store scopes the proxy to this web view only.
        let cfg = WKWebViewConfiguration()
        cfg.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: view.bounds, configuration: cfg)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(webView)

        // 2) Route this web view's traffic through the SDK secure tunnel.
        //    Requires iOS 17+ and a successful AXService.initialize(_:) beforehand
        //    (see AppDelegate.swift). Install before the first load.
        // *** UNCOMMENT THE LINES BELOW FOR SDK ***
        // if #available(iOS 17.0, *) {
        //     let rc = AXWebViewService.install(on: webView)
        //     if rc != 0 {
        //         NSLog("[demo] proxy not applied, code: \(rc)")
        //     }
        // }

        // 3) Load the page. With the SDK enabled, this navigation goes through the
        //    proxy; otherwise it loads directly.
        if let url = URL(string: demoURL) {
            webView.load(URLRequest(url: url))
        }
    }
}
