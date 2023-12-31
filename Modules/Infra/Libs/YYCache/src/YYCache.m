//
//  YYCache.m
//  YYCache <https://github.com/ibireme/YYCache>
//
//  Created by ibireme on 15/2/13.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import "YYCache.h"
#import "YYMemoryCache.h"
#import "YYDiskCache.h"

@implementation YYCache

- (instancetype) init {
    NSLog(@"Use \"initWithName\" or \"initWithPath\" to create YYCache instance.");
    return [self initWithPath:@""];
}

- (instancetype)initWithName:(NSString *)name {
    if (name.length == 0) return nil;
    NSString *cacheFolder = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [cacheFolder stringByAppendingPathComponent:name];
    return [self initWithPath:path];
}

- (instancetype)initWithPath:(NSString *)path {
    YYDiskCache *diskCache = [[YYDiskCache alloc] initWithPath:path];
    return [self initWithDiskCache:diskCache];
}

- (instancetype)initWithPath:(NSString *)path inlineThreshold:(NSUInteger)inlineThreshold needAutoTrim:(BOOL)needAutoTrim{
    YYDiskCache *diskCache = [[YYDiskCache alloc] initWithPath:path inlineThreshold:inlineThreshold needAutoTrim: needAutoTrim];
    return [self initWithDiskCache:diskCache];
}

- (instancetype)initWithDiskCache: (YYDiskCache *)diskCache {
    NSString* path = diskCache.path;
    if (path.length == 0) return nil;
    if (!diskCache) return nil;
    NSString *name = [path lastPathComponent];
    YYMemoryCache *memoryCache = [YYMemoryCache new];
    memoryCache.name = name;

    self = [super init];
    _name = name;
    _diskCache = diskCache;
    _memoryCache = memoryCache;
    return self;
}

+ (instancetype)cacheWithName:(NSString *)name {
    return [[self alloc] initWithName:name];
}

+ (instancetype)cacheWithPath:(NSString *)path {
    return [[self alloc] initWithPath:path];
}

- (BOOL)containsObjectForKey:(NSString *)key {
    return [_memoryCache containsObjectForKey:key exceptObject:[NSNull null]] || [_diskCache containsObjectForKey:key];
}

- (void)containsObjectForKey:(NSString *)key withBlock:(void (^)(NSString *key, BOOL contains))block {
    if (!block) return;

    if ([_memoryCache containsObjectForKey:key exceptObject:[NSNull null]]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(key, YES);
        });
    } else  {
        [_diskCache containsObjectForKey:key withBlock:block];
    }
}

- (id<NSCoding>)objectForKey:(NSString *)key {
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (object == [NSNull null]) {
        return nil;
    }
    if (!object) {
        object = [_diskCache objectForKey:key];
        [_memoryCache setObject:object ? : [NSNull null] forKey:key];
    }
    return object;
}

- (void)objectForKey:(NSString *)key withBlock:(void (^)(NSString *key, id<NSCoding> object))block {
    if (!block) return;
    id<NSCoding> object = [_memoryCache objectForKey:key];
    if (object == [NSNull null]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(key, nil);
        });
    } else if (object) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            block(key, object);
        });
    } else {
        [_diskCache objectForKey:key withBlock:^(NSString *key, id<NSCoding> object) {
            if (![_memoryCache objectForKey:key]) {
                [_memoryCache setObject:object ? : [NSNull null] forKey:key];
            }
            block(key, object);
        }];
    }
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key {
    [_memoryCache setObject:object forKey:key];
    [_diskCache setObject:object forKey:key];
}

- (void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void (^)(void))block {
    [_memoryCache setObject:object forKey:key];
    [_diskCache setObject:object forKey:key withBlock:block];
}

- (void)addEntriesFromDictionary:(NSDictionary<NSString *, id<NSCoding>> *)dictionary {
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull obj, BOOL * _Nonnull stop) {
        [_memoryCache setObject:obj forKey:key];
    }];
    [_diskCache addEntriesFromDictionary:dictionary];
}

- (void)removeObjectForKey:(NSString *)key {
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key withBlock:(void (^)(NSString *key))block {
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key withBlock:block];
}

- (void)removeAllObjects {
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjects];
}

- (void)removeAllObjectsWithBlock:(void(^)(void))block {
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsWithBlock:block];
}

- (void)removeAllObjectsWithProgressBlock:(void(^)(int removedCount, int totalCount))progress
                                 endBlock:(void(^)(BOOL error))end {
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsWithProgressBlock:progress endBlock:end];

}

- (NSString *)description {
    if (_name) return [NSString stringWithFormat:@"<%@: %p> (%@)", self.class, self, _name];
    else return [NSString stringWithFormat:@"<%@: %p>", self.class, self];
}

+ (void)setYYCacheLRUDisable:(BOOL)disable {
    [YYKVStorage setYYCacheLRUDisable:disable];
}

+ (void)setYYCacheTrimEnableAfterMemoryWarning:(BOOL)enable expirationSeconds:(NSInteger)expirationSeconds {
    [YYDiskCache setYYCacheTrimEnableAfterMemoryWarning:enable expirationSeconds:expirationSeconds];
}

@end
