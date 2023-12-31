//
//  BDJSBridgeAdaptPluginObject.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/14.
//

#import "BDJSBridgeAdaptPluginObject.h"
#import "BDJSBridgePluginObject+Private.h"
#import <WebKit/WebKit.h>
#import <objc/runtime.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/BTDMacros.h>

@interface BDJSBridgeAdaptPluginObject ()

@property(nonatomic, strong) NSMutableDictionary<NSString *, BDJSBridgeMessage *> *callbackIdMap;

@end

@implementation BDJSBridgeAdaptPluginObject

- (NSMutableDictionary<NSString *,BDJSBridgeMessage *> *)callbackIdMap {
    if (!_callbackIdMap) {
        _callbackIdMap = NSMutableDictionary.dictionary;
    }
    return _callbackIdMap;
}

- (IWKPluginObjectPriority)priority {
    return IWKPluginObjectPriorityDefault + 10000;
}


- (IWKPluginHandleResultType)webView:(WKWebView *)webView didInitWithFrame:(CGRect)rect configuration:(WKWebViewConfiguration *)configuration {
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)addScriptMessageHandler:(id<WKScriptMessageHandler>)scriptMessageHandler name:(NSString *)name {
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)bdw_userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSDictionary *messageBody;
    if ([message.body isKindOfClass:NSString.class]) {
        messageBody = [message.body btd_jsonDictionary];
    } else if ([message.body isKindOfClass:NSDictionary.class]) {
        messageBody = message.body;
    }
    __auto_type protocol = [self protocolWithReceivedScriptMessageName:message.name];
    if (!protocol) {
        return IWKPluginHandleResultContinue;
    }
    BDJSBridgeMessage *bridgeMessage = [[BDJSBridgeMessage alloc] initWithDictionary:messageBody];
    if (!bridgeMessage) {
        return IWKPluginHandleResultContinue;
    }
    self.callbackIdMap[bridgeMessage.callbackID] = bridgeMessage;
    @weakify(protocol)
    __auto_type shouldContinue = [self.executorManager invokeBridgeWithMessage:bridgeMessage callback:^(BDJSBridgeStatus status, NSDictionary * _Nullable params, void (^ _Nullable resultBlock)(NSString * _Nullable)) {
        @strongify(protocol);
        bridgeMessage.status = status;
        bridgeMessage.params = params;
        [protocol callbackBridgeWithMessage:bridgeMessage resultBlock:resultBlock];
    } isForced:NO];
    if (!shouldContinue) {
        return IWKPluginHandleResultBreak;
    }
    return IWKPluginHandleResultContinue;
}

- (IWKPluginHandleResultType)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^)(id _Nullable, NSError * _Nullable))completionHandler {
    //todo
    __auto_type fetchQueueProtocol = [self protocolWithFetchQueueInvoke:javaScriptString];
    @weakify(fetchQueueProtocol)
    if (fetchQueueProtocol) {
        __auto_type wrappedCompletionHandler = ^(id _Nullable result, NSError * _Nullable error){
             NSString *resultString = [result description];
             NSArray *messagesData = [resultString btd_jsonArray];
             NSMutableArray *filteredData = messagesData.mutableCopy;
             if (![messagesData isKindOfClass:NSArray.class]) {
                 return;
             }
             for (NSDictionary *data in messagesData) {
                 BDJSBridgeMessage *bridgeMessage = [[BDJSBridgeMessage alloc] initWithDictionary:data];
                 if (!bridgeMessage) {
                     continue;
                 }
                 self.callbackIdMap[bridgeMessage.callbackID] = bridgeMessage;
                 __auto_type shouldContinue = [self.executorManager invokeBridgeWithMessage:bridgeMessage callback:^(BDJSBridgeStatus status, NSDictionary * _Nullable params, void (^ _Nullable resultBlock)(NSString * _Nullable)) {
                       @strongify(fetchQueueProtocol);
                       bridgeMessage.status = status;
                       bridgeMessage.params = params;
                       [fetchQueueProtocol callbackBridgeWithMessage:bridgeMessage resultBlock:resultBlock];
                   } isForced:NO];
                   if (!shouldContinue) {
                       [filteredData removeObject:data];
                   }
             }
             if (completionHandler) {
                 completionHandler(messagesData ? [filteredData btd_jsonStringEncoded] : result, error);
             }
         };
       
         return IWKPluginHandleResultWrapValue((@[javaScriptString, wrappedCompletionHandler]));
    }
    
    __auto_type callbackProtocol = [self protocolWithCallbackInvoke:javaScriptString];
    if (callbackProtocol) {
        NSDictionary *bridgeInfo = [callbackProtocol bridgeInfoWithCallbackInvoke:javaScriptString];
        if (bridgeInfo) {
            BDJSBridgeMessage *bridgeMessage = self.callbackIdMap[bridgeInfo[@"__callback_id"]];
            if (!bridgeMessage) {
                return IWKPluginHandleResultContinue;
            }
            [self.callbackIdMap removeObjectForKey:bridgeInfo[@"__callback_id"]];
            [bridgeMessage updateStatusWithParams:bridgeInfo[@"__params"]];
            if (bridgeMessage.status == BDJSBridgeStatusNoHandler) {
                __block NSString *js = nil;
                @weakify(callbackProtocol)
                __auto_type shouldContinue = [self.executorManager willCallbackBridgeWithMessage:bridgeMessage callback:^(BDJSBridgeStatus status, NSDictionary * _Nullable params, void (^ _Nullable resultBlock)(NSString * _Nullable)) {
                    @strongify(callbackProtocol);
                    bridgeMessage.status = status;
                    bridgeMessage.params = params;
                    js = [callbackProtocol callbackJSStringWithMessage:bridgeMessage];
                    
                }];
                if (!shouldContinue && js) {
                    return IWKPluginHandleResultWrapValue((@[js, completionHandler]));
                }
            }
        }
    }
    return IWKPluginHandleResultContinue;

}

- (BDJSBridgeProtocol *)protocolWithReceivedScriptMessageName:(NSString *)name {
    __block BDJSBridgeProtocol *protocol = nil;
    [self.protocols enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj respondsToScriptMessageName:name]) {
            protocol = obj;
            *stop = YES;
        }
    }];
    return protocol;
}

- (BDJSBridgeProtocol *)protocolWithFetchQueueInvoke:(NSString *)javaScriptString {
    __block BDJSBridgeProtocol *protocol = nil;
    [self.protocols enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj respondsToFetchQueueInvoke:javaScriptString]) {
            protocol = obj;
            *stop = YES;
        }
    }];
    return protocol;
}

- (BDJSBridgeProtocol *)protocolWithCallbackInvoke:(NSString *)javaScriptString {
    __block BDJSBridgeProtocol *protocol = nil;
    [self.protocols enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj respondsToCallbackInvoke:javaScriptString]) {
            protocol = obj;
            *stop = YES;
        }
    }];
    return protocol;
}

@end
