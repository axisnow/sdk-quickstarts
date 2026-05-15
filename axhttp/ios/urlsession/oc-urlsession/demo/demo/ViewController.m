//
//  ViewController.m
//  app-demo
//
//  Created by lyn on 2024/10/1.
//

#import "ViewController.h"
// *** UNCOMMENT THE LINE BELOW FOR AXNSURLSession ***
// #import <AXSecurityNSURLSession/AXNSURLSessionHeader.h>

@interface ViewController ()
@property(nonatomic, strong) UITextView* textView;
@property(nonatomic, strong) UITextField* textField;
@end

NSURLSession* defaultSession;

NSString* helloEndpoint = @"https://example.com";

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString* hostWithPort = nil;

    // *** UNCOMMENT THE LINE BELOW FOR AXNSURLSession ***
    // NSString* accessKeyID=@"your accessKeyID of SDK Deployment";
    // NSString* accessKeySecret=@"your accessKeyID of SDK Deployment";
    // AXConfig *config = [[AXConfig alloc] init];
    // config.accessKeyId = accessKeyID;
    // config.accessKeySecret = accessKeySecret;
    // config.edgeAddresses = @[@"your accessKeyID of SDK Deployment"];
    // int r = [AXNSURLSessionService  Initialize:config];
    // if (r != 0) {
    //     NSLog(@"Initialize failed, code %d", r);
    // }

    int leftWidth = self.view.frame.size.width / 3;
    int top = 60;
    int tap = 10;
    int height = 40;
    int fontSize = 18;

    NSURLSessionConfiguration* cfg = NSURLSessionConfiguration.defaultSessionConfiguration;
    cfg.timeoutIntervalForRequest = 10;
    cfg.timeoutIntervalForResource = 10;

    // *** UNCOMMENT THE LINE BELOW FOR AXNSURLSession ***
    // defaultSession = [AXNSURLSession sessionWithConfiguration: cfg];

    // *** COMMENT THE LINE BELOW FOR AXNSURLSession ***
    defaultSession = [NSURLSession sessionWithConfiguration:cfg];

    _textField = [[UITextField alloc] init];
    _textField.frame = CGRectMake(tap, top, self.view.frame.size.width - 2 * tap, 40);
    _textField.text = helloEndpoint;
    _textField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:_textField];
    top += tap;
    top += height;

    UIScrollView* sv = [[UIScrollView alloc] init];
    sv.frame = CGRectMake(leftWidth + tap + tap, top, self.view.frame.size.width * 2 / 3 - 2 * tap,
                          self.view.frame.size.height - top);
    sv.scrollEnabled = YES;
    sv.contentSize = CGSizeMake(sv.frame.size.width, sv.frame.size.height * 3);

    _textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, sv.frame.size.width, sv.frame.size.height)];
    _textView.editable = NO;
    [sv addSubview:_textView];
    [self.view addSubview:sv];

    UIColor* color = [UIColor colorWithRed:0x62 / 255.0 green:0x00 / 255.0 blue:0xEE / 255.0 alpha:1.0];

    [self initClickButton:@"Request"
                   action:@selector(checkRequest:)
                    frame:CGRectMake(tap, top, leftWidth, height)
                    color:color
                 fontSize:fontSize];
}

- (void)initClickButton:(NSString*)title
                 action:(SEL)action
                  frame:(CGRect)frame
                  color:(UIColor*)color
               fontSize:(CGFloat)fontSize {
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn.frame = frame;
    btn.backgroundColor = color;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
}

- (void)checkRequest:(UIButton*)btn {
    [self.textView setText:[NSString stringWithUTF8String:"requesting"]];

    NSURL* helloURL = [[NSURL alloc] initWithString:[_textField text]];
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:helloURL];
    NSURLSessionDataTask* task =
        [defaultSession dataTaskWithRequest:request
                          completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
                            NSString* message;
                            if (error == nil) {
                                NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
                                long code = httpResponse.statusCode;
                                if (code == 200) {
                                    // successful http response
                                    message = @"200: OK";
                                } else {
                                    // unexpected http response
                                    NSString* reason = [NSHTTPURLResponse localizedStringForStatusCode:code];
                                    message = [NSString stringWithFormat:@"%ld:%@", code, reason];
                                }
                            } else {
                                // other networking failure
                                message = error.localizedDescription;
                            }

                            NSLog(@"%@: %@", helloURL, message);
                            [self setText:[message UTF8String]];
                          }];

    [task resume];
}

- (void)setText:(const char*)info {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSString* jsonString = [[NSString alloc] initWithFormat:@"%s", info];
      [self.textView setText:jsonString];
    });
}
@end
