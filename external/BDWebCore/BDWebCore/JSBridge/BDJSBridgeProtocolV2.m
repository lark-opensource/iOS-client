//
//  BDJSBridgeProtocolV2.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/20.
//

#import "BDJSBridgeProtocolV2.h"

@interface BDJSBridgeProtocolV2 ()<WKScriptMessageHandler>

@end

@implementation BDJSBridgeProtocolV2

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super initWithWebView:webView];
    if (self) {
        self.jsObjectName = @"Native2JSBridge";
        self.callbackMethodName = @"_handleMessageFromApp";
        [webView.configuration.userContentController removeScriptMessageHandlerForName:@"onMethodParams"];
        [webView.configuration.userContentController addScriptMessageHandler:self name:@"onMethodParams"];
    }
    return self;
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    
}

- (NSMutableDictionary *)wrappedDictionaryWithMessage:(BDJSBridgeMessage *)message {
    message.endTime = [NSString stringWithFormat:@"%.0f", [[NSDate date] timeIntervalSince1970] * 1000];
    NSDictionary *originalParams = message.params.copy;
    __auto_type dict = [super wrappedDictionaryWithMessage:message];
    NSMutableDictionary *params = [dict[@"__params"] mutableCopy] ?: NSMutableDictionary.dictionary;
    NSMutableDictionary *data = originalParams.mutableCopy;
    data[@"recvJsCallTime"] = message.beginTime;
    data[@"respJsTime"] = message.endTime;
    [params addEntriesFromDictionary:originalParams];
    params[@"data"] = data.copy;
    params[@"code"] = @(message.status);
    params[@"__data"] = originalParams;
    dict[@"__params"] = params.copy;
    return dict;
}


- (NSSet<NSString *> *)scriptMessageHandlerNames {
    return [NSSet setWithArray:@[@"callMethodParams", @"IESJSBridgeProtocolVersion2_0"]];
}

- (NSString *)scriptNeedBeInjected {
    NSString *messageHandler = [NSString stringWithFormat:@"webkit.messageHandlers.%@.postMessage", @"IESJSBridgeProtocolVersion2_0"];
    NSString *objectName = @"window";
    NSString *methodName = @"callMethodParams";

    NSString *format =
    @stringify(
               try {
                    if (typeof %@ !== 'object') {
                        %@ = {};
                    }
                    %@.%@ = function(name, params) {
                        if (typeof params === 'object') {
                            %@(JSON.stringify(params));
                        }
                    };
                } catch (e) {}
               );
    return [NSString stringWithFormat:format, objectName, objectName, objectName, methodName, messageHandler];
}

- (NSArray<NSString *> *)injectedObject {
    return @[@"callMethodParams", @"Native2JSBridge"];
}

@end
