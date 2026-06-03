//
//  AppDelegate.m
//  AXSecurityWebView demo
//
//  The SDK integration is shipped commented out. To enable it: uncomment the
//  marked lines below and fill in your deployment credentials. The SDK must be
//  initialized here (once, at launch) before the proxy is installed on any
//  WebView.
//

#import "AppDelegate.h"

// *** UNCOMMENT THE LINE BELOW FOR SDK ***
// #import <AXSecurityWebView/AXSecurityWebView.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // *** UNCOMMENT THE LINES BELOW FOR SDK ***
    // AXConfig *config = [[AXConfig alloc] init];
    // config.accessKeyID     = @"your accessKeyID of SDK Deployment";
    // config.accessKeySecret = @"your accessKeySecret of SDK Deployment";
    // config.edgeNodes       = @[ @"your edge IP or domain" ];
    //
    // int r = [AXService initialize:config];
    // if (r != 0) {
    //     NSLog(@"[demo] AXService initialize failed: %d", r);
    // }

    return YES;
}

- (UISceneConfiguration *)application:(UIApplication *)application
    configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession
                                   options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration"
                                          sessionRole:connectingSceneSession.role];
}

@end
