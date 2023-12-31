//
//  BytedCertWebView.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/7/5.
//

#import "BDCTWebView.h"
#import "BytedCertUIConfig.h"
#import "BytedCertInterface.h"
#import "BDCTCommonPiperHandler.h"
#import "BDCTCorePiperHandler.h"
#import "BytedCertManager+Private.h"
#import <TTBridgeUnify/TTBridgeAuthManager.h>
#import <TTBridgeUnify/TTWebViewBridgeEngine.h>
#import <TTBridgeUnify/BDUnifiedWebViewBridgeEngine.h>
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>


@interface BDCTWebView () <WKNavigationDelegate>
{
    BOOL _hasSetCustomUA;
}

@property (nonatomic, strong, readwrite) BDCTCorePiperHandler *corePiperHandler;

@end


@implementation BDCTWebView

+ (instancetype)webView {
    static WKProcessPool *processPool;
    processPool = [[WKProcessPool alloc] init];

    __auto_type config = [WKWebViewConfiguration new];
    config.processPool = processPool;

    BDCTWebView *webview = [[BDCTWebView alloc] initWithFrame:[UIScreen.mainScreen bounds] configuration:config];
    webview.backgroundColor = BytedCertUIConfig.sharedInstance.backgroundColor ?: UIColor.whiteColor;
    TTWebViewBridgeEngine *bridgeEngine;
    id<TTBridgeAuthorization> authManager = [[BytedCertInterface sharedInstance] manager];
    if (authManager && [authManager conformsToProtocol:@protocol(TTBridgeAuthorization)]) { // 支持自定义，鉴权类
        bridgeEngine = [[BDUnifiedWebViewBridgeEngine alloc] initWithAuthorization:authManager];
    } else { // 默认鉴权类 TTBridgeAuthManager
        bridgeEngine = [[BDUnifiedWebViewBridgeEngine alloc] init];
    }
    [webview tt_installBridgeEngine:bridgeEngine];
    [webview.scrollView setScrollEnabled:false];
    [webview.scrollView setBounces:NO];
    [webview.scrollView.panGestureRecognizer setEnabled:NO];

    __auto_type tmpProtocol = [WKWebViewConfiguration new];
    tmpProtocol.processPool = processPool;

    [webview addPiperHandlers];
    return webview;
}

- (instancetype)initWithFrame:(CGRect)frame configuration:(WKWebViewConfiguration *)configuration {
    self = [super initWithFrame:frame configuration:configuration];
    if (self) {
        self.navigationDelegate = self;
        self.backgroundColor = BytedCertUIConfig.sharedInstance.backgroundColor;
    }
    return self;
}

- (BOOL)isOpaque {
    return NO;
}

- (BDCTCorePiperHandler *)corePiperHandler {
    if (!_corePiperHandler) {
        _corePiperHandler = [BDCTCorePiperHandler new];
    }
    return _corePiperHandler;
}

- (void)addPiperHandlers {
    [self addPiperHandler:[BDCTCommonPiperHandler new]];
    [self addPiperHandler:self.corePiperHandler];
}

- (void)addPiperHandler:(id<BDCTPiperHandlerProtocol>)piperHandler {
    [piperHandler registerHandlerWithWebView:self];
}

- (void)didMoveToSuperview {
    [super didMoveToSuperview];
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        UIResponder *nextResponder = self.nextResponder;
        while ([nextResponder isKindOfClass:UIResponder.class] && ![nextResponder isKindOfClass:UIViewController.class])
            nextResponder = nextResponder.nextResponder;
        if ([nextResponder isKindOfClass:UIViewController.class]) {
            [(UIViewController *)nextResponder setAutomaticallyAdjustsScrollViewInsets:NO];
        }
    }
}

- (void)webViewDidFinishLoad:(WKWebView *)theWebView {
    self.frame = [UIScreen mainScreen].bounds;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    [self.corePiperHandler.flow.performance webviewDidLoad];
}

- (void)loadURL:(NSURL *)URL {
    if (_hasSetCustomUA) {
        [self p_loadURL:URL];
        return;
    }
    __block BOOL isCompleted = NO;
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        if (isCompleted) {
            return;
        }
        [self p_loadURL:URL];
        isCompleted = YES;
    });
    [self evaluateJavaScript:@"navigator.userAgent" completionHandler:^(NSString *_Nullable userAgent, NSError *_Nullable error) {
        @strongify(self);
        if ([userAgent isKindOfClass:NSString.class]) {
            self->_hasSetCustomUA = YES;
            if (BytedCertUIConfig.sharedInstance.isDarkMode) {
                if ([userAgent containsString:@"AppTheme/light"]) {
                    self.customUserAgent = [userAgent stringByReplacingOccurrencesOfString:@"AppTheme/light" withString:@"AppTheme/dark"];
                } else {
                    self.customUserAgent = [NSString stringWithFormat:@"%@ %@", userAgent, @"AppTheme/dark"];
                }
            } else {
                if ([userAgent containsString:@"AppTheme/dark"]) {
                    self.customUserAgent = [userAgent stringByReplacingOccurrencesOfString:@"AppTheme/dark" withString:@"AppTheme/light"];
                } else {
                    self.customUserAgent = [NSString stringWithFormat:@"%@ %@", userAgent, @"AppTheme/light"];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if (isCompleted) {
                return;
            }
            [self p_loadURL:URL];
            isCompleted = YES;
        });
    }];
}

- (void)p_loadURL:(NSURL *)URL {
    if (URL) {
        NSMutableDictionary *uiParams = [NSMutableDictionary dictionary];
        CGFloat statusBarHeight = 0;
        if (@available(iOS 13.0, *)) {
            UIStatusBarManager *statusBarManager = [[UIApplication.sharedApplication.keyWindow windowScene] statusBarManager];
            statusBarHeight = statusBarManager.statusBarFrame.size.height * UIScreen.mainScreen.scale;
        } else {
            statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height * UIScreen.mainScreen.scale;
        }
        if (statusBarHeight == 0) {
            statusBarHeight = BytedCertManager.shareInstance.statusBarHeight;
        }
        uiParams[@"statusbar_height"] = @(statusBarHeight);
        uiParams[@"app_theme"] = BytedCertUIConfig.sharedInstance.isDarkMode ? @"dark" : @"light";
        [self loadRequest:[NSURLRequest requestWithURL:[URL btd_URLByMergingQueries:uiParams.copy]]];
    }
}

- (void)dealloc {
    [self tt_uninstallBridgeEngine];
}

@end
