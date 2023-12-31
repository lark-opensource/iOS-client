//
//  MemoryTestCacheStorage.m
//  IESPrefetch-Unit-Tests
//
//  Created by yuanyiyang on 2019/12/18.
//

#import "MemoryTestCacheStorage.h"

@implementation MemoryCacheTestStorage

- (instancetype)init
{
    if (self = [super init]) {
        _storage = [NSMutableDictionary new];
    }
    return self;
}

- (void)saveObject:(NSDictionary *)object forKey:(NSString *)key
{
    self.storage[key] = object;
}

- (void)removeObjectForKey:(NSString *)key
{
    self.storage[key] = nil;
}

- (NSDictionary *)fetchObjectForKey:(NSString *)key
{
    return self.storage[key];
}

- (NSArray<NSString *> *)fetchAllKeys
{
    return self.storage.allKeys;
}

@end
