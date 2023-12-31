//
//  LKREExprCacheManager.m
//  LKRuleEngine-Pods-AwemeCore
//
//  Created by bytedance on 2021/12/17.
//

#import "LKREExprCacheManager.h"
#import "LKREInstruction.h"
#import "LKRuleEngineKVStore.h"
#import "LKRuleEngineMacroDefines.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>

static NSString * const kLKRuleEngineExpressionMMKVID = @"com.lkre.ruleengine.expression_instructions_cache";
static NSString * const kLKRuleEngineExpressionVersionMMKVID = @"com.lkre.ruleengine.expression_version_cache";

@interface LKREExprCacheManager ()

@end

@implementation LKREExprCacheManager

+ (LKREExprCacheManager *)sharedManager
{
    static LKREExprCacheManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)addCache:(NSArray<LKRECommand *> *)commandStack forExpr:(NSString *)expr
{
    NSMutableArray *insts = [NSMutableArray arrayWithCapacity:commandStack.count];
    for (LKRECommand *command in commandStack) {
        NSDictionary *instDict = [[command instruction] jsonFormat];
        [insts btd_addObject:instDict];
    }
    [LKRuleEngineKVStore setObject:insts forKey:expr uniqueID:kLKRuleEngineExpressionMMKVID];
    [LKRuleEngineKVStore setObject:LarkExpressEngineVersion forKey:expr uniqueID:kLKRuleEngineExpressionVersionMMKVID];
}

- (NSArray<LKRECommand *> *)findCacheForExpr:(NSString *)expr
{
    NSString *version = [LKRuleEngineKVStore objectOfClass:NSString.class forKey:expr uniqueID:kLKRuleEngineExpressionVersionMMKVID];
    if (version && [version isEqualToString:LarkExpressEngineVersion]) {
        NSArray *jsonArray = [LKRuleEngineKVStore objectOfClass:NSArray.class forKey:expr uniqueID:kLKRuleEngineExpressionMMKVID];
        return [LKREInstruction commandsWithJsonArray:jsonArray];        
    }
    return nil;
}

@end
