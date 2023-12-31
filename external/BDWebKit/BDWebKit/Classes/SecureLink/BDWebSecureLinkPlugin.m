//
//  BDWebSecureLinkPlugin.m
//  BDWebKit
//
//  Created by bytedance on 2020/4/16.
//

#import "BDWebSecureLinkPlugin.h"
#import "BDWebSecureLinkManager.h"
#import "WKWebView+BDSecureLink.h"
#import "WKWebView+BDPrivate.h"
#import <BDWebCore/WKWebView+Plugins.h>
#import <BDAlogProtocol/BDAlogProtocol.h>
#import <TTNetworkManager/TTNetworkManager.h>
#import <BDWebKit/NSObject+BDWRuntime.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDWebCore/IWKUtils.h>
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import "BDWebKitSettingsManger.h"

#define SecureLinkMgrInstance   [BDWebSecureLinkManager shareInstance]
#define NSSTRING_WITH_CONTENT(s) (s && s.length >0)
#define STRING_NOT_EMPTY(s) (s?s:@"")

static NSString* const kBDWebViewSecureLinkVerifyKey = @"seclink_verify";
static NSString* const kBDWebViewSecureLinkTag = @"securelink";
static NSString* const kBDWResponsePolicyHandlerKey = @"bdw_responsePolicyHandler";

typedef NS_ENUM(NSUInteger, BDWebSecureLinkStatus) {
    BDWebSecureLinkStatusCacheSafe,
    BDWebSecureLinkStatusCacheDanger,
    BDWebSecureLinkStatusNotCached
};

NSString * const BDWebSecureLinkResponseNotification = @"BDWebSecureLinkResponseNotification";

@interface WKWebView (BDSecureLinkInner)<BDWebSecureLinkContextProtocol>

@property (nonatomic, strong) NSMutableURLRequest *bdw_firstURLRequest; // 加载的原始请求
@property (nonatomic, strong) NSString *bdw_firstJumpUrl; // 第一次跳转或者重定向落地的链接
@property (nonatomic, strong) NSString *bdw_lastWrapSecOriUrl; // 上一次包装了安全链接的原始链接，用来判断是否是安全链接中间页通过
@property (nonatomic, strong) NSString *bdw_currentRespUrl; //当前response的url，用来区分异步的时候和当前请求的url不是同一个的问题
@property (nonatomic, strong) void (^bdw_decisionHandler)(WKNavigationResponsePolicy) ;
@property (nonatomic, strong) WKNavigationResponse *bdw_cachedNavigationResp;
@property (nonatomic, strong) NSMutableDictionary *bdw_secureBlackDic; // 请求安全jsapi结果，key为url，value为int，0表示安全，1表示有风险
@property (nonatomic, strong) NSMutableDictionary *bdw_secureRiskDic;

@property (nonatomic, weak) BDWebSecureLinkPlugin *bdw_secureLinkPlugin;

@end

@implementation WKWebView(BDSecureLinkInner)

+ (void)load {
    IWKClassSwizzle(self, @selector(goBack), @selector(bdw_secureLinkGoBack));
}

- (WKNavigation *)bdw_secureLinkGoBack {
    self.bdw_lastWrapSecOriUrl = nil;   // 返回表示不通过
    return [self bdw_secureLinkGoBack];
}
 
- (void)setBdw_secureLinkPlugin:(BDWebSecureLinkPlugin *)bdw_secureLinkPlugin {
    [self bdw_attachObject:bdw_secureLinkPlugin forKey:@"bdw_secureLinkPlugin" isWeak:YES];
}

- (BDWebSecureLinkPlugin *)bdw_secureLinkPlugin {
    return [self bdw_getAttachedObjectForKey:@"bdw_secureLinkPlugin" isWeak:YES];
}

- (void)setBdw_secureBlackDic:(NSMutableDictionary *)bdw_secureBlackDic {
    [self bdw_attachObject:bdw_secureBlackDic forKey:@"bdw_secureBlackDic"];
}
 
- (NSMutableDictionary *)bdw_secureBlackDic {
    return [self bdw_getAttachedObjectForKey:@"bdw_secureBlackDic"];
}

- (void)setBdw_secureRiskDic:(NSMutableDictionary *)bdw_secureRiskDic {
    [self bdw_attachObject:bdw_secureRiskDic forKey:@"bdw_secureRiskDic"];
}
 
- (NSMutableDictionary *)bdw_secureRiskDic {
    return [self bdw_getAttachedObjectForKey:@"bdw_secureRiskDic"];
}

- (void)setBdw_firstURLRequest:(NSMutableURLRequest *)bdw_firstURLRequest {
    [self bdw_attachObject:bdw_firstURLRequest forKey:@"bdw_firstURLRequest"];
}

- (NSMutableURLRequest *)bdw_firstURLRequest {
    return [self bdw_getAttachedObjectForKey:@"bdw_firstURLRequest"];
}

- (void)setBdw_firstJumpUrl:(NSString *)bdw_firstJumpUrl {
    [self bdw_attachObject:bdw_firstJumpUrl forKey:@"bdw_firstJumpUrl"];
}

- (NSString *)bdw_firstJumpUrl {
    return [self bdw_getAttachedObjectForKey:@"bdw_firstJumpUrl"];
}

- (void)setBdw_lastWrapSecOriUrl:(NSString *)bdw_lastWrapSecOriUrl {
    [self bdw_attachObject:bdw_lastWrapSecOriUrl forKey:@"bdw_lastWrapSecOriUrl"];
}

- (NSString *)bdw_lastWrapSecOriUrl {
    return [self bdw_getAttachedObjectForKey:@"bdw_lastWrapSecOriUrl"];
}

- (void)setBdw_currentRespUrl:(NSString *)bdw_currentRespUrl {
    [self bdw_attachObject:bdw_currentRespUrl forKey:@"bdw_currentRespUrl"];
}

- (NSString *)bdw_currentRespUrl {
    return [self bdw_getAttachedObjectForKey:@"bdw_currentRespUrl"];
}

- (void)setBdw_decisionHandler:(void (^)(WKNavigationResponsePolicy))bdw_decisionHandler {
    [self bdw_attachObject:bdw_decisionHandler forKey:@"bdw_decisionHandler"];
}

- (void (^)(WKNavigationResponsePolicy))bdw_decisionHandler {
    return [self bdw_getAttachedObjectForKey:@"bdw_decisionHandler"];
}

- (void)setBdw_cachedNavigationResp:(WKNavigationResponse *)bdw_cachedNavigationResp {
    [self bdw_attachObject:bdw_cachedNavigationResp forKey:@"bdw_cachedNavigationResp"];
}

- (WKNavigationResponse *)bdw_cachedNavigationResp {
    return [self bdw_getAttachedObjectForKey:@"bdw_cachedNavigationResp"];
}

@end

@implementation WKWebView (BDWebSecLinkContext)
#pragma <BDWebSecureLinkRefresh>
-(void)bdw_clearSecLinkContext {
    [self setBdw_firstURLRequest:nil];
}

-(BOOL)bdw_isSeclinkInstalled {
    return self.bdw_secureLinkPlugin != nil;
}
@end

@interface BDWebSecureLinkPlugin ()

@property (nonatomic, strong) NSString *wrapingLink;    // 被包装进secureLink的链接

/// 开启功能必填，产品id，头条13，商业化广告1402，抖音:1128，tiktok:1180，musically:1233，火山：1112
@property (nonatomic, assign) int aid;

/// 开启功能必填，scene 场景，如私信：'im'，扫一扫：'qrcode'
@property (nonatomic, strong) NSString *scene;

/// 开启功能选填，默认为中文zh，lang 语言，中文：zh，英文：en，繁体：zh-Hant
@property (nonatomic, strong) NSString *lang;

@end

@implementation BDWebSecureLinkPlugin

+ (void)injectToWebView:(WKWebView *)webview withAid:(int)aid scene:(NSString *)scene lang:(NSString *)lang {
    if (!webview || !NSSTRING_WITH_CONTENT(scene) || !NSSTRING_WITH_CONTENT(lang)) {
        return;
    }
    BDWebSecureLinkPlugin *plugin = BDWebSecureLinkPlugin.new;
    [webview IWK_loadPlugin:plugin];
    webview.bdw_secureLinkPlugin = plugin;
    
    plugin.aid = aid;
    plugin.scene = scene;
    plugin.lang = lang;
    webview.bdw_secureBlackDic = [[NSMutableDictionary alloc] init];
    webview.bdw_secureRiskDic = [[NSMutableDictionary alloc] init];
}

+ (void)configSecureLinkDomain:(NSString *)domain {
    [SecureLinkMgrInstance configSecureLinkDomain:domain];
}

+ (void)updateCustomSettingModel:(BDWebSecureLinkCustomSetting *)settingModel {
    SecureLinkMgrInstance.customSetting = settingModel;
}

+ (void)secureGoBackStepByStep:(WKWebView *)webView reachEndBlock:(void(^)(void))block {
    [self secureGoBackOneStep:webView reachEndBlock:block];
}

+ (void)secureGoBackOneStep:(WKWebView *)webView reachEndBlock:(void(^)(void))block {
    if (!webView.bdw_secureLinkPlugin) {
        if (webView.canGoBack) {
            [webView goBack];
        } else {
            block();
        }
        return;
    }

    if (webView.backForwardList.backList && webView.backForwardList.backList.count > 0) {
        WKBackForwardListItem *backItem = webView.backForwardList.backItem;
        NSString *backItemUrlString = backItem.URL.absoluteString;
        
        NSNumber *resultValue = [webView.bdw_secureBlackDic objectForKey:backItemUrlString];
        [webView goBack];
        webView.bdw_currentRespUrl = backItemUrlString;
        
        if ([SecureLinkMgrInstance isSecureLink:backItemUrlString] || (resultValue &&  [resultValue intValue] == 1)) {
            // 如果上一页还是安全中转页 或者 是危险链接，还得再往前跳
            float delayTime = 0.01;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self secureGoBackOneStep:webView reachEndBlock:block];
            });
        } else if (!resultValue ) {
            // 未知
            [webView.bdw_secureLinkPlugin asyncRequreSecureLinkCheck:backItemUrlString webView:webView flag:0];
            return;
        } else {
            // 安全
            return;
        }
    } else {
        block();
    }
}

- (IWKPluginObjectPriority)priority {
    return IWKPluginObjectPriorityVeryHigh + 1; //如果校验不通过就不需要处理对应的回调
}

#pragma mark - WKNavigationDelegate

- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request {
    // 如果开启了开关，则在第一次会使用安全链接
    
    BDALOG_PROTOCOL_DEBUG_TAG(kBDWebViewSecureLinkTag, @"loadRequest,url: %@, bdw_switchOnFirstRequestSecureCheck:%d"
                              ,request.URL.absoluteString
                              ,webView.bdw_switchOnFirstRequestSecureCheck);
    
    if (webView.bdw_firstURLRequest || !webView.bdw_switchOnFirstRequestSecureCheck) {
        return IWKPluginHandleResultContinue;
    }
    webView.bdw_firstURLRequest = [request mutableCopy];
    
    if ([self isUrlInWhiteList:request.URL.absoluteString webView:webView]) {
        BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"url in whiteList");
        return IWKPluginHandleResultContinue;
    }
    if ([SecureLinkMgrInstance isLinkPassForSecureLinkServiceErr]) {
        BDALOG_PROTOCOL_WARN_TAG(kBDWebViewSecureLinkTag, @"check pass for error ");
        return IWKPluginHandleResultContinue;
    }
    
    BDWebSecureLinkStatus cacheStatus = [self checkUrlSecurityInCache:request.URL.absoluteString webView:webView];
    if (cacheStatus == BDWebSecureLinkStatusCacheSafe) {
        [BDTrackerProtocol eventV3:@"secure_link_cache_safe" params:@{@"url":STRING_NOT_EMPTY(request.URL.absoluteString)}];
        BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"loadRequest ,url in safe cache");
        return IWKPluginHandleResultContinue;
    } else {
        BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"loadRequest need secure check");
        NSString *wrapUrl = [self wrapSecureLinkWithOriUrl:webView.bdw_firstURLRequest.URL.absoluteString];
        IWKPluginHandleResultObj *result = [IWKPluginHandleResultObj new];
        result.flow = IWKPluginHandleResultFlowBreak;
        result.value = [self loadLink:wrapUrl withWebView:webView];
        return result;
    }
}


- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    BDALOG_PROTOCOL_DEBUG_TAG(kBDWebViewSecureLinkTag, @"decidePolicyForNavigationResponse, url: %@ ,mime type: %@",navigationResponse.response.URL.absoluteString ,navigationResponse.response.MIMEType);
    
    webView.bdw_currentRespUrl = navigationResponse.response.URL.absoluteString;
    if (webView.bdw_secureLinkCheckRedirectType == BDSecureLinkCheckRedirectTypeDisable) {
        return IWKPluginHandleResultContinue;
    }
    
    if (webView.bdw_cachedNavigationResp == navigationResponse) {
        BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"pass this time because last secure check is in progress");
        webView.bdw_cachedNavigationResp = nil;
        return IWKPluginHandleResultContinue;
    }
    if ([self isUrlInWhiteList:navigationResponse.response.URL.absoluteString webView:webView]) {
        BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"url in whiteList");
        return IWKPluginHandleResultContinue;
    }
    if ([SecureLinkMgrInstance isLinkPassForSecureLinkServiceErr]) {
        BDALOG_PROTOCOL_WARN_TAG(kBDWebViewSecureLinkTag, @"check pass for error ");
        return IWKPluginHandleResultContinue;
    }
    
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpURLResponse = (NSHTTPURLResponse *)navigationResponse.response;
        NSInteger statusCode = httpURLResponse.statusCode;
        BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"decidePolicyForNavigationResponse, status code:%ld ",(long)statusCode );
        
        if (statusCode == 200 && navigationResponse.forMainFrame) {
            NSString *responseUrl = navigationResponse.response.URL.absoluteString;
            if ([SecureLinkMgrInstance isSecureLink:responseUrl]) {
                return IWKPluginHandleResultContinue;
            }
            
            // 返回的response是源链接后第一个落地链接
            int flag = 0;
            if (!NSSTRING_WITH_CONTENT(webView.bdw_firstJumpUrl)) {
                flag = 1;
                webView.bdw_firstJumpUrl = responseUrl;
            }
            NSString *riskValue = [webView.bdw_secureRiskDic objectForKey:responseUrl];
            if (STRING_NOT_EMPTY(webView.bdw_lastWrapSecOriUrl) && [self compareLinkIsEqual:responseUrl with:webView.bdw_lastWrapSecOriUrl]
                && ![riskValue isEqualToString:@"9"]
                ) {
                // 此时得到的数据和上一次wrap seclink的oriUrl是一样的，可以认为是确认进入，此时不需要请求seclinkapi，避免重复进入
                // 增加风险值判断逻辑防止兼容确认进入的逻辑导致高风险页面拦截被绕过
                webView.bdw_lastWrapSecOriUrl = nil;
                // 至少发送一次verify，决定是否要出banner
                [self requestSecureCheck:responseUrl webView:webView flag:flag handleBlock:nil];
                return IWKPluginHandleResultContinue;
            }
            webView.bdw_lastWrapSecOriUrl = nil;
            
            // 返回的response是源链接
            if ([self compareLinkIsEqual:responseUrl with:webView.bdw_firstURLRequest.URL.absoluteString]) {
                // 中转后安全链接重新发起的时候可能会多一个 "/" 。。。
                // 如果获取了原链接的response，说明原链接是白名单或者是用户点击了确认访问进入，此时cache住
                [SecureLinkMgrInstance cacheSecureLink:webView.bdw_firstURLRequest.URL.absoluteString];
                // 至少发送一次verify，决定是否要出banner
                [self requestSecureCheck:responseUrl webView:webView flag:flag handleBlock:nil];
                return IWKPluginHandleResultContinue;
            }
            
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"need request secure check ,check type : %lu",(unsigned long)webView.bdw_secureLinkCheckRedirectType);
            
            
            if (webView.bdw_strictMode && !webView.bdw_hasClick) {
                BOOL shouldIntercept = YES;
                if ([SecureLinkMgrInstance.customSetting.delegate respondsToSelector:@selector(shouldInterceptFirstJump:withResponse:)]) {
                    shouldIntercept = [SecureLinkMgrInstance.customSetting.delegate shouldInterceptFirstJump:webView.bdw_firstURLRequest.URL withResponse:navigationResponse.response.URL];
                }
                
                if (shouldIntercept) {
                    // 同步操作的话需要先中断plugin的加载，然后请求，请求结果回来后再重新执行
                    [self strictSyncRequreSecureLinkCheck:responseUrl webView:webView navigationResponse:navigationResponse flag:flag decisionHandler:decisionHandler];
                    return IWKPluginHandleResultBreak;
                }
                
            }
                
            
            if (webView.bdw_secureLinkCheckRedirectType == BDSecureLinkCheckRedirectTypeSync) {
                // 同步操作的话需要先中断plugin的加载，然后请求，请求结果回来后再重新执行
                [self syncRequreSecureLinkCheck:responseUrl webView:webView navigationResponse:navigationResponse flag:flag decisionHandler:decisionHandler];
                return IWKPluginHandleResultBreak;
            } else {
                // 异步去check securelink
                [self asyncRequreSecureLinkCheck:responseUrl webView:webView flag:flag];
            }
            

        }
    }
    
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    [navigation bdw_attachObject:webView.URL.absoluteString forKey:@"securelinkchcek_url"];
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSString *URL = [navigation bdw_getAttachedObjectForKey:@"securelinkchcek_url"];
    if ([SecureLinkMgrInstance isSecureLink:URL]) {
        [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_FailNavigation errorCode:error.code errorMsg:[self errorMsgForError:error]];
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSString *URL = [navigation bdw_getAttachedObjectForKey:@"securelinkchcek_url"];
    if ([SecureLinkMgrInstance isSecureLink:URL]) {
        [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_FailProvisionalNavigation errorCode:error.code errorMsg:[self errorMsgForError:error]];
    }
    return IWKPluginHandleResultContinue;
}

#pragma mark - logic

- (BOOL)compareLinkIsEqual:(NSString *)linkA with:(NSString *)linkB {
    if ([linkA isEqualToString:linkB]) {
        return YES;
    }
    if ([[linkA substringFromIndex:linkA.length-1] isEqualToString:@"/"]) {
        return [[linkA substringToIndex:linkA.length-1] isEqualToString:linkB];
    } else if ([[linkB substringFromIndex:linkB.length-1] isEqualToString:@"/"]) {
        return [[linkB substringToIndex:linkB.length-1] isEqualToString:linkA];
    }
    return NO;
}

- (NSString *)errorMsgForError:(NSError *)error {
    NSString *errorMsg = [NSString stringWithFormat:@"error domain:%@, reason:%@",error.domain,STRING_NOT_EMPTY(error.localizedFailureReason)];
    return errorMsg;
}

- (BOOL)isUrlInWhiteList:(NSString *)url webView:(WKWebView *)webView {
    NSURL *urlObj = [NSURL URLWithString:url];
//    if (!urlObj || !urlObj.scheme || !urlObj.host) {
    //避免误伤仅检查data schema
    if (!urlObj || !urlObj.scheme || [urlObj.scheme.lowercaseString isEqualToString:@"data"]) {
        return NO;
    }
    if (![urlObj.scheme.lowercaseString hasPrefix:@"http"]) {
        // 只校验http和https
        return YES;
    }
    
    NSString *host = urlObj.host;
    NSArray *whiteList = [webView.bdw_secureCheckHostAllowList copy];
    for (NSString *item in whiteList) {
        if ([item isKindOfClass:NSString.class] && item.length > 0) {
            if ([host isEqualToString:item]) {
                return YES;
            }
        }
    }
    
    return [BDWebKitSettingsManger bdInSeclinkWhitelist:urlObj];
}

// 异步校验
- (void)asyncRequreSecureLinkCheck:(NSString *)responseUrl webView:(WKWebView *)webView flag:(BOOL)flag {
    [self requestSecureCheck:responseUrl webView:webView flag:flag handleBlock:^(NSError *error, id jsonObj) {
        if (error) {
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"async response error , info : %@ ",error);
        } else if ([jsonObj isKindOfClass:NSDictionary.class]) {
            if ([jsonObj objectForKey:@"errno"]) {
                BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"async response type error , jsonObj : %@ ",jsonObj);
                NSInteger errorNo = [[jsonObj objectForKey:@"errno"] integerValue];
                NSString *errorMsg = [jsonObj objectForKey:@"errmsg"];
                [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_ApiResultError errorCode:errorNo errorMsg:errorMsg];
                return ;
            }
            
            NSInteger risk = [[jsonObj objectForKey:@"risk"] integerValue];
            BOOL showMidPage = [[jsonObj objectForKey:@"show_mid_page"] boolValue];
            NSInteger safeDuration = [[jsonObj objectForKey:@"safe_duration"] integerValue];
            [SecureLinkMgrInstance updateCacheDuration:safeDuration];
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"response succeed , risk : %ld , showMidPage : %d ",(long)risk,showMidPage);
            
            [webView.bdw_secureBlackDic setValue: showMidPage?@(1):@(0) forKey:responseUrl];
            NSString *riskString = [[jsonObj objectForKey:@"risk"] stringValue];
            [webView.bdw_secureRiskDic setValue: riskString forKey:responseUrl];
            
            if (![self compareLinkIsEqual:responseUrl with:webView.bdw_currentRespUrl]) {
                BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"async response not match, response url : %@ , webview url : %@ ",STRING_NOT_EMPTY(responseUrl),STRING_NOT_EMPTY(webView.URL.absoluteString));
            } else {
                [self handleSecureLinkCheck:webView oriUrl:responseUrl risk:risk showMidPage:showMidPage needPopPreviousPage:YES];
            }
        } else {
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"async response type error , jsonObj : %@ ",jsonObj);
        }
    }];
}


// 同步校验
- (void)syncRequreSecureLinkCheck:(NSString *)responseUrl webView:(WKWebView *)webView navigationResponse:(WKNavigationResponse *)navigationResponse flag:(BOOL)flag decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    [self requestSecureCheck:responseUrl webView:webView flag:flag handleBlock:^(NSError *error, id jsonObj) {
        if (error) {
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"sync response error , info : %@ ",error);
            [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_ApiRequestFail errorCode:error.code errorMsg:[self errorMsgForError:error]];
            [self checkAndFireHandlerIfNeededFrom:webView decidePolicyForNavigationResponse:navigationResponse forceReloadToSecurePage:nil];
        } else if ([jsonObj isKindOfClass:NSDictionary.class]) {
            if ([jsonObj objectForKey:@"errno"]) {
                NSInteger errorNo = [[jsonObj objectForKey:@"errno"] integerValue];
                NSString *errorMsg = [jsonObj objectForKey:@"errmsg"];
                BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"response result fail, errorCode : %ld , errorMsg : %@ ",(long)errorNo,STRING_NOT_EMPTY(errorMsg));
                [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_ApiResultError errorCode:errorNo errorMsg:errorMsg];
                [self checkAndFireHandlerIfNeededFrom:webView decidePolicyForNavigationResponse:navigationResponse forceReloadToSecurePage:nil];
                return ;
            }
            
            NSInteger risk = [[jsonObj objectForKey:@"risk"] integerValue];
            BOOL showMidPage = [[jsonObj objectForKey:@"show_mid_page"] boolValue];
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"response succeed , risk : %ld , showMidPage : %d ",(long)risk,showMidPage);
            
            [webView.bdw_secureBlackDic setValue: showMidPage?@(1):@(0) forKey:responseUrl];
            NSString *riskString = [[jsonObj objectForKey:@"risk"] stringValue];
            [webView.bdw_secureRiskDic setValue: riskString forKey:responseUrl];
            
            if (showMidPage) {
                // 需要展示中间页，需要cancel掉原来的链路，然后重新load中间页
                [self checkAndFireHandlerIfNeededFrom:webView decidePolicyForNavigationResponse:navigationResponse forceReloadToSecurePage:navigationResponse.response.URL.absoluteString];
            } else {
                // 不需要展示中间页，执行原来的流程
                [self checkAndFireHandlerIfNeededFrom:webView decidePolicyForNavigationResponse:navigationResponse forceReloadToSecurePage:nil];
            }
        } else {
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"sync response type error , jsonObj : %@ ",jsonObj);
            [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_ApiResultJsonTypeError errorCode:-1 errorMsg:@"result is not a json dic type"];
            [self checkAndFireHandlerIfNeededFrom:webView decidePolicyForNavigationResponse:navigationResponse forceReloadToSecurePage:nil];
        }
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SecureLinkMgrInstance.customSetting.syncCheckTimeLimit * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (webView.bdw_decisionHandler) {
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"sync request overtime");
            [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_ApiRequestOverTime errorCode:-1 errorMsg:@"sync request overtime"];
        }
        [self checkAndFireHandlerIfNeededFrom:webView decidePolicyForNavigationResponse:navigationResponse forceReloadToSecurePage:nil];
    });
    [self bindHandleBlock:decisionHandler toWebView:webView];
}


+ (NSString*)URLString:(NSString *)URLStr appendCommonParams:(NSDictionary *)commonParams
{
    if ([commonParams count] == 0 || !URLStr) {
        return URLStr;
    }
    URLStr = [URLStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSString *sep = @"?";
    if ([URLStr rangeOfString:@"?"].location != NSNotFound) {
        sep = @"&";
    }
    
    NSMutableString *query = [NSMutableString new];
    for (NSString *key in [commonParams allKeys]) {
        [query appendFormat:@"%@%@=%@", sep, key, commonParams[key]];
        sep = @"&";
    }
    
    NSString *result = [NSString stringWithFormat:@"%@%@", URLStr, query];
    if ([NSURL URLWithString:result]) {
        return result;
    }
    
    if ([NSURL URLWithString:URLStr]) {
        NSString *escapted_query = [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (escapted_query) {
            // if the query contains 'non-escape' character, the query is invalid and returns nil.
            NSString *result = [NSString stringWithFormat:@"%@%@", URLStr, escapted_query];
            if ([NSURL URLWithString:result]) {
                return result;
            }
        }
    }

    // The URLStr is invalid. It may contain space, or 'non-escape' character.
    return [result stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}


// 同步校验(new)
- (void)strictSyncRequreSecureLinkCheck:(NSString *)responseUrl webView:(WKWebView *)webView navigationResponse:(WKNavigationResponse *)navigationResponse flag:(BOOL)flag decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    
    [self bindHandleBlock:decisionHandler toWebView:webView];
    
    dispatch_semaphore_t sem = dispatch_semaphore_create(0);

    int64_t ts = [[NSDate date] timeIntervalSince1970];
    NSString *aid = [NSString stringWithFormat:@"%d",self.aid];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:@{@"aid":aid
                                                                                     ,@"scene":STRING_NOT_EMPTY(self.scene)
                                                                                     ,@"target":STRING_NOT_EMPTY(responseUrl)
                                                                                     ,@"ts":@(ts)
                                                                                     ,@"flag":@(flag)
                                                                                     ,@"sync":@(YES)
                                                                                    }];
    NSString *token = [NSString stringWithFormat:@"%@|%@|%@|%@|%@",aid,self.scene,responseUrl,[NSString stringWithFormat:@"%ld",ts],kBDWebViewSecureLinkVerifyKey];
    [params setObject:[token btd_md5String] forKey:@"token"];
    
    NSString *baseSecureCheckURL = [SecureLinkMgrInstance seclinkApi];
    
    NSURL *url = [NSURL URLWithString:baseSecureCheckURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"application/json; encoding=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    request.HTTPMethod = @"POST";
    
    NSError *error;
    __block NSString *seclink = nil;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:params options:0 error:&error];
    @weakify(self)
    @weakify(webView)
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        @strongify(self)
        @strongify(webView)
        if (error) {
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"sync response error , info : %@ ",error);
            [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_ApiRequestFail errorCode:error.code errorMsg:[self errorMsgForError:error]];
            [self postResponseNotification:nil
                                     error:error
                                   webview:webView];
            dispatch_semaphore_signal(sem);
        } else {
            NSDictionary *jsonObj = [NSJSONSerialization JSONObjectWithData:data
                                                                         options:NSJSONReadingAllowFragments
                                                                           error:&error];
            [self postResponseNotification:jsonObj
                                     error:error
                                   webview:webView];
            if ([jsonObj isKindOfClass:NSDictionary.class]) {
                if ([jsonObj objectForKey:@"errno"]) {
                    NSInteger errorNo = [[jsonObj objectForKey:@"errno"] integerValue];
                    NSString *errorMsg = [jsonObj objectForKey:@"errmsg"];
                    BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"response result fail, errorCode : %ld , errorMsg : %@ ",(long)errorNo,STRING_NOT_EMPTY(errorMsg));
                    [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_ApiResultError errorCode:errorNo errorMsg:errorMsg];
                    dispatch_semaphore_signal(sem);
                    return ;
                }
                
                NSInteger risk = [[jsonObj objectForKey:@"risk"] integerValue];
                BOOL showMidPage = [[jsonObj objectForKey:@"show_mid_page"] boolValue];
                BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"response succeed , risk : %ld , showMidPage : %d ",(long)risk,showMidPage);
                
                [webView.bdw_secureBlackDic setValue: showMidPage?@(1):@(0) forKey:responseUrl];
                NSString *riskString = [[jsonObj objectForKey:@"risk"] stringValue];
                [webView.bdw_secureRiskDic setValue: riskString forKey:responseUrl];
                
                if (showMidPage) {
                    // 需要展示中间页，需要cancel掉原来的链路，然后重新load中间页
                    void (^handler)(WKNavigationResponsePolicy) = [self fetchAndCleanDecisionHandlerFromWebView:webView];
                    NSString* forceReloadToSecurePage = navigationResponse.response.URL.absoluteString;
                    if (forceReloadToSecurePage) {
                        // 强制跳中间页
                        if (handler) {
                            handler(WKNavigationResponsePolicyCancel);
                        }
                        seclink = [self wrapQuickMiddlePage:forceReloadToSecurePage risk:risk];
                        
                        dispatch_semaphore_signal(sem);
                        return;
                    }
                    

                }
                dispatch_semaphore_signal(sem);
            } else {
                BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"sync response type error , jsonObj : %@ ",jsonObj);
                [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_ApiResultJsonTypeError errorCode:-1 errorMsg:@"result is not a json dic type"];
                dispatch_semaphore_signal(sem);
            }
        }
            
    }];
    [task resume];
    dispatch_semaphore_wait(sem, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(SecureLinkMgrInstance.customSetting.syncCheckTimeLimit * NSEC_PER_SEC)));
    
    if (seclink != nil) {
        [self loadLink:seclink withWebView:webView];
    }else {
        if (webView.bdw_decisionHandler) {
            BDALOG_PROTOCOL_INFO_TAG(kBDWebViewSecureLinkTag, @"sync request overtime %d",(int64_t)(SecureLinkMgrInstance.customSetting.syncCheckTimeLimit * NSEC_PER_SEC));
            [SecureLinkMgrInstance onTriggerSecureLinkError:BDWebSecureLinkErrorType_ApiRequestOverTime errorCode:-1 errorMsg:@"sync request overtime"];
        }
        [self checkAndFireHandlerIfNeededFrom:webView decidePolicyForNavigationResponse:navigationResponse forceReloadToSecurePage:nil];
    }
    

    
}

- (void)bindHandleBlock:(void (^)(WKNavigationResponsePolicy))decisionHandler toWebView:(WKWebView *)webView {
    @synchronized (self) {
        webView.bdw_decisionHandler = [decisionHandler copy];
    }
}

- (void (^)(WKNavigationResponsePolicy))fetchAndCleanDecisionHandlerFromWebView:(WKWebView *)webView {
    @synchronized (self) {
        id cachedHandler = webView.bdw_decisionHandler;
        webView.bdw_decisionHandler = nil;
        return [cachedHandler copy];
    }
}

- (void)checkAndFireHandlerIfNeededFrom:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse forceReloadToSecurePage:(NSString *)forceReloadToSecurePage {
    void (^handler)(WKNavigationResponsePolicy) = [self fetchAndCleanDecisionHandlerFromWebView:webView];
    if (forceReloadToSecurePage) {
        // 强制跳中间页
        if (handler) {
            handler(WKNavigationResponsePolicyCancel);
        }
        [self reloadSecureWrapWithOriUrl:forceReloadToSecurePage webView:webView];
        return;
    }
    
    // 不需要跳中间页的判断一下之前有没有执行即可
    if (handler) {
        webView.bdw_cachedNavigationResp = navigationResponse;
        [webView.navigationDelegate webView:webView decidePolicyForNavigationResponse:navigationResponse decisionHandler:handler];
    }
}

- (BDWebSecureLinkStatus)checkUrlSecurityInCache:(NSString *)url webView:(WKWebView *)webView {
    if ([SecureLinkMgrInstance isLinkInSecureLinkCache:url]) {
        return BDWebSecureLinkStatusCacheSafe;
    } else if ([SecureLinkMgrInstance isLinkInDangerLinkCache:url]) {
        return BDWebSecureLinkStatusCacheDanger;
    } else {
        return BDWebSecureLinkStatusNotCached;
    }
}

- (void)requestSecureCheck:(NSString *)url webView:(WKWebView *)webView flag:(BOOL)flag handleBlock:(TTNetworkJSONFinishBlock)handleBlock {
    NSString *ts = [NSString stringWithFormat:@"%.0f",[[NSDate date] timeIntervalSince1970]];
    NSString *aid = [NSString stringWithFormat:@"%d",self.aid];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:@{@"aid":aid
                                                                                     ,@"scene":STRING_NOT_EMPTY(self.scene)
                                                                                     ,@"target":STRING_NOT_EMPTY(url)
                                                                                     ,@"ts":ts
                                                                                     ,@"flag":@(flag)
                                                                                    }];
    NSString *token = [NSString stringWithFormat:@"%@|%@|%@|%@|%@",aid,self.scene,url,ts,kBDWebViewSecureLinkVerifyKey];
    [params setObject:[token btd_md5String] forKey:@"token"];
    
    NSString *baseSecureCheckURL = [SecureLinkMgrInstance seclinkApi];
    @weakify(self)
    @weakify(webView)
    [[TTNetworkManager shareInstance] requestForJSONWithURL:baseSecureCheckURL
                                                     params:params
                                                     method:@"POST"
                                           needCommonParams:YES
                                                   callback:^(NSError *error, id jsonObj) {
        @strongify(self)
        @strongify(webView)
        if (handleBlock) {
            handleBlock(error, jsonObj);
        }
        [self postResponseNotification:jsonObj error:error webview:webView];
    }];
}

//url 风险值。0 白名单，3 未知，5 可疑，9 黑名单。
- (void)handleSecureLinkCheck:(WKWebView *)webView oriUrl:(NSString *)oriUrl risk:(NSInteger)risk showMidPage:(BOOL)showMidPage needPopPreviousPage:(BOOL)needPopPreviousPage {
    if (!showMidPage) {
        return;
    } else {
        [self handleDangerOrGrayUrl:oriUrl isDanger:NO webView:webView needPopPreviousPage:needPopPreviousPage];
    }
}

- (void)handleDangerOrGrayUrl:(NSString *)oriUrl isDanger:(BOOL)isDanger webView:(WKWebView *)webView needPopPreviousPage:(BOOL)needPopPreviousPage {
    if (needPopPreviousPage) {
        // 移除已经load的页面
        [webView goBack];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self reloadSecureWrapWithOriUrl:oriUrl webView:webView];
    });
}

- (NSString *)wrapSecureLinkWithOriUrl:(NSString *)oriUrl {
    NSString *secureLink = [SecureLinkMgrInstance wrapToSecureLink:oriUrl aid:self.aid scene:self.scene lang:self.lang];
    return secureLink;
}

- (NSString *)wrapQuickMiddlePage:(NSString *)oriUrl risk:(int)risk {
    NSString *secureLink = [SecureLinkMgrInstance wrapToQuickMiddlePage:oriUrl aid:self.aid scene:self.scene lang:self.lang risk:risk];
    return secureLink;
}

- (WKNavigation *)loadLink:(NSString *)link withWebView:(WKWebView *)webView {
    if (webView.bdw_firstURLRequest) {
        NSMutableURLRequest *mutableRequest = [webView.bdw_firstURLRequest mutableCopy];
        mutableRequest.URL = [NSURL URLWithString:link];
        return [webView bdw_loadRequest:mutableRequest];
    } else {
        NSURL *url = [NSURL URLWithString:link];
        return [webView bdw_loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

- (WKNavigation *)reloadSecureWrapWithOriUrl:(NSString *)oriUrl webView:(WKWebView *)webView{
    webView.bdw_lastWrapSecOriUrl = oriUrl;
    NSString *secureLink = [self wrapSecureLinkWithOriUrl:oriUrl];
    BDALOG_PROTOCOL_DEBUG_TAG(kBDWebViewSecureLinkTag, @"wrap secure link : %@",secureLink);
    
    return [self loadLink:secureLink withWebView:webView];
}

- (void)postResponseNotification:(id)jsonObj
                           error:(NSError *)error
                         webview:(WKWebView *)webview
{
    NSMutableDictionary *info = [[NSMutableDictionary alloc] initWithCapacity:2];
    info[@"jsonObj"] = jsonObj;
    info[@"error"] = error;
    [[NSNotificationCenter defaultCenter] postNotificationName:BDWebSecureLinkResponseNotification
                                                        object:webview
                                                      userInfo:[info copy]];
}

@end
