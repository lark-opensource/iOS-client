//
//  NSDictionary+HMDSafe.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/14.
//

#import "NSDictionary+HMDSafe.h"

@implementation NSDictionary (HMDSafe)

+ (NSDictionary *)hmd_dictionaryWithObject:(id)anObject forKey:(id<NSCopying>)aKey{
    if(anObject && aKey){
        return [NSDictionary dictionaryWithObject:anObject forKey:aKey];
    } else {
        return nil;
    }
}

- (BOOL)hmd_hasKey:(id<NSCopying>)key
{
    return [self hmd_safeObjectForKey:key] != nil;
}

- (id)hmd_safeObjectForKey:(id<NSCopying>)key
{
    if (key == nil) {
        return nil;
    }
    return [self objectForKey:key];
}

- (id _Nullable)hmd_objectForKey:(id<NSCopying>)key class:(Class)clazz
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:clazz]) {
        return obj;
    }
    return nil;
}

- (NSString * _Nullable)hmd_stringForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj stringValue];
    }
    return nil;
}

- (int)hmd_intForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [(NSString *)obj intValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj intValue];
    }
    return 0;
}

- (unsigned int)hmd_unsignedIntForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return (unsigned int)[(NSString *)obj intValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj unsignedIntValue];
    }
    return 0;
}

- (NSInteger)hmd_integerForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [(NSString *)obj integerValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj integerValue];
    }
    return 0;
}

- (BOOL)hmd_boolForKey:(id<NSCopying>)key {
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [(NSString *)obj boolValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj boolValue];
    }
    return NO;
}

- (NSUInteger)hmd_unsignedIntegerForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return (NSUInteger)[(NSString *)obj integerValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj unsignedIntegerValue];
    }
    return 0;
}

- (long)hmd_longForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return (long)[(NSString *)obj longLongValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj longValue];
    }
    return 0;
}

- (unsigned long)hmd_unsignedLongForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return (unsigned long)[(NSString *)obj longLongValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj unsignedLongValue];
    }
    return 0;
}

- (long long)hmd_longLongForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [(NSString *)obj longLongValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj longLongValue];
    }
    return 0;
}

- (unsigned long long)hmd_unsignedLongLongForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return (unsigned long long)[(NSString *)obj longLongValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj unsignedLongLongValue];
    }
    return 0;
}

- (float)hmd_floatForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [(NSString *)obj floatValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj floatValue];
    }
    return 0.0f;
}

- (double)hmd_doubleForKey:(id<NSCopying>)key
{
    id obj = [self hmd_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [(NSString *)obj doubleValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj doubleValue];
    }
    return 0.0;
}

- (NSDictionary *)hmd_dictForKey:(id<NSCopying>)key
{
    id obj = [self hmd_objectForKey:key class:[NSDictionary class]];
    return obj;
}

- (NSArray *)hmd_arrayForKey:(id<NSCopying>)key
{
    id obj = [self hmd_objectForKey:key class:[NSArray class]];
    return obj;
}

@end

@implementation NSMutableDictionary (HMDSafe)

- (void)hmd_addEntriesFromDict:(NSDictionary *)dict
{
    if (dict && [dict isKindOfClass:dict.class] && dict.count) {
        [self addEntriesFromDictionary:dict];
    }
}

- (void)hmd_setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    if (aKey == nil) {
        return;
    }
    if (anObject) {
        [self setObject:anObject forKey:aKey];
    }else{
        [self removeObjectForKey:aKey];
    }
}

- (void)hmd_setSafeObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    if (aKey == nil || anObject == nil) {
        return;
    }
    [self setObject:anObject forKey:aKey];
}

- (void)hmd_setCollection:(id)aCollection forKey:(id<NSCopying>)aKey
{
    if (aKey == nil || aCollection == nil) {
        return;
    }
    if ([aCollection respondsToSelector:@selector(count)] && [aCollection count] > 0) {
        [self setObject:aCollection forKey:aKey];
    }
}

@end
