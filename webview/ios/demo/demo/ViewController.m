//
//  ViewController.m
//  AXSecurityWebView demo
//
//  Minimal integration: build your own WKWebView, then install the SDK proxy
//  onto it before loading a page. The SDK integration is shipped commented out;
//  uncomment the marked lines below (and the SDK setup in AppDelegate.m) to
//  route the WebView through the SDK secure tunnel.
//

#import "ViewController.h"

#import <WebKit/WebKit.h>

// *** UNCOMMENT THE LINE BELOW FOR SDK ***
// #import <AXSecurityWebView/AXSecurityWebView.h>

static NSString *const kDemoURL = @"https://example.com/";

@interface ViewController ()
@property(nonatomic, strong) WKWebView *webView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    // 1) Create your own web view however you normally would. Using a
    //    non-persistent data store scopes the proxy to this web view only.
    WKWebViewConfiguration *cfg = [[WKWebViewConfiguration alloc] init];
    cfg.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:cfg];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];

    // 2) Route this web view's traffic through the SDK secure tunnel.
    //    Requires iOS 17+ and a successful [AXService initialize:] beforehand
    //    (see AppDelegate.m). Install before the first load.
    // *** UNCOMMENT THE LINES BELOW FOR SDK ***
    // if (@available(iOS 17.0, *)) {
    //     int rc = [AXWebViewService installOnWebView:self.webView];
    //     if (rc != 0) {
    //         NSLog(@"[demo] proxy not applied: %d", rc);
    //     }
    // }

    // 3) Load the page. With the SDK enabled, this navigation goes through the
    //    proxy; otherwise it loads directly.
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:kDemoURL]]];
}

@end
