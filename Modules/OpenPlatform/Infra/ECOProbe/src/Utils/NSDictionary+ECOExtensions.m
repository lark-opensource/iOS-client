//
//  NSDictionary+ECOExtensions.m
//  ECOProbe
//
//  Created by qsc on 2021/3/31.
//

#import "NSDictionary+ECOExtensions.h"

@implementation NSDictionary(ECOExtensions)

- (id)objectForKey:(NSString *)key defalutObj:(id)defaultObj
{
    id obj = [self objectForKey:key];
    return obj ? obj : defaultObj;
}

- (id)objectForKey:(id)aKey ofClass:(Class)aClass defaultObj:(id)defaultObj
{
    id obj = [self objectForKey:aKey];
    return (obj && [obj isKindOfClass:aClass]) ? obj : defaultObj;
}

- (int)intValueForKey:(NSString *)key defaultValue:(int)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value intValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value intValue] : defaultValue;
}

- (NSInteger)integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value integerValue] : defaultValue;
}

- (NSUInteger)unsignedIntegerValueForKey:(NSString *)key defaultValue:(NSUInteger)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return (NSUInteger)[(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value unsignedIntegerValue] : defaultValue;
}

- (double)doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value doubleValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value doubleValue] : defaultValue;
}

- (float)floatValueForKey:(NSString *)key defaultValue:(float)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value floatValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value floatValue] : defaultValue;
}

- (long)longValueForKey:(NSString *)key defaultValue:(long)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value longValue] : defaultValue;
}

- (long long)longlongValueForKey:(NSString *)key defaultValue:(long long)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value longLongValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [[(NSNumber *)value stringValue] longLongValue] : defaultValue;
}

- (NSString *)stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    }else if (value && [value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    } else {
        return defaultValue;
    }
}

- (NSArray *)arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue
{
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSArray class]]) ? value : defaultValue;
}

- (NSDictionary *)dictionaryValueForKey:(NSString *)key defalutValue:(NSDictionary *)defaultValue
{
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSDictionary class]]) ? value : defaultValue;
}


- (id)eco_objectForKey:(NSString *)key
{
    return [self objectForKey:key defalutObj:nil];
}

- (id)eco_objectForKey:(id)aKey ofClass:(Class)aClass
{
    return [self objectForKey:aKey ofClass:aClass defaultObj:nil];
}

- (int)eco_intValueForKey:(NSString *)key
{
    return [self intValueForKey:key defaultValue:0];
}

- (NSInteger)eco_integerValueForKey:(NSString *)key
{
    return [self integerValueForKey:key defaultValue:0];
}

- (NSUInteger)eco_unsignedIntegerValueForKey:(NSString *)key
{
    return [self unsignedIntegerValueForKey:key defaultValue:0];
}

- (float)eco_floatValueForKey:(NSString *)key
{
    return [self floatValueForKey:key defaultValue:0.f];
}

- (double)eco_doubleValueForKey:(NSString *)key
{
    return [self doubleValueForKey:key defaultValue:0.];
}

- (long)eco_longValueForKey:(NSString *)key
{
    return [self longValueForKey:key defaultValue:0];
}

- (long long)eco_longlongValueForKey:(NSString *)key
{
    return [self longlongValueForKey:key defaultValue:0];
}

- (BOOL)eco_boolValueForKey:(NSString *)key
{
    return [self integerValueForKey:key defaultValue:0] != 0;
}

- (NSString *)eco_stringValueForKey:(NSString *)key
{
    return [self stringValueForKey:key defaultValue:nil];
}

- (NSArray *)eco_arrayValueForKey:(NSString *)key
{
    return [self arrayValueForKey:key defaultValue:nil];
}

- (NSDictionary *)eco_dictionaryValueForKey:(NSString *)key
{
    return [self dictionaryValueForKey:key defalutValue:nil];
}

@end
