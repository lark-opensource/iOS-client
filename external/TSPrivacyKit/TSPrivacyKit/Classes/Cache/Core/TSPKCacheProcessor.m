//
//  TSPKCacheProcessor.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/6/28.
//

#import "TSPKCacheProcessor.h"


@interface TSPKCacheProcessor ()

@property (nonatomic, strong, nonnull) id<TSPKCacheStore> store;
@property (nonatomic, strong, nonnull) id<TSPKCacheUpdateStrategy> strategy;

@end

@implementation TSPKCacheProcessor

+ (instancetype)initWithStrategy:(id<TSPKCacheUpdateStrategy>)strategy store:(id<TSPKCacheStore>)store {
    TSPKCacheProcessor *processer = [TSPKCacheProcessor new];
    processer.store = store;
    processer.strategy = strategy;
    return processer;
}

- (BOOL)needUpdate:(NSString *)key {    
    return [self.strategy needUpdate:key cacheStore:self.store];
}

- (id)get:(NSString *)api {
    return [self.store get:api];
}

- (void)updateCache:(NSString *)key newValue:(nullable id)value {
    [self.store put:key value:value];
}

@end
