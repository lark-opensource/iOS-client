//
//  CJPayWEH5Channel.m
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import "CJPayWEH5Channel.h"
#import "CJPayChannelManager.h"
#import <WebKit/WebKit.h>
#import "CJPayPrivacyMethodUtil.h"
#import "CJPayLoadingManager.h"
#import "CJPaySDKMacro.h"

@interface CJPayWEH5Channel()<WKNavigationDelegate>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, assign) CFAbsoluteTime startTime;
@property (nonatomic, assign) BOOL wakingApp;
@property (nonatomic, assign) BOOL showLoading;

@end

@implementation CJPayWEH5Channel

CJPAY_REGISTER_PLUGIN({
    [[CJPayChannelManager sharedInstance] registerChannelClass:self channelType:CJPayChannelTypeWXH5];
})

- (instancetype)init {
    self = [super init];
    if (self) {
        self.channelType = CJPayChannelTypeWXH5;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidInForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    self.webView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)canProcessWithURL:(NSURL *)URL {
    NSString *nativeReferSchema = [CJPayChannelManager sharedInstance].h5PayReferUrl;
    if ([URL.absoluteString hasPrefix:nativeReferSchema]) {
        if (self.completionBlock) {
            CJPayResultType resultType = [self.dataDict cj_boolValueForKey:@"use_visible_callback"] ? CJPayResultTypeBackToForeground : CJPayResultTypeSuccess;
            self.completionBlock(CJPayChannelTypeWXH5, resultType, @"");
            self.completionBlock = nil;
            NSMutableDictionary *trackDic = [NSMutableDictionary new];
            [trackDic addEntriesFromDictionary:@{
                @"method" : @"wxh5pay",
                @"status" : @"1",
                @"spend_time" : @((CFAbsoluteTimeGetCurrent() - self.startTime) * 1000),
                @"is_install" : @"0",
                @"other_sdk_version" : @""
            }];
            [self trackWithEvent:@"wallet_pay_by_sdk" trackParam:trackDic];
        }
        return YES;
    }
    return NO;
}

- (void)payActionWithDataDict:(NSDictionary *)dataDict completionBlock:(CJPayCompletion)completionBlock {
    
    [super payActionWithDataDict:dataDict completionBlock:completionBlock];
    
    if (![self p_isWXAppInstalled]) {
        CJ_CALL_BLOCK(self.completionBlock, CJPayChannelTypeWX, CJPayResultTypeUnInstall, @"");
        self.completionBlock = nil;
        self.dataDict = nil;
        return;
    }
    self.wakingApp = YES;
    
    NSString *weBayUrl = [[dataDict valueForKey:@"pay_param"] valueForKey:@"url"];
    if (!Check_ValidString(weBayUrl)) {
        weBayUrl = [dataDict valueForKey:@"url"];
    }
    if (!Check_ValidString(weBayUrl)) {
        weBayUrl = [[dataDict cj_stringValueForKey:@"MwebUrl"] cj_replaceUnicode];
    }
    if (!Check_ValidString(weBayUrl)) {
        weBayUrl = [[dataDict cj_stringValueForKey:@"mweb_url"] cj_replaceUnicode];
    }
    
    self.showLoading = [dataDict cj_boolValueForKey:@"show_loading"];
    
    // 获取refer
    NSString *nativeReferSchema = [CJPayChannelManager sharedInstance].h5PayReferUrl;
    NSString *serverConfigRefer = [dataDict valueForKey:@"refer"];
    if (Check_ValidString(serverConfigRefer)) {
        nativeReferSchema = serverConfigRefer;
    }
    if (!nativeReferSchema || nativeReferSchema.length < 1) {
        CJPayLogAssert(NO, @"未配置微信的referurl, [CJPayChannelManager sharedInstance].h5PayReferUrl");
        return;
    }
    
    // 获取UA
    NSString *userAgent = CJPayChannelManager.sharedInstance.h5PayCustomUserAgent;
    NSString *serverConfigUA = [dataDict valueForKey:@"ua"];
    if (Check_ValidString(serverConfigUA)) {
        userAgent = serverConfigUA;
    }
    
    NSMutableURLRequest *weBayRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[weBayUrl cj_safeURLString]]];
    NSMutableDictionary *httpField = [NSMutableDictionary new];
    httpField[@"Referer"] = nativeReferSchema;
    weBayRequest.allHTTPHeaderFields = httpField;
    self.webView = [WKWebView new];
    self.webView.navigationDelegate = self;
    
    if (Check_ValidString(userAgent)) {
        self.webView.customUserAgent = userAgent;
    }
    self.startTime = CFAbsoluteTimeGetCurrent();
    [self.webView loadRequest:weBayRequest];
    if (self.showLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
    }
}

- (BOOL)p_isWXAppInstalled
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"weixin://"]];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *absoluteString = [navigationAction.request.URL.absoluteString stringByRemovingPercentEncoding];
    //拦截重定向的跳转微信的 URL Scheme, 打开微信
    if ([absoluteString hasPrefix:@"weixin://"]) {
        CJ_CALL_BLOCK(decisionHandler, WKNavigationActionPolicyCancel);
        NSURL *wxURL = [navigationAction.request.URL copy];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([[UIApplication sharedApplication] canOpenURL:wxURL]) {
                
                // 调用AppJump敏感方法，需走BPEA鉴权
                [CJPayPrivacyMethodUtil applicationOpenUrl:wxURL
                                                withPolicy:@"bpea-caijing_webview_open_weixin_h5"
                                           completionBlock:^(NSError * _Nullable error) {
                    if (error) {
                        CJPayLogError(@"error in bpea-caijing_webview_open_weixin_h5");
                    }
                }];
            }
        });
        return;
    }
    CJ_CALL_BLOCK(decisionHandler, WKNavigationActionPolicyAllow);
}

- (void)exeCompletionBlock:(CJPayChannelType)type resultType:(CJPayResultType) resultType errCode:(NSString*) errCode {
    self.wakingApp = NO;
    CJ_CALL_BLOCK(self.completionBlock, type, resultType, errCode);
}

- (void)appDidInForeground {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.wakingApp) {
            
            if (self.showLoading) {
                [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeTopLoading];
            }

            NSMutableDictionary *trackDic = [NSMutableDictionary new];
            [trackDic addEntriesFromDictionary:@{
                @"method" : @"wxh5pay",
                @"wake_by_alipay": @"0",
                @"is_install" : [self p_isWXAppInstalled] ? @"1" : @"0",
                @"other_sdk_version" : @""
            }];
            [self trackWithEvent:@"wallet_pay_callback" trackParam:trackDic];
            [self exeCompletionBlock:self.channelType resultType:CJPayResultTypeBackToForeground errCode:@""];
        }
    });
}

@end
