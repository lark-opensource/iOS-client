//
//  TSPKCacheStrategyFactory.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/7/8.
//

#import "TSPKCacheStrategyFactory.h"
#import "TSPKTimeCacheStrategy.h"
#import "TSPKRuleCacheStrategy.h"
#import "TSPKCacheStrategyGenerator.h"

@interface TSPKCacheStrategyFactory ()

@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, Class> *globalStategties;

@end

@implementation TSPKCacheStrategyFactory

- (instancetype)init
{
    self = [super init];
    if (self) {
        _globalStategties = [NSMutableDictionary dictionary];
        [_globalStategties setValue:[TSPKTimeCacheStrategy class] forKey:@"period"];
        [_globalStategties setValue:[TSPKRuleCacheStrategy class] forKey:@"rule"];
    }
    return self;
}

+ (instancetype)sharedFactory {
    static TSPKCacheStrategyFactory *factory;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        factory = [[TSPKCacheStrategyFactory alloc] init];
    });
    return factory;
}

- (id<TSPKCacheUpdateStrategy>)getStrategy:(NSString *)name params:(NSDictionary *)params {
    return [[self.globalStategties objectForKey:name] generate:params];
}

+ (id<TSPKCacheUpdateStrategy>)getStrategy:(NSString *)name params:(NSDictionary *)params{
    return [[TSPKCacheStrategyFactory sharedFactory] getStrategy:name params:params];
}

+ (void)addStrategy:(id<TSPKCacheUpdateStrategy> _Nullable)strategy withKey:(NSString *)key
{
    [[TSPKCacheStrategyFactory sharedFactory] addStrategy:strategy withKey:key];
}

- (void)addStrategy:(id<TSPKCacheUpdateStrategy> _Nullable)strategy withKey:(NSString *)key
{
    [_globalStategties setValue:[strategy class] forKey:key];
}

@end
