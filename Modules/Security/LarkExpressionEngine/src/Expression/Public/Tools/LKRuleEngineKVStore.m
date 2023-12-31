//
//  LKRuleEngineKVStore.m
//  LarkExpressionEngine
//
//  Created by 汤泽川 on 2022/8/9.
//

#import "LKRuleEngineKVStore.h"
#import <MMKV/MMKV.h>

// ignoring lark storage check for global expression rule engine
// lint:disable lark_storage_check

static NSMutableDictionary<NSString *, MMKV *> *mmkvMap;
static NSString *defaultMMKVID = @"com.lkre.cache.map";
static dispatch_semaphore_t semaphore;

@implementation LKRuleEngineKVStore

+ (BOOL)setObject:(NSObject<NSCoding> * _Nullable)object
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] setObject:object forKey:key];
}

+ (nullable id)objectOfClass:(Class _Nonnull)cls
                      forKey:(NSString * _Nonnull)key
                    uniqueID:(NSString * _Nullable)uniqueID {
    return [[self mmkvWithID:uniqueID] getObjectOfClass:cls forKey:key];
}

+ (MMKV *)mmkvWithID:(NSString *)uniqueID {
    if (!mmkvMap) {
        mmkvMap = [NSMutableDictionary new];
    }
    
    if (!semaphore) {
        semaphore = dispatch_semaphore_create(1);
    }
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    NSString *mmkvID = uniqueID.length > 0 ? uniqueID : defaultMMKVID;
    MMKV *mmkv = [mmkvMap objectForKey:mmkvID];
    
    if (!mmkv) {
        mmkv = [MMKV mmkvWithID:mmkvID];
        [mmkvMap setObject:mmkv forKey:mmkvID];
    }
    dispatch_semaphore_signal(semaphore);
    
    return mmkv;
}

@end
