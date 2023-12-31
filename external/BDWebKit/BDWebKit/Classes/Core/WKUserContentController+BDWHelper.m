//
//  WKUserContentController+BDWHelper.m
//  BDWebKit
//
//  Created by caiweilong on 2020/4/2.
//

#import "WKUserContentController+BDWHelper.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <BDWebCore/IWKUtils.h>
#import "NSObject+BDWRuntime.h"

static NSString *const kBDWHookConsoleLogHandleName = @"consoleLog";
static NSString *const kBDWHookCookieSyncHandleName = @"TTCOOKIESYNC";

@interface WKUserContentController (_Private)
- (NSMutableDictionary<NSString *, WKScriptMessageHandler> *)bdw_scriptCallbackHandleDict;
+ (NSString *)bdw_cookiesScriptFromCookies:(NSArray<NSHTTPCookie *> *)cookies;
@end

#pragma mark - WKScriptMessageHandler

@interface BDWWeakScriptMessageHandler : NSObject<WKScriptMessageHandler>
@property (nonatomic, weak) WKUserContentController *delegate;
@end

@implementation BDWWeakScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    if ([message.name isEqualToString:kBDWHookCookieSyncHandleName]) {
        if (![message.body isKindOfClass:[NSString class]]) {
            return ;
        }
        NSURL *url = [NSURL URLWithString:message.body];
        if (!url) {
            return ;
        }
        NSArray<NSHTTPCookie *> *URLCookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies];
        if (URLCookies.count <= 0) {
            return ;
        }
        NSString *jsScript = [WKUserContentController bdw_cookiesScriptFromCookies:URLCookies];
        [message.webView evaluateJavaScript:jsScript completionHandler:nil];
        return;
    }
    WebViewLogHandler handle = [[self.delegate bdw_scriptCallbackHandleDict] objectForKey:message.name];
    if (handle) {
        handle(message);
    }
}

@end

static const void *kBDWWeakScriptHandleKey = &kBDWWeakScriptHandleKey;
static const void *kBDWWKScriptCallBackHandleDictKey = &kBDWWKScriptCallBackHandleDictKey;

@implementation WKUserContentController(BDWHelper)

+(void)load {
    IWKClassSwizzle(self, @selector(addUserScript:), @selector(bdw_addUserScript:));
}

#pragma mark - methods

- (void)bdw_addUserScript:(WKUserScript *)userScript {
    if ([[self bdw_getAttachedObjectForKey:@"forbiddenAddScript"] boolValue]) {
        return;
    }
    [self bdw_addUserScript:userScript];
}

- (void)bdw_hookCookieSync {
    [self removeScriptMessageHandlerForName:kBDWHookCookieSyncHandleName];
    [self addScriptMessageHandler:[self bdw_weakScriptHandle] name:kBDWHookCookieSyncHandleName];
    NSString *jsScript = [NSString stringWithFormat:@"(function(){try{window.webkit.messageHandlers[\"%@\"].postMessage(window.location.href)}catch(e){}})();", kBDWHookCookieSyncHandleName];
    
    if (jsScript.length > 0) {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self addUserScript:userScript];
    }
}

- (void)bdw_installHookConsoleLog:(WebViewLogHandler)handle {
    
    [self bdw_register:kBDWHookConsoleLogHandleName handle:^(WKScriptMessage * _Nonnull msg) {
        if (handle) {
            handle(msg.body);
        }
    }];
    NSString *jsScript = [self.class fetchHookConsoleLog];
    
    if (jsScript.length > 0) {
        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:jsScript injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self addUserScript:userScript];
    }
}

//添加script方法
- (void)bdw_register:(NSString *)handelName handle:(WKScriptMessageHandler)handle {
    [self bdw_unregister:handelName];
    [self removeScriptMessageHandlerForName:handelName];
    [self addScriptMessageHandler:[self bdw_weakScriptHandle] name:handelName];
    [[self bdw_scriptCallbackHandleDict] setValue:handle forKey:handelName];
}

- (void)bdw_unregister:(NSString *)handelName {
    [self removeScriptMessageHandlerForName:handelName];
    [[self bdw_scriptCallbackHandleDict] setValue:nil forKey:handelName];
}

#pragma mark - WKUserContentController gett &&setter

- (BDWWeakScriptMessageHandler *)bdw_weakScriptHandle {
    BDWWeakScriptMessageHandler *tmpScripteHandle = (BDWWeakScriptMessageHandler *)(objc_getAssociatedObject(self, kBDWWeakScriptHandleKey));
    if (tmpScripteHandle == nil) {
        tmpScripteHandle = [[BDWWeakScriptMessageHandler alloc] init];
        tmpScripteHandle.delegate = self;
        objc_setAssociatedObject(self, kBDWWeakScriptHandleKey, tmpScripteHandle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tmpScripteHandle;
}

- (NSMutableDictionary<NSString *, WKScriptMessageHandler> *)bdw_scriptCallbackHandleDict {
    NSMutableDictionary<NSString *, WKScriptMessageHandler> *dict = (NSMutableDictionary<NSString *, WKScriptMessageHandler> *)(objc_getAssociatedObject(self, kBDWWKScriptCallBackHandleDictKey));
    if (dict == nil) {
        dict = [NSMutableDictionary dictionaryWithCapacity:2];
        objc_setAssociatedObject(self, kBDWWKScriptCallBackHandleDictKey, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return dict;
}

+ (NSString *)bdw_cookiesScriptFromCookies:(NSArray<NSHTTPCookie *> *)cookies {
    NSMutableString *str = [[NSMutableString alloc] init];
    
    for (NSHTTPCookie *cookie in cookies) {
        NSString *name = [cookie.name stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *value = [cookie.value stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *path = [cookie.path stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        NSString *domain = [cookie.domain stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
        if (name.length > 0 && value.length > 0) {
            [str appendFormat:@";document.cookie=\"%@=%@;path=%@;domain=%@\"", name, value, path, domain];
        }
    }
    
    return [str copy];
}


+ (NSString *)fetchHookConsoleLog {
    return @"if (typeof window.console.__log__ === 'undefined') {\
                window.console.__log__ = window.console.log; \
             }\
             window.console.log = function(msg) { \
                 window.console.__log__.apply(this, arguments);   \
                 if (typeof msg === 'string') { \
                     try { \
                        window.webkit.messageHandlers['consoleLog'].postMessage(msg); \
                     } catch (e) {}\
                 } \
             }";
}

@end
