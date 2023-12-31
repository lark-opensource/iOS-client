//
//  BDJSBridgeProtocolV3.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/20.
//

#import "BDJSBridgeProtocolV3.h"
#import <ByteDanceKit/ByteDanceKit.h>

@interface BDJSBridgeMessage (ProtocolV3)

@property(nonatomic, copy, readonly) NSString *iframeURLString;

@end

@implementation BDJSBridgeMessage (ProtocolV3)

- (NSString *)iframeURLString {
    return [self.rawData btd_stringValueForKey:@"__iframe_url"];
}

@end

@implementation BDJSBridgeProtocolV3

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super initWithWebView:webView];
    if (self) {
        self.jsObjectName = @"JSBridge";
        self.callbackMethodName = @"_handleMessageFromApp";
    }
    return self;
}

- (NSMutableDictionary *)wrappedDictionaryWithMessage:(BDJSBridgeMessage *)message {
    message.endTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
    NSDictionary *originalParams = message.params.copy;
    __auto_type dict = [super wrappedDictionaryWithMessage:message];
    NSMutableDictionary *params = [dict[@"__params"] mutableCopy] ?: NSMutableDictionary.dictionary;
    NSMutableDictionary *data = originalParams.mutableCopy;
    data[@"recvJsCallTime"] = message.beginTime;
    data[@"respJsTime"] = message.endTime;
    params[@"code"] = @(message.status);
    params[@"data"] = data.copy;
    params[@"code"] = @(message.status);
    params[@"__data"] = originalParams;
    dict[@"__params"] = params.copy;
    return dict;
}

- (NSString *)callbackJSStringWithMessage:(BDJSBridgeMessage *)message {
    message.messageType = @"callback";
    NSString *js = nil;
    if (message.iframeURLString.length) {
        // Execute this script only if the web side passes the `__iframe_url` parameter when invoking JSB in an iframe.
        // This script forwards the data via `postMessage` to the iframe, which is identified by the `__iframe_url`.
        js = [NSString stringWithFormat:@stringify(
            ;(function(){
                var iframe = document.querySelector('iframe[src="%@"]');
                iframe && iframe.contentWindow && iframe.contentWindow.postMessage(%@, "%@");
            })();
        ), message.iframeURLString, [[self wrappedDictionaryWithMessage:message] btd_jsonStringPrettyEncoded], message.iframeURLString];
    } else {
        js = [NSString stringWithFormat:@";window.%@ && %@ && %@(%@)", self.jsObjectName, self.callbackFullName, self.callbackFullName, [[self wrappedDictionaryWithMessage:message] btd_jsonStringPrettyEncoded]];
    }
    
    return js;
}

- (NSSet<NSString *> *)scriptMessageHandlerNames {
    return [NSSet setWithObject:@"IESJSBridgeProtocolVersion3_0"];
}

- (NSString *)scriptNeedBeInjected {
    NSString *messageHandler = [NSString stringWithFormat:@"webkit.messageHandlers.%@.postMessage", @"IESJSBridgeProtocolVersion3_0"];
    NSString *objectName = @"JS2NativeBridge";
    NSString *methodName = @"_invokeMethod";

    NSString *format =
    @stringify(
                try {
                    if (typeof %@ !== 'object') {
                        %@ = {};
                    }
                    %@.%@ = function(params) {
                        if (typeof params === 'string') {
                            %@(params);
                        }
                    };
                 } catch (e) {}
                );
    return [NSString stringWithFormat:format, objectName, objectName, objectName, methodName, messageHandler];
}

- (NSArray<NSString *> *)injectedObject {
    return @[self.jsObjectName, @"JS2NativeBridge"];
}

@end
