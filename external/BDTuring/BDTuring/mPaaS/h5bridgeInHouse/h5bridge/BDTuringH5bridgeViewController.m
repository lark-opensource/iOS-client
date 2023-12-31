//
//  BDTuringH5bridgeViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2021/2/9.
//

#import "BDTuringH5bridgeViewController.h"
#import "BDTuringGlobalH5Bridge.h"

#import <WebKit/WebKit.h>

#import <TTBridgeUnify/BDUnifiedWebViewBridgeEngine.h>

static NSString *const kBDTuringH5bridgeTestURL = @"https://v-center.web.bytedance.net/tools/h5_jsb_test";

@interface BDTuringH5bridgeViewController ()

@property (nonatomic, strong) WKWebView *webview;

@end

@implementation BDTuringH5bridgeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.webview = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self.webview tt_installBridgeEngine:BDUnifiedWebViewBridgeEngine.new];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:kBDTuringH5bridgeTestURL]];
    [self.webview loadRequest:request];
    [self.view addSubview:self.webview];
}

@end
