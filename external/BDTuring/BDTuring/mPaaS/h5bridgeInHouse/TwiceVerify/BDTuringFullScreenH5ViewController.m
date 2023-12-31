//
//  BDTuringFullScreenH5ViewController.m
//  BDTuring
//
//  Created by yanming.sysu on 2021/3/10.
//

#import "BDTuringFullScreenH5ViewController.h"
#import "BDTuringTVHelper.h"
#import "BDTuringTVDefine.h"
#import "BDTuringTVTracker.h"
#import "BDTuringTVViewController+Piper.h"
#import "BDTuringTVViewController+Utility.h"
#import "BDTuringTVAppNetworkRequestSerializer.h"
#import "BDTuringMacro.h"

#import <WebKit/WebKit.h>
#import <TTBridgeUnify/TTWebViewBridgeEngine.h>
#import <TTBridgeUnify/TTBridgeAuthManager.h>
#import <TTBridgeUnify/BDUnifiedWebViewBridgeEngine.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <TTNetworkManager/TTHTTPRequestSerializerBase.h>

static NSString * const kTTAppNetworkRequestTypeFlag = @"TT-RequestType";

@interface BDTuringFullScreenH5ViewController () <WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *h5TestWebview;
@property (nonatomic, strong) BDTuringH5VerifyModel *model;

@property (nonatomic, strong) TTBridgeCallback cacheCallback;
@property (nonatomic, strong) BDTuringTVResponseCallBack _Nullable callBack;

@end

@implementation BDTuringFullScreenH5ViewController

- (instancetype)initWithModel:(BDTuringH5VerifyModel *)model {
    if (self = [super init]) {
        self.model = model;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [TTBridgeAuthManager sharedManager].authEnabled = NO;//关闭
    NSCAssert(self.model != nil, @"model should not be nil");
    
    self.h5TestWebview = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.h5TestWebview tt_installBridgeEngine:BDUnifiedWebViewBridgeEngine.new];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:self.model.url]];
    [self.h5TestWebview loadRequest:request];
    [self.view addSubview:self.h5TestWebview];
}

#pragma mark - webview delegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error {
    
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView {
    
}

@end
