//
//  NSDictionary+AWEAdditions.m
//  Pods
//
//  Created by Stan Shan on 2018/6/14.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "NSDictionary+AWEAdditions.h"

@implementation NSDictionary (AWEAdditions)

- (id)awe_objectForKey:(NSString *)key {
    return [self awe_objectForKey:key defalutObj:nil];
}

- (id)awe_objectForKey:(id)aKey ofClass:(Class)aClass {
    return [self awe_objectForKey:aKey ofClass:aClass defaultObj:nil];
}

- (int)awe_intValueForKey:(NSString *)key {
    return [self awe_intValueForKey:key defaultValue:0];
}

- (NSInteger)awe_integerValueForKey:(NSString *)key {
    return [self awe_integerValueForKey:key defaultValue:0];
}

- (NSUInteger)awe_unsignedIntegerValueForKey:(NSString *)key {
    return [self awe_unsignedIntegerValueForKey:key defaultValue:0];
}

- (float)awe_floatValueForKey:(NSString *)key {
    return [self awe_floatValueForKey:key defaultValue:0.f];
}

- (double)awe_doubleValueForKey:(NSString *)key {
    return [self awe_doubleValueForKey:key defaultValue:0.];
}

- (long)awe_longValueForKey:(NSString *)key {
    return [self awe_longValueForKey:key defaultValue:0];
}

- (long long)awe_longlongValueForKey:(NSString *)key {
    return [self awe_longlongValueForKey:key defaultValue:0];
}

- (BOOL)awe_boolValueForKey:(NSString *)key {
    return [self awe_integerValueForKey:key defaultValue:0] != 0;
}

- (NSString *)awe_stringValueForKey:(NSString *)key {
    return [self awe_stringValueForKey:key defaultValue:nil];
}

- (NSNumber *)awe_numberValueForKey:(NSString *)key {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSNumber class]]) {
        return value;
    } else {
        return nil;
    }
}

- (NSArray *)awe_arrayValueForKey:(NSString *)key {
    return [self awe_arrayValueForKey:key defaultValue:nil];
}

- (NSDictionary *)awe_dictionaryValueForKey:(NSString *)key {
    return [self awe_dictionaryValueForKey:key defalutValue:nil];
}

- (NSString*)awe_dictionaryToJson
{
    NSError *parseError = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}

- (id)awe_objectForKey:(NSString *)key defalutObj:(id)defaultObj {
    id obj = [self objectForKey:key];
    return obj ? obj : defaultObj;
}

- (id)awe_objectForKey:(id)aKey ofClass:(Class)aClass defaultObj:(id)defaultObj {
    id obj = [self objectForKey:aKey];
    return (obj && [obj isKindOfClass:aClass]) ? obj : defaultObj;
}

- (int)awe_intValueForKey:(NSString *)key defaultValue:(int)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value intValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value intValue] : defaultValue;
}

- (NSInteger)awe_integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value integerValue] : defaultValue;
}

- (NSUInteger)awe_unsignedIntegerValueForKey:(NSString *)key defaultValue:(NSUInteger)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return (NSUInteger)[(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value unsignedIntegerValue] : defaultValue;
}

- (double)awe_doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value doubleValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value doubleValue] : defaultValue;
}

- (float)awe_floatValueForKey:(NSString *)key defaultValue:(float)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value floatValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value floatValue] : defaultValue;
}

- (long)awe_longValueForKey:(NSString *)key defaultValue:(long)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value longValue] : defaultValue;
}

- (long long)awe_longlongValueForKey:(NSString *)key defaultValue:(long long)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value longLongValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value longLongValue] : defaultValue;
}

- (NSString *)awe_stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    }else if(value && [value isKindOfClass:[NSNumber class]]){
        return [value stringValue];
    }else{
        return defaultValue;
    }
}

- (NSArray *)awe_arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSArray class]]) ? value : defaultValue;
}

- (NSDictionary *)awe_dictionaryValueForKey:(NSString *)key defalutValue:(NSDictionary *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSDictionary class]]) ? value : defaultValue;
}

@end
