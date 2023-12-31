//
//  NSDictionary+BDNativeWebHelper.m
//  BDNativeWebView
//
//  Created by liuyunxuan on 2019/6/16.
//

#import "NSDictionary+BDNativeWebHelper.h"

@implementation NSDictionary (BDNativeHelper)

- (id)bdNative_objectForKey:(NSString *)key defalutObj:(id)defaultObj
{
    id obj = [self objectForKey:key];
    return obj ? obj : defaultObj;
}

- (id)bdNative_objectForKey:(id)aKey ofClass:(Class)aClass defaultObj:(id)defaultObj {
    id obj = [self objectForKey:aKey];
    return (obj && [obj isKindOfClass:aClass]) ? obj : defaultObj;
}

- (int)bdNative_intValueForKey:(NSString *)key defaultValue:(int)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value intValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value intValue] : defaultValue;
}

- (NSInteger)bdNative_integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value integerValue] : defaultValue;
}

- (NSUInteger)bdNative_unsignedIntegerValueForKey:(NSString *)key defaultValue:(NSUInteger)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return (NSUInteger)[(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value unsignedIntegerValue] : defaultValue;
}

- (double)bdNative_doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value doubleValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value doubleValue] : defaultValue;
}

- (float)bdNative_floatValueForKey:(NSString *)key defaultValue:(float)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value floatValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value floatValue] : defaultValue;
}

- (long)bdNative_longValueForKey:(NSString *)key defaultValue:(long)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value longValue] : defaultValue;
}

- (long long)bdNative_longlongValueForKey:(NSString *)key defaultValue:(long long)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value longLongValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value longLongValue] : defaultValue;
}

- (NSString *)bdNative_stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    }else if(value && [value isKindOfClass:[NSNumber class]]){
        return [value stringValue];
    }else{
        return defaultValue;
    }
}

- (NSArray *)bdNative_arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSArray class]]) ? value : defaultValue;
}

- (NSDictionary *)bdNative_dictionaryValueForKey:(NSString *)key defalutValue:(NSDictionary *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSDictionary class]]) ? value : defaultValue;
}

- (id)bdNative_objectForKey:(NSString *)key {
    return [self bdNative_objectForKey:key defalutObj:nil];
}

- (id)bdNative_objectForKey:(id)aKey ofClass:(Class)aClass {
    return [self bdNative_objectForKey:aKey ofClass:aClass defaultObj:nil];
}

- (int)bdNative_intValueForKey:(NSString *)key {
    return [self bdNative_intValueForKey:key defaultValue:0];
}

- (NSInteger)bdNative_integerValueForKey:(NSString *)key {
    return [self bdNative_integerValueForKey:key defaultValue:0];
}

- (NSUInteger)bdNative_unsignedIntegerValueForKey:(NSString *)key {
    return [self bdNative_unsignedIntegerValueForKey:key defaultValue:0];
}

- (float)bdNative_floatValueForKey:(NSString *)key {
    return [self bdNative_floatValueForKey:key defaultValue:0.f];
}

- (double)bdNative_doubleValueForKey:(NSString *)key {
    return [self bdNative_doubleValueForKey:key defaultValue:0.];
}

- (long)bdNative_longValueForKey:(NSString *)key {
    return [self bdNative_longValueForKey:key defaultValue:0];
}

- (long long)bdNative_longlongValueForKey:(NSString *)key {
    return [self bdNative_longlongValueForKey:key defaultValue:0];
}

- (BOOL)bdNative_boolValueForKey:(NSString *)key {
    return [self bdNative_integerValueForKey:key defaultValue:0] != 0;
}

- (NSString *)bdNative_stringValueForKey:(NSString *)key {
    return [self bdNative_stringValueForKey:key defaultValue:nil];
}

- (NSArray *)bdNative_arrayValueForKey:(NSString *)key {
    return [self bdNative_arrayValueForKey:key defaultValue:nil];
}

- (NSDictionary *)bdNative_dictionaryValueForKey:(NSString *)key {
    return [self bdNative_dictionaryValueForKey:key defalutValue:nil];
}


- (NSString *)bdNative_JSONRepresentation
{
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:0];
    NSString *dataStr = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    return dataStr;
}
@end
