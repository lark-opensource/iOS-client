//
//  IESPrefetchDefaultCacheStorage.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/9.
//

#import "IESPrefetchDefaultCacheStorage.h"

static NSString * const kIESPrefetchCacheStorageNameKey = @"kIESPrefetchCacheStorageNameKey";

@interface IESPrefetchDefaultCacheStorage ()

@property(nonatomic, strong) NSUserDefaults *userDefaults;

@end

@implementation IESPrefetchDefaultCacheStorage

- (instancetype)initWithSuite:(NSString *)suite
{
    if (self = [super init]) {
        NSString *key = [NSString stringWithFormat:@"%@_%@", kIESPrefetchCacheStorageNameKey, suite];
        _userDefaults = [[NSUserDefaults alloc] initWithSuiteName:key];
    }
    return self;
}

- (void)saveObject:(NSDictionary *)object forKey:(NSString *)key
{
    if (key.length == 0) {
        return;
    }
    [self.userDefaults setObject:object forKey:key];
}

- (NSDictionary *)fetchObjectForKey:(NSString *)key
{
    NSDictionary *data = [self.userDefaults dictionaryForKey:key];
    return data;
}

- (void)removeObjectForKey:(NSString *)key
{
    if (key.length == 0) {
        return;
    }
    [self.userDefaults removeObjectForKey:key];
}

- (NSArray<NSString *> *)fetchAllKeys
{
    return [[self.userDefaults dictionaryRepresentation] allKeys];
}

@end
