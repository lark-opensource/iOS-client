//
//  TTKitchenYYCacheStorageSchema.m
//  TTKitchen-Browser-Core-KeyReporter-SettingsSyncer
//
//  Created by liujinxing on 2020/10/10.
//

#import "TTKitchenYYCacheDiskCache.h"
#import <BDAssert/BDAssert.h>
#import <YYCache/YYCache.h>

@interface TTKitchenYYCacheDiskCache ()

@property (nonatomic, strong) YYCache *kitchenYYCache;

@end

@implementation TTKitchenYYCacheDiskCache

TTKitchenDiskCacheRegisterFunction() {
    if (!TTKitchenManager.diskCache){
        TTKitchenManager.diskCache = TTKitchenYYCacheDiskCache.new;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _kitchenYYCache = [YYCache cacheWithPath:[self cachePath]];
    }
    return self;
}

- (NSString *)cachePath {
    NSString *appSupportFolder = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [appSupportFolder stringByAppendingPathComponent:@"TTKitchen"];
    return path;
}

- (nullable id)getObjectOfClass:(Class)cls forKey:(NSString *)key {
    if (TTKitchenManager.keyMonitor) {
        [TTKitchenManager.keyMonitor kitchenWillGetKey:key];
    }
    return [self.kitchenYYCache objectForKey:key];
}
- (void)setObject:(nullable NSObject <NSCoding> *)Object forKey:(NSString *)key {
    [self.kitchenYYCache setObject:Object forKey:key];
}

- (BOOL)containsObjectForKey:(NSString *)key {
    return [self.kitchenYYCache containsObjectForKey:key];
}
- (void)removeObjectForKey:(NSString *)key {
    [self.kitchenYYCache removeObjectForKey:key];
}
- (void)addEntriesFromDictionary:(NSDictionary<NSString *,id<NSCoding>> *)dictionary {
    [self.kitchenYYCache addEntriesFromDictionary:dictionary];
}

- (void)clearAll {
    [self.kitchenYYCache removeAllObjects];
}

- (void)cleanCacheLog {
    NSString *path = self.kitchenYYCache.diskCache.path;
    NSString *trashPath = [path stringByAppendingPathComponent:@"trash"];
    [[NSFileManager defaultManager] removeItemAtPath:trashPath error:nil];
}

@end
