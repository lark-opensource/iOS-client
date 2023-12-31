//
//  BDStrategyCenter+Debug.m
//  BDRuleEngine
//
//  Created by WangKun on 2022/1/4.
//

#import "BDStrategyCenter+Debug.h"
#import "BDStrategyProviderManager.h"
#import "BDStrategyStore.h"

#import <ByteDanceKit/NSDictionary+BTDAdditions.h>

@interface BDStrategyProviderManager (Debug)
- (NSArray<id<BDStrategyProvider>>*)providers;
@end

@implementation BDStrategyProviderManager(Debug)
@end

@interface BDStrategyCenter (Debug)
+ (instancetype)sharedInstance;
@property (nonatomic, strong, readonly) BDStrategyProviderManager *providerCenter;
@property (nonatomic, strong, readonly) BDStrategyStore *store;
@end

@implementation BDStrategyCenter (Debug)

+ (NSArray<id<BDStrategyProvider>> *)providers
{
    return [[[BDStrategyCenter sharedInstance] providerCenter] providers];
}

+ (NSDictionary *)mergedStrategies
{
    return [[[BDStrategyCenter sharedInstance] store] jsonFormat];
}

@end
