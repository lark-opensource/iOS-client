//
//  PNSKVStoreImpl.m
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/20.
//

#import "PNSKVStoreImpl.h"
#import "PNSServiceCenter+private.h"
#import <MMKV/MMKV.h>

PNS_BIND_DEFAULT_SERVICE(PNSKVStoreImpl, PNSKVStoreProtocol)

@implementation PNSKVStoreImpl

+ (BOOL)setString:(NSString * _Nullable)value
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] setString:value forKey:key];
}

+ (BOOL)setObject:(NSObject<NSCoding> * _Nullable)object
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] setObject:object forKey:key];
}

+ (nullable NSString *)stringForKey:(NSString * _Nonnull)key
                           uniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] getStringForKey:key];
}

+ (nullable id)objectOfClass:(Class _Nonnull)cls
                      forKey:(NSString * _Nonnull)key
                    uniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] getObjectOfClass:cls forKey:key];
}

+ (nullable NSArray *)allKeysWithUniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] allKeys];
}

+ (void)clearAllWithUniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] clearAll];
}

+ (void)closeWithUniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] close];
}

+ (BOOL)containsKey:(NSString * _Nonnull)key uniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] containsKey:key];
}

+ (void)removeValueForKey:(NSString * _Nullable)key uniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] removeValueForKey:key];
}

+ (MMKV *)mmkvWithID:(NSString *)uniqueID {
    return [MMKV mmkvWithID:uniqueID] ? : [MMKV defaultMMKV];
}

// initialize takes about 1ms
+ (void)initializeKVStore {
    if ([NSThread isMainThread]) {
        [MMKV initializeMMKV:nil];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MMKV initializeMMKV:nil];
        });
    }
}

@end
