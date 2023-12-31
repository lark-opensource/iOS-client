//
//  TSPKRuleCacheStrategy.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/7/11.
//

#import "TSPKRuleCacheStrategy.h"
#import "TSPKCacheStore.h"
#import <PNSServiceKit/PNSRuleEngineProtocol.h>
#import <PNSServiceKit/PNSServiceCenter.h>

@implementation TSPKRuleCacheStrategy

+ (instancetype)generate:(NSDictionary *)config {
    return [TSPKRuleCacheStrategy new];
}

- (BOOL)needUpdate:(NSString *)key cacheStore:(id<TSPKCacheStore>)store {
    if (![store containsKey:key]) {
        return YES;
    }
    
    id<PNSRuleResultProtocol> results = [PNS_GET_INSTANCE(PNSRuleEngineProtocol) validateParams:[self convertEventDataToParams:key source:@"guard_cache"]];
    
    for(id <PNSSingleRuleResultProtocol> result in results.values) {
        if ([result.conf[@"action"] isEqualToString:@"cache"]) {
            return NO;
        }
    }
    
    return YES;
}

- (NSDictionary *)convertEventDataToParams:(NSString *)key source:(NSString *)source {
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    dict[@"source"] = source ?: @"";
    dict[@"api"] = key ?: @"";
    return [NSDictionary dictionaryWithDictionary:dict];
}

@end
