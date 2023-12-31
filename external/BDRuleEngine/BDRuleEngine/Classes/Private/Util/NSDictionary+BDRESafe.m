//
//  NSDictionary+BDRESafe.m
//  BDRuleEngine-Pods-AwemeCore
//
//  Created by PengYan on 2021/12/10.
//

#import "NSDictionary+BDRESafe.h"

@implementation NSDictionary (BDRESafe)

- (id)bdre_safeObjectForKey:(id<NSCopying>)key
{
    if (key == nil) {
        return nil;
    }
    return [self objectForKey:key];
}

- (id)bdre_objectForKey:(id<NSCopying>)key class:(Class)clazz
{
    id obj = [self bdre_safeObjectForKey:key];
    if ([obj isKindOfClass:clazz]) {
        return obj;
    }
    return nil;
}

- (NSNumber *)bdre_numberForKey:(id<NSCopying>)key
{
    id obj = [self bdre_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)obj;
    }
    return nil;
}

- (NSString *)bdre_stringForKey:(id<NSCopying>)key
{
    id obj = [self bdre_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSString class]]) {
        return obj;
    }
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)obj stringValue];
    }
    return nil;
}

- (BOOL)bdre_boolForKey:(id<NSCopying>)key
{
    id obj = [self bdre_safeObjectForKey:key];
    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj boolValue];
    }
    return NO;
}

- (NSDictionary *)bdre_dictForKey:(id<NSCopying>)key
{
    id obj = [self bdre_objectForKey:key class:[NSDictionary class]];
    return obj;
}

- (NSArray *)bdre_arrayForKey:(id<NSCopying>)key
{
    id obj = [self bdre_objectForKey:key class:[NSArray class]];
    return obj;
}

@end
