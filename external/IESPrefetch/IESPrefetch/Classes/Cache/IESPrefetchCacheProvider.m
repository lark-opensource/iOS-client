//
//  IESPrefetchCacheProvider.m
//  IESPrefetch
//
//  Created by yuanyiyang on 2019/12/9.
//

#import "IESPrefetchCacheProvider.h"
#import "IESPrefetchMonitorService.h"
#import "IESPrefetchCacheStorageProtocol.h"
#import "IESPrefetchLogger.h"
#import "IESPrefetchCacheModel+RequestModel.h"

static NSString * const kIESPrefetchCacheRequestKey = @"__request";

@interface IESPrefetchCacheProvider ()

@property (nonatomic, weak) id<IESPrefetchCacheStorageProtocol> storage;

@end

@implementation IESPrefetchCacheProvider

- (instancetype)initWithCacheStorage:(id<IESPrefetchCacheStorageProtocol>)storage
{
    if (storage == nil) {
        PrefetchCacheLogE(@"storage should not be nil.");
        return nil;
    }
    if ([storage respondsToSelector:@selector(saveObject:forKey:)] == NO) {
        PrefetchCacheLogE(@"storage should implement saveObject:forKey:");
        return nil;
    }
    if ([storage respondsToSelector:@selector(fetchObjectForKey:)] == NO) {
        PrefetchCacheLogE(@"storage should implement fetchObjectForKey:");
        return nil;
    }
    if ([storage respondsToSelector:@selector(removeObjectForKey:)] == NO) {
        PrefetchCacheLogE(@"storage should implement removeObjectForKey:");
        return nil;
    }
    if ([storage respondsToSelector:@selector(fetchAllKeys)] == NO) {
        PrefetchCacheLogE(@"storage should implement fetchAllKeys");
        return nil;
    }
    if (self = [super init]) {
        _storage = storage;
    }
    return self;
}

- (void)addCacheWithModel:(IESPrefetchCacheModel *)model forKey:(NSString *)key {
    NSMutableDictionary *data = [[model jsonSerializationDictionary] mutableCopy];
    if (model.requestDescription.length > 0 && data != nil) {
        data[kIESPrefetchCacheRequestKey] = model.requestDescription;
    }
    if (data) {
        PrefetchCacheLogD(@"save cache for key: %@", key);
        [self.storage saveObject:[data copy] forKey:key];
    }
}

- (IESPrefetchCacheModel *)fetchForKey:(NSString *)key
{
    NSDictionary *data = [self.storage fetchObjectForKey:key];
    if (data == nil) {
        PrefetchCacheLogD(@"cache for key: %@ does not exists", key);
        return nil;
    }
    if (![data isKindOfClass:[NSDictionary class]]) {
        PrefetchCacheLogW(@"cache for key: %@ is malformatted, will be removed", key);
        [self.storage removeObjectForKey:key];
        return nil;
    }
    IESPrefetchCacheModel *model = [[IESPrefetchCacheModel alloc] initWithDictionary:data];
    if (data != nil && [data isKindOfClass:[NSDictionary class]] && data[kIESPrefetchCacheRequestKey]) {
        model.requestDescription = data[kIESPrefetchCacheRequestKey];
    }
    return model;
}

- (IESPrefetchCacheModel *)modelForKey:(NSString *)key {
    IESPrefetchCacheModel *model = [self fetchForKey:key];
    if (!model) {
        return nil;
    }
    if ([model hasExpired]) {
        PrefetchCacheLogD(@"cache for key: %@ expired, will be removed", key);
        [self.storage removeObjectForKey:key];
        return nil;
    }
    return model;
}

- (void)cleanExpiredDataIfNeed {
    [[self.storage fetchAllKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESPrefetchCacheModel *model = [self modelForKey:obj];
        if (!model || [model hasExpired]) {
            [self.storage removeObjectForKey:obj];
        }
    }];
}

- (NSArray<IESPrefetchCacheModel *> *)allCaches
{
    NSMutableArray<IESPrefetchCacheModel *> *caches = [NSMutableArray new];
    [[self.storage fetchAllKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        IESPrefetchCacheModel *model = [self fetchForKey:obj];
        if (model != nil) {
            [caches addObject:model];
        }
    }];
    return [caches copy];
}

@end
