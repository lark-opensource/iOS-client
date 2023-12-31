//
//  WKWebView+BDWSCCWebView.m
//  AWELazyRegister
//
//  Created by bytedance on 6/20/22.
//
#import "BDWebSCCManager.h"
#import "BDSCCURLObserver.h"

#import "WKWebView+BDWSCCWebView.h"
#import <objc/runtime.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <BDWebCore/WKWebView+Plugins.h>
#import "NSObject+BDWRuntime.h"
#import <ByteDanceKit/BTDMacros.h>

static NSString * const kObserverSCCWebViewURLKeyPath = @"URL";
static const char * kSCCWebViewURLObserverKey = "kSCCWebViewURLObserverKey";
static const char * kSCCReloadCount = "kSCCReloadCount";

@interface WKWebView ()

@property (nonatomic, strong) NSNumber *reloadCount;

@end

@interface SCCPlugin : IWKPluginObject<IWKClassPlugin>

@end


@implementation SCCPlugin

#pragma mark - Navigation Delegate

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    BOOL ifSCCEnableAndMainFrame = [self ifSCCEnable:webView] && navigationAction.targetFrame && navigationAction.targetFrame.isMainFrame;
    if (webView.bdw_sccURLObserver && ifSCCEnableAndMainFrame) {
        NSArray *denyDic = webView.bdw_sccURLObserver.config.denyDic;
        if (denyDic) {
            BOOL urlInDenyList = NO;
            NSString* newURLStr = navigationAction.request.URL.absoluteString;
            for (int i = 0;i < denyDic.count;i++) {
                NSArray *denyList = [denyDic[i] objectForKey:@"urlSet"];
                for (int j = 0;j < denyList.count;j++) {
                    NSError *error = NULL;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:denyList[j] options:NSRegularExpressionCaseInsensitive error:&error];
                    NSRange range = [regex rangeOfFirstMatchInString:newURLStr options:NSMatchingReportProgress range:NSMakeRange(0, newURLStr.length)];
                    if(range.location == 0 && range.length == newURLStr.length) {
//                        if([webView.bdw_sccURLObserver.config.customHandler respondsToSelector:@selector(bdw_URLRiskLevel:forReason:withWebView:forURL:canGoBack:)]) {
                            BOOL canGoBack = (webView.backForwardList.currentItem.URL != nil);
                            BDSCCLog(@"scc hit local deny url %@ for webview request %@",denyList[j],newURLStr);
                            NSString *reason = @"deny_setting";
                            if(canGoBack) {
                                reason = @"deny_no_effect";
                            }
                            if([webView.bdw_sccURLObserver.config.customHandler respondsToSelector:@selector(bdw_URLRiskLevel:forReason:withWebView:forURL:canGoBack:)]) {
                                BOOL needForbiddenThisRequest = [webView.bdw_sccURLObserver.config.customHandler bdw_URLRiskLevel:BDWebViewSCCReportTypeDeny forReason:reason withWebView:webView.bdw_sccURLObserver.webView forURL:webView.URL canGoBack:canGoBack];
                                if (needForbiddenThisRequest) {
                                    [webView.bdw_sccURLObserver resetSCCStatusForWebView];
                                    decisionHandler(WKNavigationActionPolicyCancel);
                                    return IWKPluginHandleResultBreak;
                                }
                            }
//                        }
                    }
                }
            }
        }
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    if([self ifSCCEnable:webView] && webView.bdw_sccURLObserver.config.needCloudChecking){
        NSURL *nowURL = webView.URL;
        if (webView.bdw_sccURLObserver.config.hasBeenReach) {
            if (webView.bdw_sccURLObserver.config.reportType == BDWebViewSCCReportTypeDeny ||
                webView.bdw_sccURLObserver.config.reportType == BDWebViewSCCReportTypeCancel||
                webView.bdw_sccURLObserver.config.reportType == BDWebViewSCCReportTypeNotice) {
                webView.bdw_sccURLObserver.config.needCloudChecking = NO;
                webView.bdw_sccURLObserver.config.hasBeenReach = NO;

                if([webView.bdw_sccURLObserver.config.customHandler respondsToSelector:@selector(bdw_URLRiskLevel:forReason:withWebView:forURL:canGoBack:)]) {
                    BOOL canGoBack = (webView.backForwardList.currentItem.URL != nil);
                    BOOL needForbiddenThisRequest = [webView.bdw_sccURLObserver.config.customHandler bdw_URLRiskLevel:webView.bdw_sccURLObserver.config.reportType forReason:@"scc_res" withWebView:webView forURL:nowURL canGoBack:canGoBack];
                    if (needForbiddenThisRequest) {
                        decisionHandler(WKNavigationActionPolicyCancel);
                        return IWKPluginHandleResultBreak;
                    }
                }
                return IWKPluginHandleResultContinue;
            } else {
                [webView.bdw_sccURLObserver resetSCCStatusForWebView];
                if([webView.bdw_sccURLObserver.config.customHandler respondsToSelector:@selector(bdw_URLRiskLevel:forReason:withWebView:forURL:canGoBack:)]) {
                    BOOL canGoBack = (webView.backForwardList.currentItem.URL != nil);
                    [webView.bdw_sccURLObserver.config.customHandler bdw_URLRiskLevel:webView.bdw_sccURLObserver.config.reportType forReason:@"scc_res" withWebView:webView forURL:nowURL canGoBack:canGoBack];
                }
                return IWKPluginHandleResultContinue;
            }
        } else {
            BDWebSCCManager *settingManager = [BDWebSCCManager shareInstance];
            double deltaTime = [[NSDate date] timeIntervalSinceDate:webView.bdw_sccURLObserver.config.cloudCheckBeginTime];
            BOOL ifTimeOut= (settingManager.maxWaitTime-deltaTime*1000)>0?YES:NO;
            if (ifTimeOut) {
                NSInteger count = [webView.reloadCount integerValue] + 1;
                if (count < settingManager.maxReloadCount) {
                    webView.reloadCount = [NSNumber numberWithInteger:count];
                    BDSCCLog(@"scc reload count number is %@ with webview %@",webView.reloadCount,webView);
                    decisionHandler(WKNavigationActionPolicyCancel);
                    [webView loadRequest:[NSURLRequest requestWithURL:webView.URL]];
                    return IWKPluginHandleResultBreak;
                } else {
                    [webView.bdw_sccURLObserver resetSCCStatusForWebView];
                    if([webView.bdw_sccURLObserver.config.customHandler respondsToSelector:@selector(bdw_URLRiskLevel:forReason:withWebView:forURL:canGoBack:)]) {
                        BOOL canGoBack = (webView.backForwardList.currentItem.URL != nil);
                        BDSCCLog(@"scc reload count overflow");
                        BOOL needForbiddenThisRequest = [webView.bdw_sccURLObserver.config.customHandler bdw_URLRiskLevel:BDWebViewSCCReportTypeUnknown forReason:@"timeout" withWebView:webView forURL:nowURL canGoBack:canGoBack];
                        if (needForbiddenThisRequest) {
                            decisionHandler(WKNavigationActionPolicyCancel);
                            return IWKPluginHandleResultBreak;
                        }
                    }
                }
            } else {
                [webView.bdw_sccURLObserver resetSCCStatusForWebView];
                if([webView.bdw_sccURLObserver.config.customHandler respondsToSelector:@selector(bdw_URLRiskLevel:forReason:withWebView:forURL:canGoBack:)]) {
                    BOOL canGoBack = (webView.backForwardList.backItem.URL != nil);
                    BOOL needForbiddenThisRequest = [webView.bdw_sccURLObserver.config.customHandler bdw_URLRiskLevel:BDWebViewSCCReportTypeUnknown forReason:@"timeout" withWebView:webView forURL:nowURL canGoBack:canGoBack];
                    BDSCCLog(@"scc time out");
                    if (needForbiddenThisRequest) {
                        decisionHandler(WKNavigationActionPolicyCancel);
                        return IWKPluginHandleResultBreak;
                    }
                }
            }
        }
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if ([self ifSCCEnable:webView]) {
        webView.reloadCount = [NSNumber numberWithInteger:0];
        [webView.bdw_sccURLObserver resetSCCStatusForWebView];
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webViewWillDealloc:(WKWebView *)webView {
    if (webView.bdw_sccURLObserver) {
        [webView removeObserver:webView.bdw_sccURLObserver forKeyPath:kObserverSCCWebViewURLKeyPath];
    }
    return IWKPluginHandleResultContinue;
}

#pragma mark - Tool

- (BOOL)ifSCCEnable:(WKWebView *)webView {
    return webView.bdw_sccURLObserver && webView.bdw_sccURLObserver.config.enable;
}

@end

@implementation WKWebView (BDWSCCWebView)

- (void)setBdw_sccURLObserver:(BDWSCCURLObserver *)bdw_sccURLObserver {
    objc_setAssociatedObject(self, &kSCCWebViewURLObserverKey, bdw_sccURLObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDWSCCURLObserver *)bdw_sccURLObserver {
    return objc_getAssociatedObject(self,&kSCCWebViewURLObserverKey);
}

- (void)setReloadCount:(NSNumber *)reloadCount {
    objc_setAssociatedObject(self, &kSCCReloadCount, reloadCount, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)reloadCount {
    return objc_getAssociatedObject(self,&kSCCReloadCount);
}

- (void)bdw_EnableSCCCheckWithHandler:(id<BDWSCCWebViewCustomHandler>)customHandler {
    if (@available(iOS 9.0, *)) {
        if (!customHandler) {
            BDSCCLog(@"handler empty");
            return;
        }
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            [WKWebView IWK_loadPlugin:SCCPlugin.new];
        });
        if (!self.bdw_sccURLObserver) {
            BDWSCCURLObserver *ob = [[BDWSCCURLObserver alloc] init];
            self.bdw_sccURLObserver = ob;
            self.bdw_sccURLObserver.webView = self;
            self.bdw_sccURLObserver.config.customHandler = customHandler;
            self.bdw_sccURLObserver.config.seclinkScene = @"common";
            self.bdw_sccURLObserver.config.allowListForJumpAPP = [[NSArray alloc] init];
            if([self.bdw_sccURLObserver.config.customHandler respondsToSelector:@selector(fetchSeclinkParameter)]) {
                NSDictionary *settingDic = [self.bdw_sccURLObserver.config.customHandler fetchSeclinkParameter];
                NSString *scene = [settingDic btd_stringValueForKey:@"scene"];
                if (!BTD_isEmptyString(scene)) {
                    self.bdw_sccURLObserver.config.seclinkScene = scene;
                }
            }
            if([self.bdw_sccURLObserver.config.customHandler respondsToSelector:@selector(fetchAllowAndDenyList)]) {
                NSDictionary *settingDic = [self.bdw_sccURLObserver.config.customHandler fetchAllowAndDenyList];
                self.bdw_sccURLObserver.config.enable = YES;
                BDWebSCCManager *settingRule = [BDWebSCCManager shareInstance];
                settingRule.maxWaitTime = 1500;
                settingRule.maxReloadCount = 11;
                if (settingDic) {
                    NSArray *allowArray = [settingDic btd_arrayValueForKey:@"scc_cs_allow_list"];
                    BDWebSCCManager *settingRule = [BDWebSCCManager shareInstance];
                    if (!BTD_isEmptyArray(allowArray)) {
                        NSUserDefaults *ruleLocalStorage = [NSUserDefaults standardUserDefaults];
                        [ruleLocalStorage setObject:allowArray forKey:@"allowRule"];
                        if (!settingRule.storageList) {
                            settingRule.storageList = ruleLocalStorage;
                        }
                    }
                    NSArray *denyDic = [settingDic btd_arrayValueForKey:@"scc_cs_deny_list"];
                    if (!BTD_isEmptyArray(denyDic)) {
                        self.bdw_sccURLObserver.config.denyDic = denyDic;
                    }
                    NSArray *allowJumpArray = [settingDic btd_arrayValueForKey:@"scc_cs_allow_jumpAPP_list"];
                    if (!BTD_isEmptyArray(allowJumpArray)) {
                        self.bdw_sccURLObserver.config.allowListForJumpAPP = allowJumpArray;
                    }
                    NSInteger maxWaitTime = [settingDic btd_intValueForKey:@"scc_cs_max_wait_time"];
                    if (maxWaitTime > 0) {
                        settingRule.maxWaitTime = maxWaitTime;
                    }
                    NSInteger maxReloadCount = [settingDic btd_intValueForKey:@"scc_cs_max_reload_count"];
                    if (maxReloadCount > 0) {
                        settingRule.maxReloadCount = maxReloadCount;
                    }
                    BOOL enable = [settingDic btd_boolValueForKey:@"scc_cs_enable"];
                    self.bdw_sccURLObserver.config.enable = enable;
                }
            }

            self.reloadCount = @(0);
            [self addObserver:self.bdw_sccURLObserver forKeyPath:kObserverSCCWebViewURLKeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        }
    } else {
        BDSCCLog(@"ios version lower than 9");
    }
}

- (BOOL)disableJumpToOthersAPP:(NSURL *)url {
    if (BTD_isEmptyArray(self.bdw_sccURLObserver.config.allowListForJumpAPP)) {
        return NO;
    } else {
        for(int i=0; i < self.bdw_sccURLObserver.config.allowListForJumpAPP.count; i++) {
            if ([self.bdw_sccURLObserver.config.allowListForJumpAPP[i] isEqualToString:url.absoluteString]) {
                return YES;
            }
        }
        return NO;
    }
}

- (void)bdw_DisableSCCCheck {
    if (self.bdw_sccURLObserver) {
        self.bdw_sccURLObserver.config.enable = NO;
    }
}

@end

