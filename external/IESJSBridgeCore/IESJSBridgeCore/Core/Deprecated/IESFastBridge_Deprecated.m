//
//  IESFastBridge_Deprecated.m
//  IESWebKit
//
//  Created by li keliang on 2019/4/7.
//

#import "IESFastBridge_Deprecated.h"
#import "IESBridgeMessage+Private.h"
#import "IESBridgeEngine_Deprecated+Private.h"
#import "WKWebView+IESBridgeExecutor.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import <objc/runtime.h>

#define NSSTRINGIFY(s) @#s

static NSString *const kIESFastBridgeWKHandler = @"IESFastBridge";

@interface IESFastBridgeWKHandler : NSObject<WKScriptMessageHandler>

@property (nonatomic, strong) IESBridgeEngine_Deprecated *bridgeEngine;

@end

@interface WKWebView (IESFastBridgePrivate)

@property (nonatomic, readwrite, nullable) IESBridgeEngine_Deprecated *iesFastBridge;
@property (nonatomic, readwrite, nullable) IESFastBridgeWKHandler *iesBridgeHandler;

@end

@implementation IESFastBridgeWKHandler

- (instancetype)initWithBridgeEngine:(IESBridgeEngine_Deprecated *)bridgeEngine
{
    self = [super init];
    if (self) {
        _bridgeEngine = bridgeEngine;
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if (![message.name isEqualToString:kIESFastBridgeWKHandler]) {
        return;
    }
    
    NSDictionary *messageBody;
    if ([message.body isKindOfClass:NSString.class]) {
        messageBody = [message.body btd_jsonDictionary];
    }
    else if ([message.body isKindOfClass:NSDictionary.class]) {
        messageBody = message.body;
    }
    
    IESBridgeMessage *bridgeMessage = [[IESBridgeMessage alloc] initWithDictionary:messageBody];
    bridgeMessage.from = IESBridgeMessageFromJSCall;
    [self.bridgeEngine executeMethodsWithMessage:bridgeMessage];
}

@end

@implementation IESFastBridge_Deprecated

+ (void)injectionBridgeIntoWKWebView:(WKWebView *)webView;
{
    [self injectionBridge:[IESBridgeEngine_Deprecated new] intoWKWebView:webView];
}

+ (void)injectionBridge:(IESBridgeEngine_Deprecated *)bridgeEngine intoWKWebView:(WKWebView *)webView
{
    [self injectionBridgeScriptIfNeeded:webView];

    if (![webView.iesFastBridge isEqual:bridgeEngine]) {
        IESFastBridgeWKHandler *handler = [[IESFastBridgeWKHandler alloc] initWithBridgeEngine:bridgeEngine];
        [webView.configuration.userContentController removeScriptMessageHandlerForName:kIESFastBridgeWKHandler];
        [webView.configuration.userContentController addScriptMessageHandler:(IESFastBridgeWKHandler *)[BTDWeakProxy proxyWithTarget:handler] name:kIESFastBridgeWKHandler];
        webView.iesBridgeHandler = handler;
    }

    bridgeEngine.executor = webView;
    webView.iesFastBridge = bridgeEngine;
}

+ (void)injectionBridgeScriptIfNeeded:(WKWebView *)webView
{
    NSString *injectionJS =
    NSSTRINGIFY(
                if (typeof window.Toutiao%@ !== 'object') {
                    window.Toutiao%@ = {};
                }
                window.Toutiao%@.invokeMethod = function(msg){
                    if (typeof msg === 'string') {
                        window.webkit.messageHandlers.IESFastBridge.postMessage(msg);
                    }
                };
                );
    NSString *piperName = [@"SlNCcmlkZ2U=" btd_base64DecodedString];
    NSString *jsString = [NSString stringWithFormat:injectionJS, piperName, piperName, piperName];
    WKUserScript *injectionScript = [[WKUserScript alloc] initWithSource:jsString injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
    
    __block BOOL injectionScriptBefore = NO;
    [webView.configuration.userContentController.userScripts enumerateObjectsUsingBlock:^(WKUserScript * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.source isEqualToString:injectionJS]) {
            injectionScriptBefore = YES;
            *stop = YES;
        }
    }];
    
    if (!injectionScriptBefore) {
        [webView.configuration.userContentController addUserScript:injectionScript];
    }
}

@end

@implementation WKWebView (IESFastBridge_Deprecated)

- (void)setIesFastBridge:(IESBridgeEngine_Deprecated *)iesFastBridge
{
    objc_setAssociatedObject(self, @selector(iesFastBridge), iesFastBridge, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (IESBridgeEngine_Deprecated *)iesFastBridge
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setIesBridgeHandler:(IESFastBridgeWKHandler *)iesBridgeHandler
{
    objc_setAssociatedObject(self, @selector(iesBridgeHandler), iesBridgeHandler, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (IESFastBridgeWKHandler *)iesBridgeHandler
{
    return objc_getAssociatedObject(self, _cmd);
}

@end
