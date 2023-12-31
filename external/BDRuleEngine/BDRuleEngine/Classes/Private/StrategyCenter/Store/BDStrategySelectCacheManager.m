//
//  BDStrategySelectCacheManager.m
//  Indexer
//
//  Created by WangKun on 2022/2/22.
//

#import "BDStrategySelectCacheManager.h"
#import "BDStrategyCenter.h"
#import "BDRuleEngineLogger.h"
#import "BDRuleEngineKVStore.h"
#import "BDRuleEngineReporter.h"
#import "BDStrategyCenterConstant.h"

#import <pthread/pthread.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>

static NSString * const kBDStrategySelectCacheIDPrefix = @"com.bd.ruleengine.strategy_select_cache";
static NSString * const kBDStrategySelectCacheMD5ID = @"com.bd.ruleengine.strategy_select_cache.md5_map";

@implementation BDStrategySelectCacheManager

static dispatch_queue_t preSelectStrategiesQueue() {
    static dispatch_queue_t queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("queue-BDRuleEnginePreSelectStrategiesQueue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
}

+ (NSString *)signature
{
    return [BDRuleEngineKVStore stringForKey:BDStrategySignatureKey uniqueID:kBDStrategySelectCacheMD5ID];
}

+ (void)loadStrategySelectCache
{
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    NSArray *allKeys = [BDRuleEngineKVStore allKeysWithUniqueID:kBDStrategySelectCacheMD5ID];
    for (NSString *setName in allKeys) {
        // load
        [self ruleSetNamesForCacheKey:@"" inSet:setName];
    }
    CFTimeInterval costTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000000;
    [BDRuleEngineReporter delayLog:BDRELogNameRulerStart tags:@{BDRELogSampleTagSourceKey : BDRELogStartEventSourceValue} block:^id<BDRuleEngineReportDataSource> _Nonnull{
        return [[BDREReportContent alloc] initWithMetric:@{
            @"cost": @(costTime)
        } category:@{
            @"event_name": @"rule_engine_load_streategy_select_cache_with_md5map",
            @"newmd5_not_equal_oldmd5_count": @(0),
            @"only_load": @(1)
        } extra:nil];
    }];
}

+ (void)loadStrategySelectCacheWithMD5Map:(NSDictionary *)md5Map signature:(NSString *)signature
{
    NSInteger md5NotEqualCount = 0;
    CFAbsoluteTime startTime = CFAbsoluteTimeGetCurrent();
    
    NSArray *allKeys = [BDRuleEngineKVStore allKeysWithUniqueID:kBDStrategySelectCacheMD5ID];
    // delete select cache
    for (NSString *setName in allKeys) {
        // not in new md5 map's keys
        if (![md5Map btd_objectForKey:setName default:nil]) {
            NSString *mmkvID = [NSString stringWithFormat:@"%@.%@", kBDStrategySelectCacheIDPrefix, setName];
            [BDRuleEngineKVStore closeWithUniqueID:mmkvID];
            [BDRuleEngineKVStore removeValueForKey:setName uniqueID:kBDStrategySelectCacheMD5ID];
        }
    }
    // update select cache according to md5
    for (NSString *setName in md5Map) {
        NSString *newMD5 = [md5Map btd_stringValueForKey:setName];
        NSString *mmkvID = [NSString stringWithFormat:@"%@.%@", kBDStrategySelectCacheIDPrefix, setName];
        
        if ([BDRuleEngineKVStore containsKey:setName uniqueID:kBDStrategySelectCacheMD5ID]) {
            NSString *oldMD5 = [BDRuleEngineKVStore stringForKey:setName uniqueID:kBDStrategySelectCacheMD5ID];
            // clear all cache item for setName if md5 diff
            if (![newMD5 isEqualToString:oldMD5]) {
                md5NotEqualCount += 1;
                NSArray *allKeysCopy = [BDRuleEngineKVStore allKeysWithUniqueID:mmkvID].copy;
                [BDRuleEngineKVStore clearAllWithUniqueID:mmkvID];
                // pre execute strategy select
                dispatch_async(preSelectStrategiesQueue(), ^{
                    [allKeysCopy enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        NSDictionary *parameters = [obj btd_jsonDictionary];
                        if (parameters) {
                            [BDStrategyCenter generateStrategiesInSource:setName params:parameters];
                        }
                    }];
                });
            } else {
                // load
                [self ruleSetNamesForCacheKey:@"" inSet:setName];
            }
        } else {
            // load
            [self ruleSetNamesForCacheKey:@"" inSet:setName];
        }
        [BDRuleEngineKVStore setString:newMD5 forKey:setName uniqueID:kBDStrategySelectCacheMD5ID];
    }
    [BDRuleEngineKVStore setString:signature forKey:BDStrategySignatureKey uniqueID:kBDStrategySelectCacheMD5ID];
    CFTimeInterval costTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000000;
    
    [BDRuleEngineReporter delayLog:BDRELogNameRulerStart tags:@{BDRELogSampleTagSourceKey : BDRELogStartEventSourceValue} block:^id<BDRuleEngineReportDataSource> _Nonnull{
        return [[BDREReportContent alloc] initWithMetric:@{
            @"cost": @(costTime)
        } category:@{
            @"event_name": @"rule_engine_load_streategy_select_cache_with_md5map",
            @"newmd5_not_equal_oldmd5_count": @(md5NotEqualCount),
            @"only_load": @(0)
        } extra:nil];
    }];
}

+ (NSArray *)ruleSetNamesForInput:(NSDictionary *)input
                   withFilterKeys:(nullable NSArray *)filterKeys
                            inSet:(NSString *)setName
{
    NSString *cacheKey = [self generateKeyForInput:input withFilterKeys:filterKeys];
    return [BDStrategySelectCacheManager ruleSetNamesForCacheKey:cacheKey inSet:setName];
}

+ (void)setRuleSetNames:(NSArray *)ruleSetNames
               forInput:(NSDictionary *)input
         withFilterKeys:(NSArray *)filterKeys
                  inSet:(NSString *)setName
{
    NSString *cacheKey = [self generateKeyForInput:input withFilterKeys:filterKeys];
    [BDStrategySelectCacheManager setRuleSetNames:ruleSetNames forCacheKey:cacheKey inSet:setName];
}

+ (NSArray *)ruleSetNamesForCacheKey:(NSString *)cacheKey
                               inSet:(NSString *)setName
{
    NSArray *strategy = [BDRuleEngineKVStore objectOfClass:NSArray.class forKey:cacheKey uniqueID:[self uniqueIDWithSetName:setName]];
    if (strategy) {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[StrategySelectCacheManager] find strategy select cache for key [%@] with strategy [%@]", cacheKey ?: @"", strategy];
        }];
    } else {
        [BDRuleEngineLogger info:^NSString * _Nonnull{
            return [NSString stringWithFormat:@"[StrategySelectCacheManager] find no strategy select cache for key [%@]", cacheKey ?: @""];
        }];
    }
    return strategy;
}

+ (void)setRuleSetNames:(NSArray *)ruleSetNames
            forCacheKey:(NSString *)cacheKey
                  inSet:(NSString *)setName
{
    BOOL res = [BDRuleEngineKVStore setObject:ruleSetNames ?: @[] forKey:cacheKey uniqueID:[self uniqueIDWithSetName:setName]];
    if (!res) {
        return;
    }
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[StrategySelectCacheManager] save strategy select cache for key [%@] with value [%@]", cacheKey ?: @"", ruleSetNames ?: @[]];
    }];
}

+ (NSString *)uniqueIDWithSetName:(NSString *)setName
{
    return [NSString stringWithFormat:@"%@.%@", kBDStrategySelectCacheIDPrefix, setName];
}

+ (NSString *)generateKeyForInput:(NSDictionary *)input withFilterKeys:(nullable NSArray *)filterKeys
{
    if (!input) {
        return nil;
    }
    if (!filterKeys) {
        filterKeys = [input.allKeys sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            if ([obj1 isKindOfClass:[NSString class]] && [obj2 isKindOfClass:[NSString class]]) {
                return [obj1 compare:obj2];
            }
            return NSOrderedSame;
        }];
    }
    NSMutableString *res = @"{".mutableCopy;
    for (NSUInteger index = 0; index < filterKeys.count; index++) {
        id key = [filterKeys objectAtIndex:index];
        id value = [input objectForKey:key];
        if (!value) {
            continue;
        }
        if ([value isKindOfClass:[NSSet class]]) {
            value = [value allObjects];
        }
        if ([value isKindOfClass:[NSString class]]) {
            [res appendFormat:@"\"%@\":\"%@\",", key, value];
        } else if ([value isKindOfClass:[NSNumber class]]) {
            [res appendFormat:@"\"%@\":%@,", key, value];
        } else if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
            NSString *convertedValue = [value btd_jsonStringEncoded];
            if (convertedValue) {
                [res appendFormat:@"\"%@\":%@,", key, convertedValue];
            }
        } else {
            continue;
        }
    }
    NSString *returnString = res.copy;
    if (res.length >= 1) {
        NSString *last = [res substringFromIndex:res.length-1];
        if ([last isEqualToString:@","]) {
            returnString = [res substringToIndex:res.length-1];
        }
    }
    return [returnString stringByAppendingString:@"}"];
}

@end
