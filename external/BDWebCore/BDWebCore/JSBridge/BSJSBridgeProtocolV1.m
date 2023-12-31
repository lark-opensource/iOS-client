//
//  BSJSBridgeProtocolV1.m
//  BDJSBridgeCore
//
//  Created by 李琢鹏 on 2020/1/20.
//

#import "BSJSBridgeProtocolV1.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

@implementation BSJSBridgeProtocolV1

- (instancetype)initWithWebView:(WKWebView *)webView {
    self = [super initWithWebView:webView];
    if (self) {
        self.jsObjectName = @"ToutiaoJSBridge";
        self.callbackMethodName = @"_handleMessageFromToutiao";
        self.fetchQueueMethodName = @"_fetchQueue";
    }
    return self;
}

- (BOOL)respondsToFetchQueueInvoke:(NSString *)jsString {
    if ([jsString containsString:@"ToutiaoJSBridge._fetchQueue()"]) {
        return YES;
    }
    return NO;
}

- (BOOL)respondsToNavigationAction:(NSString *)actionURLString {
    if ([actionURLString hasPrefix:@"bytedance://dispatch_message"]) {
        return YES;
    }
    return NO;
}

- (NSMutableDictionary *)wrappedDictionaryWithMessage:(BDJSBridgeMessage *)message {
    NSDictionary *originalParams = message.params.copy;
    __auto_type dict = [super wrappedDictionaryWithMessage:message];
    NSMutableDictionary *params = [[dict btd_dictionaryValueForKey:@"__params"] mutableCopy];
    params[@"code"] = @(message.status);
    params[@"__data"] = originalParams;
    [params addEntriesFromDictionary:originalParams];
    dict[@"__params"] = params.copy;
    return dict;
}

- (void)fetchQueue:(void (^)(NSArray<BDJSBridgeMessage *> * _Nullable))block {
    [self.webView evaluateJavaScript:self.fetchQueueFullName completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        NSString *resultString = [result description];
        NSArray *messagesData = [resultString btd_jsonArray];
        if (![messagesData isKindOfClass:NSArray.class] || messagesData.count == 0) {
            block(nil);
        }
        __auto_type messages = NSMutableArray.array;
        for (NSDictionary *data in messagesData) {
            BDJSBridgeMessage *message = [[BDJSBridgeMessage alloc] initWithDictionary:data];
            [messages addObject:message];
        }
        block(messages.copy);
    }];
}

- (NSArray<NSString *> *)injectedObject {
    return @[self.jsObjectName];
}

@end
