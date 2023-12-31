//
//  NSDictionary+CJExtension.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/22.
//

#import "NSDictionary+CJPay.h"

@implementation NSDictionary(CJPay)

- (id)cj_objectForKey:(NSString *)key defaultObj:(nullable id)defaultObj {
    id obj = [self objectForKey:key];
    return obj ? obj : defaultObj;
}

- (int)cj_intValueForKey:(NSString *)key defaultValue:(int)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value intValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value intValue] : defaultValue;
}

- (NSInteger)cj_integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value integerValue] : defaultValue;
}

- (float)cj_floatValueForKey:(NSString *)key defaultValue:(float)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value floatValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value floatValue] : defaultValue;
}

- (double)cj_doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value doubleValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [(NSNumber *)value doubleValue] : defaultValue;
}

- (NSString *)cj_stringValueForKey:(NSString *)key defaultValue:(nullable NSString *)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    }else if(value && [value isKindOfClass:[NSNumber class]]){
        return [value stringValue];
    }else{
        return defaultValue;
    }
}

- (NSArray *)cj_arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSArray class]]) ? value : defaultValue;
}

- (NSDictionary *)cj_dictionaryValueForKey:(NSString *)key defalutValue:(NSDictionary *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSDictionary class]]) ? value : defaultValue;
}

- (NSData *)cj_dataValueForKey:(NSString *)key defalutValue:(NSData *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSData class]]) ? value : defaultValue;
}

- (id)cj_objectForKey:(NSString *)key {
    return [self cj_objectForKey:key defaultObj:nil];
}

- (int)cj_intValueForKey:(NSString *)key {
    return [self cj_intValueForKey:key defaultValue:0];
}

- (NSInteger)cj_integerValueForKey:(NSString *)key {
    return [self cj_integerValueForKey:key defaultValue:0];
}

- (float)cj_floatValueForKey:(NSString *)key {
    return [self cj_floatValueForKey:key defaultValue:0.f];
}

- (double)cj_doubleValueForKey:(NSString *)key {
    return [self cj_doubleValueForKey:key defaultValue:0.f];
}

- (BOOL)cj_boolValueForKey:(NSString *)key {
    return [self cj_integerValueForKey:key defaultValue:0] != 0;
}

- (NSString *)cj_stringValueForKey:(NSString *)key {
    return [self cj_stringValueForKey:key defaultValue:nil];
}

- (NSArray *)cj_arrayValueForKey:(NSString *)key {
    return [self cj_arrayValueForKey:key defaultValue:nil];
}

- (NSDictionary *)cj_dictionaryValueForKey:(NSString *)key {
    return [self cj_dictionaryValueForKey:key defalutValue:nil];
}

- (NSData *)cj_dataValueForKey:(NSString *)key {
    return [self cj_dataValueForKey:key defalutValue:nil];
}

- (NSDictionary *)cj_mergeDictionary:(NSDictionary *)toMergeDic {
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionaryWithDictionary:self];
    [mutableDic addEntriesFromDictionary:toMergeDic];
    return [mutableDic copy];
}

- (nullable NSString *)cj_toStr {
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
