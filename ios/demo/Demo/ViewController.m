#import "ViewController.h"

// *** UNCOMMENT THE LINE BELOW FOR SDK ***
// #import <AXSecurity/axsecurity.h>

@interface ViewController ()
@property(nonatomic, strong) UITextView *log;
@property(nonatomic, strong) UIButton *button;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = UIColor.whiteColor;

    CGFloat viewW = self.view.frame.size.width;
    CGFloat viewH = self.view.frame.size.height;
    CGFloat pad = 12;
    CGFloat topInset = 60;
    CGFloat btnW = viewW / 3.0;
    CGFloat btnH = 60;

    self.button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.button.frame = CGRectMake(pad, topInset, btnW, btnH);
    self.button.backgroundColor = [UIColor cyanColor];
    self.button.titleLabel.font = [UIFont systemFontOfSize:20];
    [self.button setTitle:@"HTTP Request" forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(request:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button];

    CGFloat logX = pad + btnW + pad;
    CGFloat logW = viewW - logX - pad;
    CGFloat logH = viewH - topInset - pad;
    self.log = [[UITextView alloc] initWithFrame:CGRectMake(logX, topInset, logW, logH)];
    self.log.editable = NO;
    self.log.font = [UIFont systemFontOfSize:14];
    self.log.textColor = UIColor.blackColor;
    self.log.backgroundColor = [UIColor colorWithWhite:0.96 alpha:1.0];
    self.log.layer.borderColor = [UIColor colorWithWhite:0.85 alpha:1.0].CGColor;
    self.log.layer.borderWidth = 1.0;
    self.log.layer.cornerRadius = 6.0;
    self.log.text = @"";
    [self.view addSubview:self.log];
}

- (void)request:(UIButton *)btn {
    [self.log setText:@"requesting..."];
    [self sendHTTPRequest];
}

- (void)sendHTTPRequest {
    NSString *urlString = @"https://your.server.domain/your/path";

    // *** COMMENT THE LINE BELOW FOR SDK ***
    NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];

    // *** UNCOMMENT THE LINES BELOW FOR SDK ***
    // AXLocalProxy *httpProxy = [AXService getLocalHTTPProxy];
    // if (httpProxy == nil) {
    //     [self.log setText:@"get http proxy address error"];
    //     return;
    // }
    // NSURLSessionConfiguration *cfg = [NSURLSessionConfiguration defaultSessionConfiguration];
    // cfg.connectionProxyDictionary = @{
    //     @"HTTPEnable"  : @YES,
    //     @"HTTPProxy"   : httpProxy.ip,
    //     @"HTTPPort"    : @(httpProxy.port),
    //     @"HTTPSEnable" : @YES,
    //     @"HTTPSProxy"  : httpProxy.ip,
    //     @"HTTPSPort"   : @(httpProxy.port),
    // };

    cfg.timeoutIntervalForRequest = 10;
    cfg.timeoutIntervalForResource = 10;

    NSURLSession *session = [NSURLSession sessionWithConfiguration:cfg];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];

    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task =
        [session dataTaskWithRequest:request
                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                     NSString *message;
                     if (error != nil) {
                         message = [NSString stringWithFormat:@"http request error: %@", error.localizedDescription];
                     } else {
                         NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                         long code = httpResponse.statusCode;
                         if (code == 200) {
                             NSString *body = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                             message = [NSString stringWithFormat:@"%ld: %@", code, body ?: @"(empty)"];
                         } else {
                             NSString *reason = [NSHTTPURLResponse localizedStringForStatusCode:code];
                             message = [NSString stringWithFormat:@"%ld: %@", code, reason];
                         }
                     }
                     NSLog(@"%@: %@", url, message);
                     dispatch_async(dispatch_get_main_queue(), ^{
                       [weakSelf.log setText:message];
                     });
                   }];
    [task resume];
}

@end
