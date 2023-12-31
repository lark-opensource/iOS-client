//
//  CJPayHybridView.m
//  CJPaySandBox
//
//  Created by 高航 on 2023/2/13.
//

#import "CJPayHybridView.h"
#import <HybridKit/HybridKitViewProtocol.h>
#import <HybridKit/HybridKit.h>
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import <HybridKit/HybridSchemaParam.h>
#import <HybridKit/HybridWebKitUtils.h>
#import <HybridKit/HybridIESWebView.h>
#import <TTBridgeUnify/TTWebViewBridgeEngine.h>
#import "CJPayWebViewUtil.h"
#import "CJPayBridgeAuthManager.h"
#import "CJPayHybridBaseConfig.h"
#import "CJPayHybridLifeCycleSubscribeCenter.h"
#import "CJPayTargetProxy.h"
#import "CJPaySettingsManager.h"
#import "CJPayLoadingManager.h"
#import "CJPayRequestParam.h"
#import "CJWebViewHelper.h"


@interface CJPayHybridView()<HybridKitViewLifecycleProtocol>

@property (nonatomic, assign, readwrite) HybridEngineType engineType;


@end

@implementation CJPayHybridView

- (instancetype)initWithConfig:(CJPayHybridBaseConfig *)config {
    self = [super init];
    if (self) {
        _config = config;
        _context = [config toContext];
        [self p_init];
    }
    return self;
}


- (HybridEngineType)engineType {
    return self.context.schemaParams.engineType;
}

- (void)sendEvent:(NSString *)event params:(NSDictionary *)data {
    if (!Check_ValidString(event)) {
        return;
    }
    [self.kitView sendEvent:event params:data];
}

#pragma mark -private

- (void)p_init {
    if (self.config.enginetype == HybridEngineTypeWeb) {
        [self p_initWebView];
    }
}

- (void)p_setTag {
    return;
}

- (void)p_initWebView {
    [self p_setupWKConfig];
    [self p_seclinkInject];
    [self p_setupUA];
}

- (void)p_setupUA {
    @CJWeakify(self)
    [[CJPayWebViewUtil sharedUtil] setupUAWithCompletion:^(NSString * _Nullable userAgent) {
        @CJStrongify(self)
        NSString *customUA = [NSString stringWithFormat:@"%@ Kernel/hybridkit", CJString(userAgent)];
        [self p_setupKitViewWithUA:customUA];
    }];
}

- (void)p_setupKitViewWithUA:(NSString *)customUA {
    self.context.customUA = CJString(customUA);
    self.kitView = [[HybridKit sharedInstance] kitViewWithUrl:self.context.originURL context:self.context frame:self.bounds];
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy viewDidCreate:self.kitView];
    self.kitView.lifecycleDelegate = self;
    
    CJPayContainerConfig *containerConfig = [CJPaySettingsManager shared].localSettings.containerConfig;
    if (self.kitView.rawView && [self.kitView.rawView isKindOfClass:WKWebView.class]) {
        WKWebView *rawWKWebview = (WKWebView *)self.kitView.rawView;
        if (!containerConfig.enableHybridkitUA) {
            [rawWKWebview setCustomUserAgent:self.context.customUA];
            [CJTracker event:@"wallet_user_agent"
                      params:@{@"user_agent": self.context.customUA}];
        }
        id WKDelegate = self.context.webviewNavigationDelegate;
        
        if (WKDelegate && [WKDelegate conformsToProtocol:@protocol(WKUIDelegate)]) {
            rawWKWebview.UIDelegate = (id<WKUIDelegate>)WKDelegate;
        }
        
        [[CJPayBridgeAuthManager shared] installIESAuthOn:rawWKWebview];
        
    }
    [self addSubview:self.kitView];
    CJPayMasMaker(self.kitView, {
        make.edges.equalTo(self);
    });
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CJPayWebViewOfflineNotification" object:@{@"action": @(0)}];
    
    [self.kitView load];
    NSURL *url = [NSURL URLWithString:self.config.url];
    
    [CJPayTracker event:@"wallet_rd_webview_start_load" params:@{
        @"kernel_type" : @"1",
        @"type": @"web",
        @"url": CJString(self.config.url),
        @"schema": CJString(self.config.scheme),
        @"host" : CJString(url.host),
        @"path" : CJString(url.path)
        }];
}

- (void)p_seclinkInject {
    int aid = [[CJPayRequestParam gAppInfoConfig].appId intValue];
    NSString *secLinkDomain = [CJPayRequestParam gAppInfoConfig].secLinkDomain;
    NSString *currentLanguage = [CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageEn ? @"en" : @"zh";
    HybridWebSecureLinkConfig *seclinkConfig = [HybridWebSecureLinkConfig configWithAid:aid scene:self.config.secLinkScene language:currentLanguage switchOnFirstRequestSecureCheck:YES secureLinkCheckRedirectType:BDSecureLinkCheckRedirectTypeAsync];
    self.context.secureLinkConfig = seclinkConfig;
}

- (void)p_setupWKConfig {
    WKWebViewConfiguration *wkConfig = [CJWebViewHelper buildWebviewConfig:self.config.url httpMethod:self.config.openMethod];
    self.context.webViewConfig = wkConfig;
}


#pragma mark - LifeCycle
- (void)viewDidCreate:(id<HybridKitViewProtocol>)view {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy viewDidCreate:view];
}

- (void)viewWillStartLoading:(id<HybridKitViewProtocol>)view {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy viewWillStartLoading:view];
}

- (void)viewDidStartLoading:(id<HybridKitViewProtocol>)view {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy viewDidStartLoading:view];
}

- (void)view:(id<HybridKitViewProtocol>)view didFinishLoadWithURL:(NSString *_Nullable)url {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy view:view didFinishLoadWithURL:url];
    [self p_setTag];
}

- (void)viewDidFirstScreen:(id<HybridKitViewProtocol>)view {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy viewDidFirstScreen:view];
}

- (void)viewDidConstructJSRuntime:(id<HybridKitViewProtocol>)view {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy viewDidConstructJSRuntime:view];
}

- (void)view:(id<HybridKitViewProtocol>)view didLoadFailedWithURL:(NSString *)url error:(NSError *)error {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy view:view didLoadFailedWithURL:url error:error];
}

- (void)view:(id<HybridKitViewProtocol>)view didRecieveError:(NSError *)error {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy view:view didRecieveError:error];
}

- (void)viewWillDealloc:(id<HybridKitViewProtocol>)view {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy viewWillDealloc:view];
}

- (void)dealloc {
    [[CJPayHybridLifeCycleSubscribeCenter defaultService].subscriberProxy viewWillDealloc:_kitView];
}

@end
