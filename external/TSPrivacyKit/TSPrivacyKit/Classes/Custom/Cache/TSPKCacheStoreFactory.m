//
//  TSPKCacheStoreFactory.m
//  BDRuleEngine-Pods-Baymax_MusicallyTests-Unit-_Tests
//
//  Created by admin on 2022/7/8.
//

#import "TSPKCacheStoreFactory.h"
#import "TSPKMemoryStore.h"

static NSString *const TSPKCacheStoreTypeMemory = @"memory";

@interface TSPKCacheStoreFactory ()

@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, id<TSPKCacheStore>> *globalStores;

@end

@implementation TSPKCacheStoreFactory

- (instancetype)init
{
    self = [super init];
    if (self) {
        _globalStores = [NSMutableDictionary dictionary];
        [_globalStores setValue:[TSPKMemoryStore new] forKey:TSPKCacheStoreTypeMemory];
    }
    return self;
}

+ (instancetype)sharedFactory {
    static TSPKCacheStoreFactory *factory;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        factory = [[TSPKCacheStoreFactory alloc] init];
    });
    return factory;
}

- (id<TSPKCacheStore>)getStore:(NSString *)name {
    if ([name isEqualToString:TSPKCacheStoreTypeMemory]) {
        return [self.globalStores objectForKey:name];
    }
    return nil;
}

+ (id)getStore:(NSString *)name {
    return [[TSPKCacheStoreFactory sharedFactory] getStore:name];
}

@end
