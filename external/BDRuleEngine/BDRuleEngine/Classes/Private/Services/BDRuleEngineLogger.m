//
//  BDRuleEngineLogger.m
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/6/24.
//

#import "BDRuleEngineLogger.h"
#import "BDRuleEngineSettings.h"

#import <PNSServiceKit/PNSLoggerProtocol.h>

typedef NS_ENUM(NSUInteger, BDRuleEngineLocalLogLevel) {
    BDRuleEngineLocalLogLevelNoSet = 0,
    BDRuleEngineLocalLogLevelDebug = 1,
    BDRuleEngineLocalLogLevelInfo  = 2,
    BDRuleEngineLocalLogLevelWarn  = 3,
    BDRuleEngineLocalLogLevelError = 4
};

@implementation BDRuleEngineLogger

static dispatch_queue_t localLogQueue() {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("queue-BDRuleEngineLocalLog", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (void)error:(BDREDescBlock)block
{
    if (![self shouldLogWithLevel:BDRuleEngineLocalLogLevelError block:block]) {
        return;
    }
    dispatch_async(localLogQueue(), ^{
        PNSLogE(@"Ruler", @"%@", block() ?: @"");
    });
}

+ (void)warn:(BDREDescBlock)block
{
    if (![self shouldLogWithLevel:BDRuleEngineLocalLogLevelWarn block:block]) {
        return;
    }
    dispatch_async(localLogQueue(), ^{
        PNSLogW(@"Ruler", @"%@", block() ?: @"");
    });
}

+ (void)info:(BDREDescBlock)block
{
    if (![self shouldLogWithLevel:BDRuleEngineLocalLogLevelInfo block:block]) {
        return;
    }
    dispatch_async(localLogQueue(), ^{
        PNSLogI(@"Ruler", @"%@", block() ?: @"");
    });
}

+ (void)debug:(BDREDescBlock)block
{
    if (![self shouldLogWithLevel:BDRuleEngineLocalLogLevelDebug block:block]) {
        return;
    }
    dispatch_async(localLogQueue(), ^{
        PNSLogD(@"Ruler", @"%@", block() ?: @"");
    });
}

+ (BOOL)shouldLogWithLevel:(BDRuleEngineLocalLogLevel)level block:(BDREDescBlock)block
{
    if (!block || ([BDRuleEngineSettings localLogLevel] > level)) {
        return NO;
    }
    return YES;
}

@end
