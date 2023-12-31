//
//  BDRuleEngineKVStore.m
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/6/24.
//

#import "BDRuleEngineKVStore.h"

#import <PNSServiceKit/PNSKVStoreProtocol.h>

@implementation BDRuleEngineKVStore

+ (Class<PNSKVStoreProtocol>)store
{
    static Class<PNSKVStoreProtocol> store;
    if (!store) {
        store = PNSKVStoreClass;
    }
    return store;
}

+ (BOOL)setString:(NSString * _Nullable)value
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID
{
    return [[self store] setString:value forKey:key uniqueID:uniqueID];
}

+ (BOOL)setObject:(NSObject<NSCoding> * _Nullable)object
           forKey:(NSString * _Nonnull)key
         uniqueID:(NSString * _Nullable)uniqueID
{
    return [[self store] setObject:object forKey:key uniqueID:uniqueID];
}

+ (nullable NSString *)stringForKey:(NSString * _Nonnull)key
                           uniqueID:(NSString * _Nullable)uniqueID
{
    return [[self store] stringForKey:key uniqueID:uniqueID];
}

+ (nullable id)objectOfClass:(Class _Nonnull)cls
                      forKey:(NSString * _Nonnull)key
                    uniqueID:(NSString * _Nullable)uniqueID
{
    return [[self store] objectOfClass:cls forKey:key uniqueID:uniqueID];
}

+ (void)removeValueForKey:(NSString *_Nullable)key
                 uniqueID:(NSString * _Nullable)uniqueID
{
    [[self store] removeValueForKey:key uniqueID:uniqueID];
}

+ (BOOL)containsKey:(NSString *_Nonnull)key
           uniqueID:(NSString * _Nullable)uniqueID
{
    return [[self store] containsKey:key uniqueID:uniqueID];
}

+ (nullable NSArray *)allKeysWithUniqueID:(NSString * _Nullable)uniqueID
{
    return [[self store] allKeysWithUniqueID:uniqueID];
}

+ (void)clearAllWithUniqueID:(NSString * _Nullable)uniqueID
{
    [[self store] clearAllWithUniqueID:uniqueID];
}

+ (void)closeWithUniqueID:(NSString * _Nullable)uniqueID
{
    [[self store] closeWithUniqueID:uniqueID];
}

@end
