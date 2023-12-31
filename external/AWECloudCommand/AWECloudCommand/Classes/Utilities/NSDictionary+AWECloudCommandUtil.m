//
//  NSDictionary+AWECloudCommandUtil.m
//  AWECloudCommand
//
//  Created by songxiangwu on 2018/1/3.
//

#import "NSDictionary+AWECloudCommandUtil.h"

@implementation NSDictionary (AWECloudCommandUtil)

- (id)awe_cc_objectForKey:(NSString *)key
{
    return [self awe_cc_objectForKey:key defalutObj:nil];
}

- (id)awe_cc_objectForKey:(id)aKey ofClass:(Class)aClass
{
    return [self awe_cc_objectForKey:aKey ofClass:aClass defaultObj:nil];
}

- (int)awe_cc_intValueForKey:(NSString *)key
{
    return [self awe_cc_intValueForKey:key defaultValue:0];
}

- (NSInteger)awe_cc_integerValueForKey:(NSString *)key
{
    return [self awe_cc_integerValueForKey:key defaultValue:0];
}

- (NSUInteger)awe_cc_unsignedIntegerValueForKey:(NSString *)key
{
    return [self awe_cc_unsignedIntegerValueForKey:key defaultValue:0];
}

- (float)awe_cc_floatValueForKey:(NSString *)key
{
    return [self awe_cc_floatValueForKey:key defaultValue:0.f];
}

- (double)awe_cc_doubleValueForKey:(NSString *)key
{
    return [self awe_cc_doubleValueForKey:key defaultValue:0.];
}

- (long)awe_cc_longValueForKey:(NSString *)key
{
    return [self awe_cc_longValueForKey:key defaultValue:0];
}

- (long long)awe_cc_longlongValueForKey:(NSString *)key
{
    return [self awe_cc_longlongValueForKey:key defaultValue:0];
}

- (BOOL)awe_cc_boolValueForKey:(NSString *)key
{
    return [self awe_cc_integerValueForKey:key defaultValue:0] != 0;
}

- (NSString *)awe_cc_stringValueForKey:(NSString *)key
{
    return [self awe_cc_stringValueForKey:key defaultValue:nil];
}

- (NSArray *)awe_cc_arrayValueForKey:(NSString *)key
{
    return [self awe_cc_arrayValueForKey:key defaultValue:nil];
}

- (NSDictionary *)awe_cc_dictionaryValueForKey:(NSString *)key
{
    return [self awe_cc_dictionaryValueForKey:key defalutValue:nil];
}

- (NSString*)awe_cc_dictionaryToJson
{
    NSError *parseError = nil;
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&parseError];
    
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
}

- (id)awe_cc_objectForKey:(NSString *)key defalutObj:(id)defaultObj
{
    id obj = [self objectForKey:key];
    return obj ? obj : defaultObj;
}

- (id)awe_cc_objectForKey:(id)aKey ofClass:(Class)aClass defaultObj:(id)defaultObj
{
    id obj = [self objectForKey:aKey];
    return (obj && [obj isKindOfClass:aClass]) ? obj : defaultObj;
}

- (int)awe_cc_intValueForKey:(NSString *)key defaultValue:(int)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value intValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value intValue] : defaultValue;
}

- (NSInteger)awe_cc_integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value integerValue] : defaultValue;
}

- (NSUInteger)awe_cc_unsignedIntegerValueForKey:(NSString *)key defaultValue:(NSUInteger)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return (NSUInteger)[(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value unsignedIntegerValue] : defaultValue;
}

- (double)awe_cc_doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value doubleValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value doubleValue] : defaultValue;
}

- (float)awe_cc_floatValueForKey:(NSString *)key defaultValue:(float)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value floatValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value floatValue] : defaultValue;
}

- (long)awe_cc_longValueForKey:(NSString *)key defaultValue:(long)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value longValue] : defaultValue;
}

- (long long)awe_cc_longlongValueForKey:(NSString *)key defaultValue:(long long)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value longLongValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value longLongValue] : defaultValue;
}

- (NSString *)awe_cc_stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue
{
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    }else if(value && [value isKindOfClass:[NSNumber class]]){
        return [value stringValue];
    }else{
        return defaultValue;
    }
}

- (NSArray *)awe_cc_arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue
{
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSArray class]]) ? value : defaultValue;
}

- (NSDictionary *)awe_cc_dictionaryValueForKey:(NSString *)key defalutValue:(NSDictionary *)defaultValue
{
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSDictionary class]]) ? value : defaultValue;
}

+ (id)awe_cc_dictionaryWithJSONString:(NSString *)inJSON error:(NSError **)outError;
{
    NSData *theData = [inJSON dataUsingEncoding:NSUTF8StringEncoding];
    return[self _dictionaryWithJSONData:theData error:outError];
}

- (id)awe_cc_objectForInsensitiveKey:(NSString *)key {
    __block id object = nil;
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull objKey, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([objKey isKindOfClass:NSString.class]) {
            if ([key caseInsensitiveCompare:objKey] == NSOrderedSame) {
                object = obj;
                *stop = YES;
            }
        }
    }];
    
    return object;
}

+ (id)_dictionaryWithJSONData:(NSData *)inData error:(NSError **)outError
{
    if (inData) {
        return [NSJSONSerialization JSONObjectWithData:inData options:NSJSONReadingAllowFragments error:outError];
    } else {
        return nil;
    }
}

@end
