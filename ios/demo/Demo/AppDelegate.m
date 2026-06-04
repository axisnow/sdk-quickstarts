#import "AppDelegate.h"

// *** UNCOMMENT THE LINE BELOW FOR SDK ***
// #import <AXSecurity/axsecurity.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // *** UNCOMMENT THE LINES BELOW FOR SDK ***
    // AXConfig *config = [[AXConfig alloc] init];
    // config.accessKeyID     = @"<YOUR_ACCESS_KEY_ID>";
    // config.accessKeySecret = @"<YOUR_ACCESS_KEY_SECRET>";
    // config.edgeNodes       = @[ @"<AXISNOW_EDGE_DOH_EIP_OR_DOMAIN>" ];
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
