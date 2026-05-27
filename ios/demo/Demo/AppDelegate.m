#import "AppDelegate.h"

// *** UNCOMMENT THE LINE BELOW FOR SDK ***
// #import <AXSecurity/axsecurity.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // *** UNCOMMENT THE LINES BELOW FOR SDK ***
    // AXConfig *config = [[AXConfig alloc] init];
    // config.accessKeyID     = @"your accessKeyID of SDK Deployment";
    // config.accessKeySecret = @"your accessKeySecret of SDK Deployment";
    // config.edgeNodes       = @[ @"your edge IP or domain" ];
    //
    // AXProxyConfig *proxy = [[AXProxyConfig alloc] init];
    // proxy.secureProxyEnabled = YES;
    // config.proxy = proxy;
    //
    // AXDNSConfig *dns = [[AXDNSConfig alloc] init];
    // dns.edgeDohResolveDomains = @[ @"*.example.com" ];
    // config.dns = dns;
    //
    // int r = [AXService initialize:config];
    // if (r != 0) {
    //     NSLog(@"SDK initialization failed: %d", r);
    // }

    return YES;
}

@end
