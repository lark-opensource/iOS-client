//
//  BDStrategySelectResultModel.m
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/3/29.
//

#import "BDStrategyResultModel.h"

#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@implementation BDStrategyResultModel

- (instancetype)initWithStrategyNames:(NSArray *)names
                           ruleResult:(BDRuleResultModel *)ruleResult
                             hitCache:(BOOL)hitCache
                            fromGraph:(BOOL)fromGraph
                                 cost:(CFTimeInterval)cost
{
    self = [super init];
    if (self) {
        _ruleResult = ruleResult;
        _strategyNames = names;
        _hitCache = hitCache;
        _fromGraph = fromGraph;
        _cost = cost;
    }
    return self;
}

- (instancetype)initWithErrorRuleResultModel:(BDRuleResultModel *)model
{
    self = [super init];
    if (self) {
        _ruleResult = nil;
        _strategyNames = nil;
        _cost = model.strategySelectCost;
        if (model.engineError) {
            _ruleResult = model;
        }
    }
    return self;
}

- (NSError *)engineError
{
    return self.ruleResult.engineError;
}

- (NSString *)key
{
    return self.ruleResult.key;
}

- (NSString *)uuid
{
    return self.ruleResult.uuid;
}

- (NSString *)description
{
    return [@{
        @"strategies" : _strategyNames ?: @[],
        @"hit_cache"  : @(_hitCache),
        @"from_graph" : @(_fromGraph),
        @"cost"       : @(_cost)
    } btd_jsonStringEncoded];
}

@end
