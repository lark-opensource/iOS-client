//
//  BDJSBridgeProtocol.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2019/12/30.
//

#import "BDJSBridgeProtocol.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

@interface BDJSBridgeProtocol ()

@property(nonatomic, weak) WKWebView *webView;

@end

@implementation BDJSBridgeProtocol

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-designated-initializers"
- (instancetype)init {
#pragma clang diagnostic pop
    [NSException raise:NSGenericException format:@"Use designated initializer initWithWebView: instead."];
    return nil;
}

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super init];
    if (self) {
        _webView = webView;
    }
    return self;
}

- (BOOL)respondsToScriptMessageName:(NSString *)name {
    return [self.scriptMessageHandlerNames containsObject:name];
}

- (BOOL)respondsToFetchQueueInvoke:(NSString *)jsString {
    return NO;
}

- (BOOL)respondsToCallbackInvoke:(NSString *)jsString {
    return [jsString containsString:self.callbackFullName];
}

- (BOOL)respondsToNavigationAction:(NSString *)actionURLString {
    return NO;
}

- (NSString *)scriptNeedBeInjected {
    return nil;
}

- (NSString *)injectedObject {
    return nil;
}

- (NSDictionary *)bridgeInfoWithCallbackInvoke:(NSString *)jsString {
    if (!self.jsObjectName || !self.callbackMethodName) {
        return nil;
    }
    NSString *pattern = [NSString stringWithFormat:@"(?<=%@\\().([\\s\\S]*)?(?=\\))", self.callbackFullName];
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
    NSTextCheckingResult *result = [regex firstMatchInString:jsString options:0 range:NSMakeRange(0, [jsString length])];
    NSString *info = nil;
    if (result) {
        info = [jsString substringWithRange:result.range];
    }
    return [info btd_jsonDictionary];
}

- (void)callbackBridgeWithMessage:(BDJSBridgeMessage *)message resultBlock:(void (^)(NSString * _Nullable))resultBlock {
    [self.webView evaluateJavaScript:[self callbackJSStringWithMessage:message] completionHandler:^(id _Nullable result, NSError * _Nullable error) {
          BDJSBridgeStatus statusCode = BDJSBridgeStatusSucceed;
          if ([result isKindOfClass:NSString.class]) {
              NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
              NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
              NSString *description = dict[@"__err_code"];
              BOOL is404 = [description isEqualToString:@"cb404"] || [description isEqualToString:@"ev404"];
              statusCode = is404 ? BDJSBridgeStatus404 : BDJSBridgeStatusSucceed;
          }
          else if (!result) {
              statusCode = BDJSBridgeStatusUndefined;
          }
          else {
              statusCode = BDJSBridgeStatusUnknownError;
          }
          !resultBlock ?: resultBlock(statusCode == BDJSBridgeStatusSucceed ? result : nil);
      }];

}

- (NSString *)callbackJSStringWithMessage:(BDJSBridgeMessage *)message {
    message.messageType = @"callback";
    NSString *js = [NSString stringWithFormat:@";window.%@ && %@ && %@(%@)", self.jsObjectName, self.callbackFullName, self.callbackFullName, [[self wrappedDictionaryWithMessage:message] btd_jsonStringPrettyEncoded]];
    return js;
}

- (NSString *)callbackFullName {
    return [NSString stringWithFormat:@"%@.%@", self.jsObjectName, self.callbackMethodName];
}

- (NSString *)fetchQueueFullName {
    return [NSString stringWithFormat:@"%@.%@()", self.jsObjectName, self.fetchQueueMethodName];
}

- (NSMutableDictionary *)wrappedDictionaryWithMessage:(BDJSBridgeMessage *)message {
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"ret"] = message.statusDescription;
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"__msg_type"] = message.messageType;
    dict[@"__event_id"] = message.eventID;
    dict[@"__callback_id"] = message.callbackID;
    dict[@"__params"] = params.copy;

    // Adapt old version JSSDK.
    if ([message.messageType isEqualToString:BDJSBridgeMessageTypeEvent]) {
        dict[@"__callback_id"] = message.eventID;
    }
    return dict;
}

- (void)fetchQueue:(void (^)(NSArray<BDJSBridgeMessage *> * _Nullable))block {

}

@end
