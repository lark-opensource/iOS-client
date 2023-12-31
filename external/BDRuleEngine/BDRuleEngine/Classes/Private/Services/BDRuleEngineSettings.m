//
//  BDRuleEngineSettings.m
//  Indexer
//
//  Created by WangKun on 2021/12/20.
//

#import "BDRuleEngineSettings.h"
#import "BDRuleEngineDelegateCenter.h"
#import "NSDictionary+BDRESafe.h"
#import "BDRuleEngineReporter.h"

#import <PNSServiceKit/PNSSettingProtocol.h>

@implementation BDRuleEngineSettings

+ (id<PNSSettingProtocol>)setting
{
    static id<PNSSettingProtocol> setting;
    if (!setting) {
        setting = PNSSetting;
    }
    return setting;
}

+ (BOOL)enableAppLog
{
    NSNumber *enable = [[self config] bdre_numberForKey:@"enable_app_log"] ?: @YES;
    return [enable boolValue];
}

+ (BOOL)enablePrecacheCel
{
    NSNumber *enable = [[self config] bdre_numberForKey:@"enable_precache_cel"] ?: @NO;
    return [enable boolValue];
}

+ (BOOL)enableRuleEngine
{
    NSNumber *enable = [[self config] bdre_numberForKey:@"enable_rule_engine"] ?: @YES;
    return [enable boolValue];
}

+ (NSUInteger)expressionCacheSize
{
    NSNumber *size = [[self config] bdre_numberForKey:@"expression_cache_size"] ?: @100;
    return [size unsignedIntegerValue];
}

+ (BOOL)enableCacheSelectStrategy
{
    NSNumber *enable = [[self config] bdre_numberForKey:@"enable_strategy_select_cache"] ?: @YES;
    return [enable boolValue];
}

+ (BOOL)enableInstructionList
{
    NSNumber *enable = [[self config] bdre_numberForKey:@"enable_instruction_list"] ?: @YES;
    return [enable boolValue];
}

+ (BOOL)enableQuickExecutor
{
    NSNumber *enable = [[self config] bdre_numberForKey:@"enable_quick_executor"] ?: @YES;
    return [enable boolValue];
}

+ (BOOL)enableFFF
{
    NSNumber *enable = [[self config] bdre_numberForKey:@"enable_fff"] ?: @NO;
    return [enable boolValue];
}

+ (NSDictionary *)globalSampleRate
{
    return [[self config] bdre_dictForKey:@"global_sample_rate"] ?: @{
        BDRELogStartEventSourceValue    : @1,
        BDRElogExprExecErrorSourceValue : @1,
        BDRELogExprExecEventSourceValue : @100000,
        BDRELogStartEventDelayTimeKey   : @10
    };
}

+ (NSUInteger)localLogLevel
{
    NSNumber *level = [[self config] bdre_numberForKey:@"local_log_level"];
    return level ? [level unsignedIntegerValue] : 4;
}

+ (NSDictionary *)config
{
    static NSDictionary *config = nil;
    if (config) {
        return config;
    }
    
    id<BDRuleEngineDelegate> delegate = [BDRuleEngineDelegateCenter delegate];
    config = (delegate ? [delegate ruleEngineConfig] : [[self setting] dictionaryForKey:@"rule_engine_config"]) ?: @{};
    return config;
}

@end
