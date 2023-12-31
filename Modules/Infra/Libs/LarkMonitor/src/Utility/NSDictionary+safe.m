//
//  NSDictionary+safe.m
//  LarkMonitor
//
//  Created by sniperj on 2020/11/8.
//

#import "NSDictionary+safe.h"

@implementation NSDictionary (safe)

+ (NSDictionary *)lk_dictionaryWithObject:(id)anObject forKey:(id<NSCopying>)aKey{
    if(anObject && aKey){
        return [NSDictionary dictionaryWithObject:anObject forKey:aKey];
    } else {
        return nil;
    }
}

- (BOOL)lk_hasKey:(id<NSCopying>)key
{
    return [self lk_safeObjectForKey:key] != nil;
}

- (id)lk_safeObjectForKey:(id<NSCopying>)key
{
    if (key == nil) {
        return nil;
    }
    return [self objectForKey:key];
}

- (id _Nullable)lk_objectForKey:(id<NSCopying>)key class:(Class)clazz
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:clazz]) {
        return obj;
    }
    return nil;
}

- (NSString * _Nullable)lk_stringForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj stringValue];
    }
    return nil;
}

- (int)lk_intForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj intValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj intValue];
    }
    return 0;
}

- (unsigned int)lk_unsignedIntForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj unsignedIntValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj unsignedIntValue];
    }
    return 0;
}

- (NSInteger)lk_integerForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj integerValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj integerValue];
    }
    return 0;
}

- (BOOL)lk_boolForKey:(id<NSCopying>)key {
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj boolValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj boolValue];
    }
    return NO;
}

- (NSUInteger)lk_unsignedIntegerForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj unsignedIntegerValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj unsignedIntegerValue];
    }
    return 0;
}

- (long)lk_longForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj longValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj longValue];
    }
    return 0;
}

- (unsigned long)lk_unsignedLongForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj unsignedLongValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj unsignedLongValue];
    }
    return 0;
}

- (long long)lk_longLongForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj longLongValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj longLongValue];
    }
    return 0;
}

- (unsigned long long)lk_unsignedLongLongForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj unsignedLongLongValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj unsignedLongLongValue];
    }
    return 0;
}

- (float)lk_floatForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj floatValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj floatValue];
    }
    return 0.0f;
}

- (double)lk_doubleForKey:(id<NSCopying>)key
{
    id obj = [self lk_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return [obj doubleValue];
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj doubleValue];
    }
    return 0.0;
}

- (NSDictionary *)lk_dictForKey:(id<NSCopying>)key
{
    id obj = [self lk_objectForKey:key class:[NSDictionary class]];
    return obj;
}

- (NSArray *)lk_arrayForKey:(id<NSCopying>)key
{
    id obj = [self lk_objectForKey:key class:[NSArray class]];
    return obj;
}

@end

@implementation NSMutableDictionary (safe)

- (void)lk_setObject:(id)anObject forKey:(id<NSCopying>)aKey
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

- (void)lk_setSafeObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    if (aKey == nil || anObject == nil) {
        return;
    }
    [self setObject:anObject forKey:aKey];
}

@end
