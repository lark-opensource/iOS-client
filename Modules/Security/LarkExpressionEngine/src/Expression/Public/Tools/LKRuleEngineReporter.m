//
//  LKRuleEngineReporter.m
//  LarkExpressionEngine
//
//  Created by 汤泽川 on 2022/8/9.
//

#import "LKRuleEngineReporter.h"

static id<LKRuleEngineReporter> sharedReporter = nil;

@implementation LKRuleEngineReporter

+ (instancetype)sharedInstance {
    static LKRuleEngineReporter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LKRuleEngineReporter alloc] init];
    });
    return instance;
}

+ (void)registerReporter:(id<LKRuleEngineReporter>)reporter {
    sharedReporter = reporter;
}

- (void)log:(NSString *)event
     metric:(NSDictionary *)metric
   category:(NSDictionary *)category {
    if (sharedReporter && [sharedReporter respondsToSelector:@selector(log:metric:category:)]) {
        [sharedReporter log:event metric:metric category:category];
    } else {
        NSAssert(NO, @"Uninject log service!");
    }
}

@end
