//
//  BDWebCookiePlugin.m
//  BDWebKit
//
//  Created by wealong on 2019/11/17.
//

#import "BDWebCookiePlugin.h"
#import "WKWebView+BDCookie.h"
#import "WKWebView+BDPrivate.h"
#import "BDWebKitSettingsManger.h"
#import "BDWebKitUtil.h"
#import "WKWebView+BDPrivate.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <WebKit/WebKit.h>
#import <objc/runtime.h>

static NSString *const kBDWHookCookieSyncHandleName = @"BDCOOKIESYNC";
static NSString *const kBDWCookieHostKey = @"BD-Cookie-Host";
static NSString *const kBDWebSchemaHandlerRecursiveProperty = @"com.byted.BDWebSchemaHandler";
static NSString *const kIESFalconSchemaHandlerRecursiveProperty = @"com.byted.IESFalconSchemaHandler";

@implementation WKWebViewConfiguration(BDWebCookiePlugin)

- (BDWebCookiePluginSyncMode)bdw_cookiePluginSyncMode
{
    return [objc_getAssociatedObject(self, _cmd) unsignedIntegerValue];
}

- (void)setBdw_cookiePluginSyncMode:(BDWebCookiePluginSyncMode)bdw_cookiePluginSyncMode
{
    objc_setAssociatedObject(self, @selector(bdw_cookiePluginSyncMode), @(bdw_cookiePluginSyncMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation WKWebView (BDWebCookiePlugin)

- (BOOL)bdw_cookieSyncing {
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdw_cookieSyncing:(BOOL)bdw_cookieSyncing {
    objc_setAssociatedObject(self, @selector(bdw_cookieSyncing), @(bdw_cookieSyncing), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@interface BDWebCookiePlugin () <WKScriptMessageHandler>

@property (nonatomic) dispatch_queue_t queue;

@end

@implementation BDWebCookiePlugin

- (IWKPluginHandleResultType)webView:(WKWebView *)webView willInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration {
    
    if (@available(iOS 11.0, *)) {
        switch(configuration.bdw_cookiePluginSyncMode) {
            case BDWebCookiePluginAsyncMode: {
                NSArray<NSHTTPCookie *> *httpCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy];
                webView.bdw_cookieSyncing = YES;
                [configuration.websiteDataStore.httpCookieStore getAllCookies:^(NSArray<NSHTTPCookie *> * _Nonnull wkCookies) {
                    dispatch_barrier_async(self.queue, ^{
                        NSArray *newCookies = [self _unsyncCookiesWithWKCookies:wkCookies httpCookies:httpCookies];
                        if ([newCookies count] == 0) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                webView.bdw_cookieSyncing = NO;
                            });
                        }
                        dispatch_async(dispatch_get_main_queue(), ^{
                            for (NSHTTPCookie *cookie in newCookies) {
                                NSHTTPCookie *newCookie = cookie;
                                if ([BDWebKitSettingsManger bdCookieSecureEnable] && [[BDWebKitSettingsManger bdSecureCookieList] containsObject:cookie.name]) {
                                    NSMutableDictionary *mCookieDict = cookie.properties.mutableCopy;
                                    mCookieDict[NSHTTPCookieSecure] = @(YES);
                                    newCookie = [[NSHTTPCookie alloc] initWithProperties:mCookieDict];
                                }
                                [configuration.websiteDataStore.httpCookieStore setCookie:newCookie completionHandler:nil];
                            }
                            webView.bdw_cookieSyncing = NO;
                        });
                    });
                }];
                break;
            }
            case BDWebCookiePluginSkipSyncMode: break;
            case BDWebCookiePluginSyncAnywayMode:
            default: {
                NSArray<NSHTTPCookie *> *httpCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy];
                for (NSHTTPCookie *cookie in httpCookies) {
                    NSHTTPCookie *newCookie = cookie;
                    if ([BDWebKitSettingsManger bdCookieSecureEnable] && [[BDWebKitSettingsManger bdSecureCookieList] containsObject:cookie.name]) {
                        NSMutableDictionary *mCookieDict = cookie.properties.mutableCopy;
                        mCookieDict[NSHTTPCookieSecure] = @(YES);
                        newCookie = [[NSHTTPCookie alloc] initWithProperties:mCookieDict];
                    }
                    [configuration.websiteDataStore.httpCookieStore setCookie:newCookie completionHandler:nil];
                }
                break;
            }
        }
    }
    else {
        [configuration.userContentController removeScriptMessageHandlerForName:kBDWHookCookieSyncHandleName];
        [configuration.userContentController addScriptMessageHandler:self name:kBDWHookCookieSyncHandleName];
        NSString *jsScript = [NSString stringWithFormat:[self fetchCookieSyncJS], kBDWHookCookieSyncHandleName];
        
        if (jsScript.length > 0) {
            WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
            [configuration.userContentController addUserScript:userScript];
        }
    }
    
    webView.bdw_allowAddCookieInHeader = YES;
    webView.bdw_allowFix30xCORSCookie = YES;
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultObj<WKNavigation *> *)webView:(WKWebView *)webView loadRequest:(NSURLRequest *)request {
    /// force sync cookie in main thread when cookie not finish syncing;
    if(webView.bdw_cookieSyncing) {
        [self syncCookiesForWKWebView:webView];
    }
    if (!webView.bdw_isAddedCookieInHeader &&
         webView.bdw_allowAddCookieInHeader &&
        // http 有安全问题，不在主文档请求带 cookie，加个开关保平安
        (![request.URL.scheme isEqualToString:@"http"] || ![BDWebKitSettingsManger bdCookieSecureEnable])) {
        [self.class syncCookiesWithRequest:request completion:^(NSURLRequest *nRequest) {
            webView.bdw_isAddedCookieInHeader = YES;
            webView.bdw_originRequest = nRequest;
            
            [webView bdw_loadRequest:nRequest];
        }];
        return IWKPluginHandleResultBreak;
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (!webView.bdw_allowAddCookieInHeader || !webView.bdw_allowFix30xCORSCookie) {
        return IWKPluginHandleResultContinue;
    }
    
    NSURL *URL = navigationAction.request.URL;
    NSDictionary *headers = [navigationAction.request allHTTPHeaderFields];
    NSString *cookiesString = [headers btd_stringValueForKey:@"Cookie" default:nil];
    NSString *targetHost = URL.host;
    // 如果 request 带了客户端种的 Cookie, 但是 host 不同，说明发生了 302 且跨域的请求
    if (!BDWK_isEmptyString(targetHost) &&
        !BDWK_isEmptyString(cookiesString) &&
        [cookiesString containsString:kBDWCookieHostKey] &&
        ![cookiesString containsString:targetHost]) {
        BOOL is30x = (targetHost && webView.bdw_originRequest.URL.host &&
                      ![URL.host isEqualToString:webView.bdw_originRequest.URL.host] &&
                      navigationAction.navigationType == WKNavigationTypeOther);
        if (is30x) {
            NSMutableURLRequest *request = [navigationAction.request mutableCopy];
            // Remove recursive flag for SchemeHandler
            if ([[NSURLProtocol propertyForKey:kBDWebSchemaHandlerRecursiveProperty inRequest:request] boolValue]) {
                [NSURLProtocol removePropertyForKey:kBDWebSchemaHandlerRecursiveProperty inRequest:request];
            }
            if ([[NSURLProtocol propertyForKey:kIESFalconSchemaHandlerRecursiveProperty inRequest:request] boolValue]) {
                [NSURLProtocol removePropertyForKey:kIESFalconSchemaHandlerRecursiveProperty inRequest:request];
            }
            [request setValue:nil forHTTPHeaderField:@"Cookie"];
            webView.bdw_isAddedCookieInHeader = NO;
            [webView loadRequest:request];
            decisionHandler(WKNavigationActionPolicyCancel);
            return IWKPluginHandleResultBreak;
        }
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void(^)(WKNavigationResponsePolicy))decisionHandler
{
    // only sync main frame response cookie for http-intercepted-webview
    if (navigationResponse.forMainFrame && [webView bdw_hasInterceptMainFrameRequest]) {
        if ([BDWebKitSettingsManger bdSyncCookieForMainFrameResponse]) {
            NSURL *mainFrameURL = navigationResponse.response.URL;
            if (mainFrameURL && [mainFrameURL.scheme hasPrefix:@"http"]) {
                // sync Response-SetCookie from TTNet or NSURLSession for main frame url
                NSHTTPCookieStorage *httpCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
                NSArray<NSHTTPCookie *> *URLCookies = [httpCookieStorage cookiesForURL:mainFrameURL];
                for (NSHTTPCookie *cookie in URLCookies) {
                    if (@available(iOS 11.0, *)) {
                        [webView.configuration.websiteDataStore.httpCookieStore setCookie:cookie completionHandler:nil];
                    }
                }
            }
        }
    }
    return IWKPluginHandleResultContinue;
}

- (NSString *)fetchCookieSyncJS {
    return @"(function(){try{window.webkit.messageHandlers[\"%@\"].postMessage(window.location.href)}catch(e){}})();";
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:kBDWHookCookieSyncHandleName]) {
        if (![message.body isKindOfClass:[NSString class]]) {
            return ;
        }
        NSURL *url = [NSURL URLWithString:message.body];
        if (!url) {
            return ;
        }
        [message.webView bdw_syncCookie];
        return;
    }
}

+ (void)syncCookiesWithRequest:(NSURLRequest *)request completion:(void (^)(NSURLRequest *))completion {
    if (request.URL == nil){
        if (completion) {
            completion(request);
        }
        return;
    }
    
    NSHTTPCookieStorage *httpCookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    NSArray<NSHTTPCookie *> *URLCookies = [httpCookieStorage cookiesForURL:request.URL];
    
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    NSString *origCookie = [mutableRequest valueForHTTPHeaderField:@"Cookie"]? :@"";
    NSString *newCookie = [origCookie stringByAppendingString:[self _cookiesStringFromCookies:URLCookies]];
    
    if (newCookie.length > 0) {
        if (request.URL.host.length > 0) {
            // 这里种一个标记位标识当前 Cookie 的 host
            newCookie = [newCookie stringByAppendingFormat:@"%@=%@; ", kBDWCookieHostKey, request.URL.host];
        }
        [mutableRequest addValue:newCookie forHTTPHeaderField:@"Cookie"];
    }
    if (completion) {
        completion([mutableRequest copy]);
    }
}

+ (NSString *)_cookiesStringFromCookies:(NSArray<NSHTTPCookie *> *)cookies {
    NSMutableString *str = [[NSMutableString alloc] init];
    
    for (NSHTTPCookie *cookie in cookies) {
        [str appendFormat:@"%@=%@; ", cookie.name, cookie.value];
    }
    
    return [str copy];
}


//MARK: - Sync Cookie Optimize

/// isEqual with properties to ensure expireDate diff.
+ (BOOL)containsCookieWithCookies:(NSArray<NSHTTPCookie *> * _Nonnull)cookies
                           cookie:(NSHTTPCookie * _Nonnull)cookie
{
    if (![cookies containsObject: cookie]) {
        return NO;
    }
    for (id obj in cookies) {
        if (!cookie.properties) {
            continue;
        }
        if ([obj isKindOfClass:[NSHTTPCookie class]] && [((NSHTTPCookie *)obj).properties isEqualToDictionary:cookie.properties]) {
            return YES;
        }
    }
    return NO;
}

/// filter increment cookies
- (NSArray<NSHTTPCookie *> *)_unsyncCookiesWithWKCookies:(NSArray<NSHTTPCookie *> *)wkCookies
                                             httpCookies:(NSArray<NSHTTPCookie *> *)httpCookies
{
    NSMutableArray *result = [[NSArray new] mutableCopy];
    for (NSHTTPCookie *cookie in httpCookies) {
        if (![self.class containsCookieWithCookies:wkCookies cookie:cookie]) {
            [result addObject:cookie];
        }
    }
    return result;
}

- (void)syncCookiesForWKWebView: (WKWebView * _Nonnull)webview
{
    NSArray<NSHTTPCookie *> *httpCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage].cookies copy];
    for (NSHTTPCookie *cookie in httpCookies) {
        NSHTTPCookie *newCookie = cookie;
        if ([BDWebKitSettingsManger bdCookieSecureEnable] && [[BDWebKitSettingsManger bdSecureCookieList] containsObject:cookie.name]) {
            NSMutableDictionary *mCookieDict = cookie.properties.mutableCopy;
            mCookieDict[NSHTTPCookieSecure] = @(YES);
            newCookie = [[NSHTTPCookie alloc] initWithProperties:mCookieDict];
        }
        [webview.configuration.websiteDataStore.httpCookieStore setCookie:newCookie completionHandler:nil];
    }
}

- (dispatch_queue_t)queue {
    if (!_queue) {
        _queue = dispatch_queue_create("bd_webview_sync_cookie_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    return _queue;
}

@end
