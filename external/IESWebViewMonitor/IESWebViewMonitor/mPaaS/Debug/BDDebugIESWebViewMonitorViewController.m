//
//  BDDebugIESWebViewMonitorViewController.m
//  IESWebViewMonitor
//
//  Created by chenshu on 2020/7/31.
//

#import "BDDebugIESWebViewMonitorViewController.h"
#import "BDDebugTestWebView.h"
#import "IESLiveWebViewMonitor.h"

@interface BDDebugIESWebViewMonitorViewController ()

@property (nonatomic, strong) BDDebugTestWebView *webView;

@end

@implementation BDDebugIESWebViewMonitorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _webView = [[BDDebugTestWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_webView];
    
    NSURL *URL = [NSURL URLWithString:@"https://www.baidu.com"];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    [_webView loadRequest:request];
}

@end
