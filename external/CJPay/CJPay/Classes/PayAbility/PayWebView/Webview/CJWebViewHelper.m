//
//  CJWebViewHelper.m
//  CJPay
//
//  Created by 王新华 on 2018/12/13.
//

#import "CJWebViewHelper.h"
#import "CJPayProcessPool.h"
#import "CJPayCookieUtil.h"
#import "CJPayUIMacro.h"
#import <BDWebKit/WKWebView+BDSecureLink.h>
#import <BDWebKit/BDWebSecureLinkPlugin.h>
#import <BDWebKit/BDWebSecureLinkCustomSetting.h>
#import "CJPayRequestParam.h"
#import "CJPayBizWebRiskBannerView.h"
#import <objc/runtime.h>
#import "CJPayBridgeAuthManager.h"
#import <IESWebViewMonitor/BDWebView+BDWebViewMonitor.h>
#import <IESWebViewMonitor/WKWebView+PublicInterface.h>
#import "CJPayWKWebView.h"
#import <BDWebKit/BDWebInterceptor.h>
#import "CJPaySettingsManager.h"

@interface WKWebView(CJPaySeclinkSupport)

@property (nonatomic, strong) CJPayBizWebRiskBannerView *cjpayRiskBannerView;

@end

@implementation WKWebView(CJPaySeclinkSupport)

- (void)setCjpayRiskBannerView:(CJPayBizWebRiskBannerView *)cjpayRiskBannerView {
    objc_setAssociatedObject(self, @selector(setCjpayRiskBannerView:), cjpayRiskBannerView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CJPayBizWebRiskBannerView *)cjpayRiskBannerView {
    CJPayBizWebRiskBannerView *bannerView = (CJPayBizWebRiskBannerView *)objc_getAssociatedObject(self, @selector(setCjpayRiskBannerView:));
    if (!bannerView) {
        bannerView = [CJPayBizWebRiskBannerView new];
        @CJWeakify(self);
        bannerView.closeBlock = ^{
            @CJStrongify(self);
            [self.cjpayRiskBannerView removeFromSuperview];
        };
        self.cjpayRiskBannerView = bannerView;
    }
    return bannerView;
}

- (void)cjpayUpdateRiskBanner:(NSString *)content showBanner:(BOOL) showBanner{
    if (!showBanner) {
        return;
    }
    if (!self.cjpayRiskBannerView.superview) {
        [self insertSubview:self.cjpayRiskBannerView atIndex:1000];
        CJPayMasReMaker(self.cjpayRiskBannerView, {
            make.left.right.top.equalTo(self);
        });
    }
    content = Check_ValidString(content) ? content : CJPayLocalizedStr(@"正在访问外部网站，请注意账号和财产安全");
    [self.cjpayRiskBannerView updateWarnContent:content];
}

@end

@implementation CJWebViewHelper

+ (instancetype)shared {
    static CJWebViewHelper *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [CJWebViewHelper new];
    });
    return instance;
}

+ (CJPayWKWebView *)buildWebView:(NSString *)forUrl {
    return [self buildWebView:forUrl httpMethod:@"GET"];
}

+ (CJPayWKWebView *)buildWebView:(NSString *)forUrl httpMethod:(NSString *)httpMethod {
    WKWebViewConfiguration *configuration = [self buildWebviewConfig:forUrl httpMethod:httpMethod];
    
    CJPayWKWebView *webView = [[CJPayWKWebView alloc] initWithFrame:CGRectMake(0, 0, CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT) configuration:configuration];

//    webView.bdwm_usex = YES;
//    [webView bdhm_attachContainerBid:@"cjpay_webview"];
    [[CJPayBridgeAuthManager shared] installEngineOn:webView];
    [[CJPayBridgeAuthManager shared] installIESAuthOn:webView];
    if ([webView.scrollView respondsToSelector:@selector(setContentInsetAdjustmentBehavior:)]) {
        if (@available(iOS 11.0, *)) {
            [webView.scrollView setContentInsetAdjustmentBehavior:UIScrollViewContentInsetAdjustmentNever];
        } else {
            // Fallback on earlier versions
        }
    }
    return webView;
}

+ (WKWebViewConfiguration *)buildWebviewConfig:(NSString *)forUrl httpMethod:(NSString *)httpMethod {
    WKUserContentController *userController = [[WKUserContentController alloc] init];
    WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];
    
    if (@available(iOS 11.0, *)) {
        NSArray<NSHTTPCookie *> *httpCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy];
        for (NSHTTPCookie *cookie in httpCookies) {
            [configuration.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:nil];
        }
    }
    else {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:[[CJPayCookieUtil sharedUtil] getWebCommonScipt:forUrl] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
        [userController addUserScript:userScript];
    }
    
    configuration.userContentController = userController;
    configuration.processPool = [CJPayProcessPool shared];
    // 默认是NO，这个值决定了用内嵌HTML5播放视频还是用本地的全屏控制，face++炫彩活体需要该配置
    configuration.allowsInlineMediaPlayback = YES;
    if (@available(iOS 10.0, *)) {
        configuration.dataDetectorTypes = (WKDataDetectorTypePhoneNumber | WKDataDetectorTypeLink | WKDataDetectorTypeCalendarEvent) ^ WKDataDetectorTypeAll;
        // WKAudiovisualMediaTypeNone 音视频的播放不需要用户手势触发, 即为自动播放
        configuration.mediaTypesRequiringUserActionForPlayback = WKAudiovisualMediaTypeNone;
    } else {
        configuration.requiresUserActionForMediaPlayback = NO;
        // Fallback on earlier versions
    }
    if (@available(iOS 13.0, *)) {
        configuration.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
    }
    
    if (@available(iOS 12.0, *)
        && [CJPaySettingsManager shared].currentSettings.webviewCommonConfigModel.offlineUseSchemeHandler
        && ![httpMethod isEqualToString:@"POST"]
        && ![self isInExcludeDomains:forUrl]) {
        // 加载Web拦截插件
        SEL setupInterceptorPlugin = NSSelectorFromString(@"setupClassPluginForWebInterceptor");
        if ([[BDWebInterceptor sharedInstance] respondsToSelector:setupInterceptorPlugin]) {
            [[BDWebInterceptor sharedInstance] performSelector:setupInterceptorPlugin];
        }

        // 使用WKWebViewConfiguration.setURLSchemeHandler的方式进行拦截
        configuration.bdw_enableInterceptor = YES;
    }
    return configuration;
}

+ (BOOL)injectSecLinkTO:(WKWebView *)webView withScene:(NSString *)scene withOriginalUrl:(NSString *)originalUrl {
    int aid = [[CJPayRequestParam gAppInfoConfig].appId intValue];
    NSString *secLinkDomain = [CJPayRequestParam gAppInfoConfig].secLinkDomain;
    
    if (!Check_ValidString(scene) && [CJPayRequestParam gAppInfoConfig].transferSecLinkSceneBlock) {
        scene = [CJPayRequestParam gAppInfoConfig].transferSecLinkSceneBlock([originalUrl cj_urlQueryParams]);
    }
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"BDWebSecureLinkResponseNotification" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        // 通知类型 https://code.byted.org/iOS_Library/BDWebKit/commit/2be8bd01cef192f2e02adf781fd05dc2be83fcf7
        WKWebView *notiWebview = note.object;
        id json = [note.userInfo cj_dictionaryValueForKey:@"jsonObj"];
        if (![json isKindOfClass:NSDictionary.class]) {
            return;
        }
        // 接口返回值https://bytedance.feishu.cn/docs/doccnuTaBM80lsCMYAk73hTHUEh
        NSDictionary *jsonDic = (NSDictionary *)json;
        NSString *content = [jsonDic cj_stringValueForKey:@"banner_text"];
        BOOL showBanner = [jsonDic cj_boolValueForKey:@"show_banner"];
        [notiWebview cjpayUpdateRiskBanner:content showBanner:showBanner];
    }];
    
    if (!Check_ValidString(scene) && Check_ValidString(secLinkDomain)) {
        return NO;
    }
    NSString *currentLanguage = [CJPayLocalizedUtil getCurrentLanguage] == CJPayLocalizationLanguageEn ? @"en" : @"zh";
    [BDWebSecureLinkPlugin injectToWebView:webView withAid:aid scene:scene lang:currentLanguage]; //  需要在wkwebview初始化后，第一次loadrequest之前调用
    [BDWebSecureLinkPlugin configSecureLinkDomain:secLinkDomain];
    webView.bdw_switchOnFirstRequestSecureCheck = YES; // 打开首次request校验
    webView.bdw_secureLinkCheckRedirectType = BDSecureLinkCheckRedirectTypeAsync; // 打开后续页面跳转或重定向落地页的校验
    return YES;
}

+ (void)secLinkGoBackFrom:(WKWebView *)webView reachEndBlock:(void(^)(void))block {
    [BDWebSecureLinkPlugin secureGoBackStepByStep:webView reachEndBlock:block];
}

+ (BOOL)isBlankWeb:(UIView *)view {
    Class wkCompositingView = NSClassFromString(@"WKCompositingView");
    if ([view isKindOfClass:[wkCompositingView class]]) {
        return NO;
    }
    for(UIView * subView in view.subviews) {
        if (![self isBlankWeb:subView]) {
            return NO;
        }
    }
    return YES;
}

/// schemehandler 离线化部分页面有badcase，需要留个兜底，不分页面不开启离线化，通过settings配置
/// - Parameter url: 当前url
+ (BOOL)isInExcludeDomains:(NSString *)url {
    NSArray *excludeUrlList = [CJPaySettingsManager shared].currentSettings.webviewCommonConfigModel.offlineExcludeUrlList;
    __block BOOL inExcludeUrlList = NO;
    [excludeUrlList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (Check_ValidString(obj) && [url containsString:obj]) {
            inExcludeUrlList = YES;
            *stop = YES;
        }
    }];
    return inExcludeUrlList;
}

+ (BOOL)isInShowErrorViewDomains:(nullable NSString *)url {
    if (!Check_ValidString(url)) {
        return NO;
    }
    
    NSArray *showErrorViewDomainList = [CJPaySettingsManager shared].currentSettings.webviewCommonConfigModel.showErrorViewDomainList;
    __block BOOL inShowErrorViewDomains = NO;
    [showErrorViewDomainList enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (Check_ValidString(obj) && [url containsString:obj]) {
            inShowErrorViewDomains = YES;
            *stop = YES;
        }
    }];
    return inShowErrorViewDomains;
}

@end
