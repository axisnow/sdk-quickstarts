#import "ViewController.h"
#import <arpa/inet.h>
#import <netdb.h>
#import <netinet/in.h>
#import <sys/socket.h>
#import <unistd.h>

// TODO: Uncomment to use AXSecurity SDK (see README.md for setup)
// #import <AXSecurity/axsecurity.h>

@interface ViewController ()
@property(nonatomic, strong) UILabel *log;
@property(nonatomic, strong) UIButton *button;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // TODO: Initialize AXService here (see README.md)

    self.view.backgroundColor = UIColor.whiteColor;

    self.log = [[UILabel alloc]
        initWithFrame:CGRectMake(0, 0, self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0)];
    self.log.text = @"";
    self.log.textColor = UIColor.blackColor;
    self.log.center = CGPointMake(self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0);
    [self.view addSubview:self.log];

    self.button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.button.frame = CGRectMake(100, 100, 150, 80);
    self.button.backgroundColor = [UIColor yellowColor];
    self.button.titleLabel.font = [UIFont systemFontOfSize:24];
    [self.button setTitle:@"Request" forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(request:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button];
}

- (void)request:(UIButton *)btn {
    [self.log setText:@"requesting..."];
    [self sendPing];
}

- (void)sendPing {
    dispatch_async(dispatch_get_main_queue(), ^{
      NSString *requestHost = @"your-request-domain";
      int requestPort = 7000;

      // TODO: Use AXService to get local proxy address (see README.md)
      // AXLocalProxy *localProxy = [AXService getLocalTCPProxy:requestHost port:requestPort];
      // if (localProxy == nil) { return; }
      // requestHost = localProxy.ip;
      // requestPort = localProxy.port;

      struct addrinfo hints, *pinfo;
      memset(&hints, 0, sizeof hints);
      hints.ai_family = AF_INET;
      hints.ai_socktype = SOCK_STREAM;
      NSString *requestPortStr = [NSString stringWithFormat:@"%d", requestPort];
      int status = getaddrinfo([requestHost UTF8String], [requestPortStr UTF8String], &hints, &pinfo);
      if (status != 0) {
          [self.log setText:[NSString stringWithFormat:@"getaddrinfo: %s", gai_strerror(status)]];
          return;
      }

      int socketFD = socket(AF_INET, SOCK_STREAM, 0);
      if (socketFD == -1) {
          freeaddrinfo(pinfo);
          [self.log setText:[NSString stringWithFormat:@"create socket error: %s", strerror(errno)]];
          return;
      }
      if (connect(socketFD, pinfo->ai_addr, pinfo->ai_addrlen) == -1) {
          close(socketFD);
          freeaddrinfo(pinfo);
          [self.log setText:[NSString stringWithFormat:@"connect error: %s", strerror(errno)]];
          return;
      }
      freeaddrinfo(pinfo);

      NSString *message = @"ping";
      NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
      ssize_t bytesSent = send(socketFD, [data bytes], [data length], 0);
      if (bytesSent == -1) {
          [self.log setText:[NSString stringWithFormat:@"send error: %s", strerror(errno)]];
          close(socketFD);
          return;
      }
      [self.log setText:[NSString stringWithFormat:@"sent: %@", message]];

      uint8_t buffer[1024];
      memset(buffer, 0, sizeof(buffer));
      ssize_t bytesRead = recv(socketFD, buffer, sizeof(buffer) - 1, 0);
      if (bytesRead == -1) {
          [self.log setText:[NSString stringWithFormat:@"recv error: %s", strerror(errno)]];
      } else if (bytesRead == 0) {
          [self.log setText:@"connection closed by server"];
      } else {
          NSString *response = [[NSString alloc] initWithBytes:buffer length:bytesRead encoding:NSUTF8StringEncoding];
          [self.log setText:[NSString stringWithFormat:@"received: %@", response]];
      }

      close(socketFD);
    });
}

@end
