// Copyright 2021 The Lynx Authors. All rights reserved.

#import "BDXLynxWebView.h"
#import "BDUnifiedWebViewBridgeEngine.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUIMethodProcessor.h>
#import <BDXBridgeKit/BDXBridge.h>
#import "LynxView+Bridge.h"
#import <Lynx/LynxRootUI.h>

NSString *const BDXLynxWebViewEventLoad = @"load";
NSString *const BDXLynxWebViewEventTitle = @"title";
NSString *const BDXLynxWebViewEventError = @"error";
NSString *const BDXLynxWebViewEventProgress = @"progress";

@interface BDXLynxWebView () <BDWebViewDelegate>

@property (nonatomic, strong) BDWebView *webView;

@property (nonatomic, copy) NSString *src;
@property (nonatomic, assign) BOOL jsbEnable;
@property (nonatomic, copy) NSString *userAgent;

@end

@implementation BDXLynxWebView

LYNX_REGISTER_UI("x-webview")

static NSMutableDictionary *__engineDic;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [BDXBridge registerDefaultGlobalMethodsWithFilter:nil];
    });
}

+ (void)registerBridge:(void (^)(TTBridgeRegisterMaker * _Nonnull))block forContainerId:(NSString *)containerId {
    if (!block || !containerId.length) {
        return;
    }
    
    if (!__engineDic) {
        __engineDic = [NSMutableDictionary dictionary];
    }
    BDUnifiedWebViewBridgeEngine *engine = __engineDic[containerId];
    if (!engine) {
        engine = BDUnifiedWebViewBridgeEngine.new;
        __engineDic[containerId] = engine;
    }
    
    [engine.bridgeRegister registerBridge:block];
}

+ (void)unregisterBridge:(NSString *)containerId {
    if (!__engineDic || !containerId.length) {
        return;
    }
    [__engineDic removeObjectForKey:containerId];
}

- (void)dealloc {
    [self.view removeObserver:self forKeyPath:@"pageTitle"];
    [self.view removeObserver:self forKeyPath:@"estimatedProgress"];
}

- (UIView *)createView {
    BDWebView *webview = [[BDWebView alloc] init];
    [webview addObserver:self forKeyPath:@"pageTitle" options:NSKeyValueObservingOptionNew context:nil];
    [webview addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    webview.delegate = self;
    return webview;
}

- (void)propsDidUpdate {
    if (self.jsbEnable) {
        NSString *containerId = self.context.rootUI.lynxView.containerID;
        if (containerId.length && !self.view.bridgeEngine) {
            BDUnifiedWebViewBridgeEngine *engine = __engineDic[containerId];
            if (engine) {
                [self.view installBridgeEngine:engine];
            } else {
                [self.view installBridgeEngine:BDUnifiedWebViewBridgeEngine.new];
            }
        }
    } else {
        if (self.view.bridgeEngine) {
            [self.view uninstallBridgeEngine];
        }
    }
}

- (void)layoutDidFinished {
    [super layoutDidFinished];
    [self startLoad];
}

- (void)startLoad {
    if (!self.src.length) {
        return;
    }
    NSURL *url = [NSURL URLWithString:self.src];
    if ([self.view.URL isEqual:url]) {
        return;
    }
    if (self.view.isLoading) {
        [self.view stopLoading];
    }
    [self.view loadRequest:[NSURLRequest requestWithURL:url]];
}

LYNX_PROP_SETTER("src", src, NSString *) {
    _src = [value copy];
}

LYNX_PROP_SETTER("jsb-enable", jsbEnable, BOOL) {
    _jsbEnable = value;
}

LYNX_PROP_SETTER("user-agent", userAgent, NSString *) {
    _userAgent = [value copy];
    self.view.customUserAgent = _userAgent;
}

- (void)webViewDidStartLoad:(BDWebView *)webView {
  
}

- (void)webViewDidFinishLoad:(BDWebView *)webView {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXLynxWebViewEventLoad targetSign:[self sign] detail:@{@"url" : _src ? : @""}];
    [self.context.eventEmitter sendCustomEvent:event];
}


- (void)webView:(BDWebView *)webView didFailLoadWithError:(NSError *)error {
    LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXLynxWebViewEventError
                                                        targetSign:[self sign]
                                                            detail:@{
                                                                @"url" : _src ? : @"",
                                                                @"detail" : [error description],
                                                                @"code": @([error code])
                                                            }];
    [self.context.eventEmitter sendCustomEvent:event];
}

LYNX_UI_METHOD(navigateForward) {
    BOOL canGoForward = [self.view canGoForward];
    if (canGoForward) {
        [self.view goForward];
    }
    callback(
      kUIMethodSuccess, @{
          @"code": canGoForward ? @(0) : @(1),
      });
}

LYNX_UI_METHOD(navigateBack) {
    BOOL canGoBack = [self.view canGoBack];
    if (canGoBack) {
        [self.view goBack];
    }
    callback(
      kUIMethodSuccess, @{
          @"code": canGoBack ? @(0) : @(1),
      });
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"pageTitle"]) {
        NSString *pageTitle = [change objectForKey:NSKeyValueChangeNewKey];
        LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXLynxWebViewEventTitle targetSign:[self sign] detail:@{@"title":pageTitle ? : @""}];
        [self.context.eventEmitter sendCustomEvent:event];
    } else if ([keyPath isEqualToString:@"estimatedProgress"]) {
        NSNumber *estimatedProgress = [change objectForKey:NSKeyValueChangeNewKey];
        LynxCustomEvent *event = [[LynxDetailEvent alloc] initWithName:BDXLynxWebViewEventProgress targetSign:[self sign] detail:@{@"progress":estimatedProgress ? : @""}];
        [self.context.eventEmitter sendCustomEvent:event];
    }
    
}

@end
