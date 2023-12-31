//
//  LKRuleEngineLogger.m
//  LarkExpressionEngine
//
//  Created by 汤泽川 on 2022/11/28.
//

#import "LKRuleEngineLogger.h"

static id<LKRuleEngineLogger> sharedLogger = nil;

@implementation LKRuleEngineLogger

+ (instancetype)sharedInstance {
    static LKRuleEngineLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[LKRuleEngineLogger alloc] init];
    });
    return logger;
}

+ (void)registerLogger:(id<LKRuleEngineLogger>)logger {
    sharedLogger = logger;
}

- (void)logWithLevel:(LKRuleEngineLogLevel)level message:(nonnull NSString *)message file:(nonnull NSString *)file line:(NSInteger)line function:(nonnull NSString *)function {
    if (sharedLogger && [sharedLogger respondsToSelector:@selector(logWithLevel:message:file:line:function:)]) {
        [sharedLogger logWithLevel:level message:message file:file line:line function:function];        
    }
}


@end
