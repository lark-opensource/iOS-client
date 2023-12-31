//
//  TTKitchenMMKVStorageSchema.m
//  TTKitchen-Core
//
//  Created by liujinxing on 2020/10/10.
//

#import "TTKitchenMMKVDiskCache.h"
#import <ByteDanceKit/BTDMacros.h>
#import <BDAssert/BDAssert.h>
#import <MMKV/MMKV.h>

@interface TTKitchenMMKVDiskCache ()

@property (nonatomic, strong) MMKV *kitchenMMKVCache;

@end

@implementation TTKitchenMMKVDiskCache

TTKitchenDiskCacheRegisterFunction(){
    if (!TTKitchenManager.diskCache){
        TTKitchenManager.diskCache = TTKitchenMMKVDiskCache.new;
    }
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _kitchenMMKVCache = [MMKV mmkvWithID:@"TTKitchen"];
    }
    return self;
}

- (nullable id)getObjectOfClass:(Class)cls forKey:(NSString *)key {
    if (TTKitchenManager.keyMonitor) {
        [TTKitchenManager.keyMonitor kitchenWillGetKey:key];
    }
    return [self.kitchenMMKVCache getObjectOfClass:cls forKey:key];
}
- (void)setObject:(nullable NSObject <NSCoding> *)Object forKey:(NSString *)key {
    [self.kitchenMMKVCache setObject:Object forKey:key];
}

- (BOOL)containsObjectForKey:(NSString *)key {
    return [self.kitchenMMKVCache containsKey:key];
}
- (void)removeObjectForKey:(NSString *)key {
    [self.kitchenMMKVCache removeValueForKey:key];
}

- (void)addEntriesFromDictionary:(NSDictionary<NSString *,id<NSCoding>> *)dictionary {
    @weakify(self);
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nonnull obj, BOOL * _Nonnull stop) {
        @strongify(self);
        [self.kitchenMMKVCache setObject:(NSObject <NSCoding> *)obj forKey:key];
    }];
}

- (void)clearAll {
    [self.kitchenMMKVCache clearAll];
}

@end
