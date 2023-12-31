//
//  WKWebView+BDNativeWebBridge.m
//  Pods
//
//  Created by liuyunxuan on 2019/7/8.
//

#import "WKWebView+BDNativeWebBridge.h"
#import "BDNativeWebBridgeManager.h"
#import <objc/runtime.h>

#ifndef BDNativeWebComponent_POD_VERSION
#define BDNativeWebComponent_POD_VERSION @"0_9999.0.0"
#endif

@interface WKWebView(BDNativeBridge_Property)

@property (nonatomic, strong) BDNativeWebMessageHandler *bdNativeBridge_nativeMessageHandler;
@property (nonatomic, strong) BDNativeWebBridgeManager *bdNativeBridge_nativeBridgeManager;

@end
static const char * kNativeMessageHandlerKey = "kNativeMessageHandlerKey";
static const char * kNativeBridgeManagerKey = "kNativeBridgeMangerKey";

@implementation WKWebView (BDNativeBridge_Property)

- (void)setBdNativeBridge_nativeMessageHandler:(BDNativeWebMessageHandler *)bdNativeBridge_nativeMessageHandler {
    objc_setAssociatedObject(self, kNativeMessageHandlerKey, bdNativeBridge_nativeMessageHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDNativeWebMessageHandler *)bdNativeBridge_nativeMessageHandler {
    return objc_getAssociatedObject(self, kNativeMessageHandlerKey);
}

- (void)setBdNativeBridge_nativeBridgeManager:(BDNativeWebBridgeManager *)bdNativeBridge_nativeBridgeManager {
    objc_setAssociatedObject(self, kNativeBridgeManagerKey, bdNativeBridge_nativeBridgeManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BDNativeWebBridgeManager *)bdNativeBridge_nativeBridgeManager {
    return objc_getAssociatedObject(self, kNativeBridgeManagerKey);
}

@end

@interface WKUserContentController(BDNativeBridge)

@property (nonatomic, strong) NSNumber *bdNativeBridge_nativeBridgeHandle;

@end

static const char * kWKWebViewUserControllerHandleKey = "kWKWebViewUserControllerHandleKey";

@implementation WKUserContentController(BDNativeBridge)

- (void)setBdNativeBridge_nativeBridgeHandle:(NSNumber *)bdNativeBridge_nativeBridgeHandle {
    objc_setAssociatedObject(self, kWKWebViewUserControllerHandleKey, bdNativeBridge_nativeBridgeHandle, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (NSNumber *)bdNativeBridge_nativeBridgeHandle {
    return objc_getAssociatedObject(self, kWKWebViewUserControllerHandleKey);
}

@end

@implementation WKWebView (BDNativeBridge)

- (void)bdNativeBridge_enableBDNativeBridge
{
    if (self.bdNativeBridge_nativeMessageHandler == nil)
    {
        self.bdNativeBridge_nativeMessageHandler = [[BDNativeWebMessageHandler alloc] init];
        self.bdNativeBridge_nativeMessageHandler.delegate = self;
    }
    
    if (self.bdNativeBridge_nativeBridgeManager == nil)
    {
        self.bdNativeBridge_nativeBridgeManager = [[BDNativeWebBridgeManager alloc] init];
        self.bdNativeBridge_nativeBridgeManager.delegate = self;
    }
    
    if (!self.configuration.userContentController.bdNativeBridge_nativeBridgeHandle)
    {
        NSString *script = @"{ window.byted_mixrender_native = { \
            invoke: function(id, funcName, params, callbackId) { \
                window.webkit.messageHandlers.byted_mixrender_native.postMessage(\
                    JSON.stringify({msg: 'invoke', id, func: funcName, params, callbackId: callbackId \
                }))\
            },\
            callback: function(id, result) { \
                window.webkit.messageHandlers.byted_mixrender_native.postMessage(\
                    JSON.stringify({msg: 'callback',  id, result \
                }))\
            } \
        }};";

        WKUserScript *userScript = [[WKUserScript alloc] initWithSource:script injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [self.configuration.userContentController addUserScript:userScript];
        [self.configuration.userContentController addScriptMessageHandler:self.bdNativeBridge_nativeMessageHandler name:@"byted_mixrender_native"];
    }
    else
    {
        [self.configuration.userContentController removeScriptMessageHandlerForName:@"byted_mixrender_native"];
        [self.configuration.userContentController addScriptMessageHandler:self.bdNativeBridge_nativeMessageHandler name:@"byted_mixrender_native"];
    }
    self.configuration.userContentController.bdNativeBridge_nativeBridgeHandle = @(YES);
}

- (void)bdNativeBridge_registerHandler:(BDNativeBridgeHandler)handler bridgeName:(NSString *)bridgeName
{
    [self.bdNativeBridge_nativeBridgeManager registerHandler:handler bridgeName:bridgeName];
}
#pragma mark - BDNativeWebMessageHandlerDelegate
- (void)bdNativeUserContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:@"byted_mixrender_native"])
    {
        if ([message.body isKindOfClass:[NSString class]])
        {
            [self.bdNativeBridge_nativeBridgeManager handleMixRenderMessage:message.body];
        }
    }
}

- (void)bdNativeBridge_nativeMangerEvaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id, NSError *))completionHandler
{
    [self evaluateJavaScript:javaScriptString completionHandler:completionHandler];
}

- (NSString *)bdNativeBridge_version
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^\\d+_(\\d+(\\.\\d+){0,2})" options:NSRegularExpressionCaseInsensitive error:nil];

    __block NSString *shortVersion = nil;
    [regex enumerateMatchesInString:BDNativeWebComponent_POD_VERSION options:0 range:NSMakeRange(0, BDNativeWebComponent_POD_VERSION.length) usingBlock:^(NSTextCheckingResult * _Nullable result, NSMatchingFlags flags, BOOL * _Nonnull stop) {
        shortVersion = [BDNativeWebComponent_POD_VERSION substringWithRange:[result rangeAtIndex:1]];
        *stop = YES;
    }];
    NSAssert(shortVersion, @"Bad Pod Version");
    return shortVersion ?: @"0";
}
@end
