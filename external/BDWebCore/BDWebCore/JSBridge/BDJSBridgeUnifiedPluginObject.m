//
//  BDJSBridgeUnifiedPluginObject.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/14.
//

#import "BDJSBridgeUnifiedPluginObject.h"
#import "BDJSBridgePluginObject+Private.h"
#import <ByteDanceKit/ByteDanceKit.h>

@interface BDJSBridgeUnifiedPluginObject ()<WKScriptMessageHandler>

@end

@implementation BDJSBridgeUnifiedPluginObject

- (void)onLoad:(WKWebView *)container {
    if (!container || ![container isKindOfClass:WKWebView.class]) {
        NSParameterAssert(container);
        NSParameterAssert([container isKindOfClass:WKWebView.class]);
        return;
    }
    [super onLoad:container];
    
    NSMutableString *source = [NSMutableString string];
    
    [self.protocols enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, BDJSBridgeProtocol * _Nonnull protocol, BOOL * _Nonnull stop) {
        NSString *scriptSource = protocol.scriptNeedBeInjected;
           if (scriptSource) {
               [source appendString:protocol.scriptNeedBeInjected];
           }
           for (NSString *name in protocol.scriptMessageHandlerNames) {
               [container.configuration.userContentController removeScriptMessageHandlerForName:name];
               [container.configuration.userContentController addScriptMessageHandler:self name:name];
           }
    }];
    
    WKUserScript *script = [[WKUserScript alloc] initWithSource:source injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];

    // Inject script if needed.
    __block BOOL needAddScript = YES;
    [container.configuration.userContentController.userScripts enumerateObjectsUsingBlock:^(WKUserScript *obj, NSUInteger idx, BOOL *stop) {
        if ([script.source isEqualToString:obj.source]) {
            needAddScript = NO;
            *stop = YES;
        }
    }];
    if (needAddScript) {
        [container.configuration.userContentController addUserScript:script];
    }

}

- (IWKPluginHandleResultType)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url = navigationAction.request.URL;
    __auto_type protocol = [self protocolWithNavigationAction:url.absoluteString];
    if (!protocol) {
        return IWKPluginHandleResultContinue;
    }
    @weakify(protocol)
    [protocol fetchQueue:^(NSArray<BDJSBridgeMessage *> * _Nullable messages) {
        for (BDJSBridgeMessage *bridgeMessage in messages) {
            bridgeMessage.protocolVersion = NSStringFromClass(protocol.class);
            [self.executorManager invokeBridgeWithMessage:bridgeMessage callback:^(BDJSBridgeStatus status, NSDictionary * _Nullable params, void (^ _Nullable resultBlock)(NSString * _Nullable)) {
               @strongify(protocol);
               bridgeMessage.status = status;
               bridgeMessage.params = params;
               [protocol callbackBridgeWithMessage:bridgeMessage resultBlock:resultBlock];
            } isForced:YES];
        }
    }];
    decisionHandler(WKNavigationActionPolicyCancel);
    return IWKPluginHandleResultBreak;
}

- (BDJSBridgeProtocol *)protocolWithNavigationAction:(NSString *)actionURLString {
    __block BDJSBridgeProtocol *protocol = nil;
    [self.protocols enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj respondsToNavigationAction:actionURLString]) {
            protocol = obj;
            *stop = YES;
        }
    }];
    return protocol;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    WKWebView *webView = message.webView;
    if (!webView) {
        NSParameterAssert(webView);
        return;
    }
    __auto_type protocol = [self protocolWithScriptMessageName:message.name];
    if (!protocol) {
        return;
    }

    NSDictionary *messageBody;
    if ([message.body isKindOfClass:NSString.class]) {
        messageBody = [message.body btd_jsonDictionary];
    } else if ([message.body isKindOfClass:NSDictionary.class]) {
        messageBody = message.body;
    }
    BDJSBridgeMessage *bridgeMessage = [[BDJSBridgeMessage alloc] initWithDictionary:messageBody];
    bridgeMessage.protocolVersion = NSStringFromClass(protocol.class);
    @weakify(protocol);
    [self.executorManager invokeBridgeWithMessage:bridgeMessage callback:^(BDJSBridgeStatus status, NSDictionary * _Nullable params, void (^ _Nullable resultBlock)(NSString * _Nullable)) {
        @strongify(protocol);
        bridgeMessage.status = status;
        bridgeMessage.params = params;
        BDJSBridgeExecutorFlowShouldContinue shouldCallback = [self.executorManager willCallbackBridgeWithMessage:bridgeMessage callback:^(BDJSBridgeStatus status, NSDictionary * _Nullable params, void (^ _Nullable resultBlock)(NSString * _Nullable)) {
            @strongify(protocol);
            bridgeMessage.status = status;
            bridgeMessage.params = params;
            [protocol callbackBridgeWithMessage:bridgeMessage resultBlock:resultBlock];
        }];
        if (shouldCallback) {
            [protocol callbackBridgeWithMessage:bridgeMessage resultBlock:resultBlock];
        }
    } isForced:YES];
}

- (BDJSBridgeProtocol *)protocolWithScriptMessageName:(NSString *)name {
    __block BDJSBridgeProtocol *protocol = nil;
    [self.protocols enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, BDJSBridgeProtocol * _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj.scriptMessageHandlerNames containsObject:name]) {
            protocol = obj;
        }
    }];
    return protocol;
}

@end
