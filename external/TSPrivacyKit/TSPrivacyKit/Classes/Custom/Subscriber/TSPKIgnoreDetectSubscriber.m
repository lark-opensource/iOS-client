//
//  TSPKIgnoreDetectSubscriber.m
//  AWEComplianceImpl-Pods-Aweme
//
//  Created by bytedance on 2021/6/7.
//

#import "TSPKIgnoreDetectSubscriber.h"
#import <TSPrivacyKit/TSPKEvent.h>
#import "TSPKLogger.h"
#import "TSPrivacyKitConstants.h"

@implementation TSPKIgnoreDetectSubscriber

- (TSPKHandleResult *_Nullable)hanleEvent:(TSPKEvent *_Nonnull)event
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if (event.methodType) {
        dict[@"method"] = event.methodType;
    }
    if (event.ignoreSymbolContexts) {
        dict[@"ignoreSymbols"] = event.ignoreSymbolContexts;
    }
    
    dict[@"type"] = @"contextIgnore";
    dict[@"ruleId"] = @(event.ruleId);
    dict[@"isIgnore"] = @(event.isIgnore);
    // ALog info
    [TSPKLogger logWithTag:TSPKLogCommonTag message:dict];
    
    // for example:
    // {"ignoreSymbols":["VoIP"],"method":"AudioOutput","ruleId":10,"type":"contextIgnore", "isIgnore":false}
    return nil;
}

- (NSString *_Nonnull)uniqueId
{
    return @"TSPKIgnoreDetectSubscriber";
}

- (BOOL)canHandelEvent:(TSPKEvent *_Nonnull)event
{
    return YES;
}

@end
