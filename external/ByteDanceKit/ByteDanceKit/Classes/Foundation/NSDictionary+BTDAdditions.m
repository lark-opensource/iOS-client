//
//  NSDictionary+BTDAdditions.m
//  ByteDanceKit
//
//  Created by wangdi on 2018/2/9.
//

#import "NSDictionary+BTDAdditions.h"
#import "NSObject+BTDAdditions.h"
#import "NSString+BTDAdditions.h"

#define RETURN_VALUE(_type_, _key_, _def_)                                                     \
if (!_key_) return _def_;                                                            \
id value = self[_key_];                                                            \
if (!value || value == [NSNull null]) return _def_;                                \
if ([value isKindOfClass:[NSNumber class]]) return ((NSNumber *)value)._type_;   \
if ([value isKindOfClass:[NSString class]]) return NSNumberFromID(value)._type_; \
return _def_;

@implementation NSDictionary (BTDAdditions)

- (NSString *)btd_jsonStringEncoded
{
    NSError *error = nil;
    return [self btd_jsonStringEncoded:&error];
}

- (NSString *)btd_jsonStringEncoded:(NSError *__autoreleasing *)error
{
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:kNilOptions error:error];
        NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        return json;
    }
    return nil;
}

- (NSString *)btd_jsonStringPrettyEncoded {
    if ([NSJSONSerialization isValidJSONObject:self]) {
        NSError *error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&error];
        if (error == nil) {
            NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
            return json;
        }
    }
    return nil;
}

- (NSString *)btd_safeJsonStringEncoded
{
    id object = [self btd_safeJsonObject];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [object btd_jsonStringEncoded];
    }
    return nil;
}

- (NSString *)btd_safeJsonStringEncoded:(NSError *__autoreleasing *)error
{
    id object = [self btd_safeJsonObject];
    if ([object isKindOfClass:[NSDictionary class]]) {
        return [object btd_jsonStringEncoded:error];
    }
    return nil;
}

/// Get a number value from 'id'.
static NSNumber *NSNumberFromID(id value) {
    static NSCharacterSet *dot;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dot = [NSCharacterSet characterSetWithRange:NSMakeRange('.', 1)];
    });
    if (!value || value == [NSNull null]) return nil;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) {
        NSString *lower = ((NSString *)value).lowercaseString;
        if ([lower isEqualToString:@"true"] || [lower isEqualToString:@"yes"]) return @(YES);
        if ([lower isEqualToString:@"false"] || [lower isEqualToString:@"no"]) return @(NO);
        if ([lower isEqualToString:@"nil"] || [lower isEqualToString:@"null"]) return nil;
        if ([(NSString *)value rangeOfCharacterFromSet:dot].location != NSNotFound) {
            return @(((NSString *)value).doubleValue);
        } else {
            return @(((NSString *)value).longLongValue);
        }
    }
    return nil;
}

- (BOOL)btd_boolValueForKey:(id<NSCopying>)key {
    return [self btd_boolValueForKey:key default:NO];
}

- (int)btd_intValueForKey:(id<NSCopying>)key {
    return [self btd_intValueForKey:key default:0];
}

- (long)btd_longValueForKey:(id<NSCopying>)key {
    return [self btd_longValueForKey:key default:0];
}

- (long long)btd_longlongValueForKey:(id<NSCopying>)key {
    return [self btd_longLongValueForKey:key default:0];
}

- (NSInteger)btd_integerValueForKey:(id<NSCopying>)key {
    return [self btd_integerValueForKey:key default:0];
}

- (NSUInteger)btd_unsignedIntegerValueForKey:(id<NSCopying>)key {
    return [self btd_unsignedIntegerValueForKey:key default:0];
}

- (short)btd_shortValueForKey:(id<NSCopying>)key {
    return [self btd_shortValueForKey:key default:0];
}

- (unsigned short)btd_unsignedShortValueForKey:(id<NSCopying>)key {
    return [self btd_unsignedShortValueForKey:key default:0];
}

- (float)btd_floatValueForKey:(id<NSCopying>)key {
    return [self btd_floatValueForKey:key default:0.0];
}

- (double)btd_doubleValueForKey:(id<NSCopying>)key {
    return [self btd_doubleValueForKey:key default:0.0];
}

- (NSNumber *)btd_numberValueForKey:(id<NSCopying>)key {
    return [self btd_numberValueForKey:key default:nil];
}

- (NSString *)btd_stringValueForKey:(id<NSCopying>)key {
    return [self btd_stringValueForKey:key default:nil];
}

- (nullable NSArray *)btd_arrayValueForKey:(id<NSCopying>)key {
    return [self btd_arrayValueForKey:key default:nil];
}

- (nullable NSDictionary *)btd_dictionaryValueForKey:(id<NSCopying>)key {
    return [self btd_dictionaryValueForKey:key default:nil];
}

- (BOOL)btd_boolValueForKey:(id<NSCopying>)key default:(BOOL)def {
    RETURN_VALUE(boolValue,key,def);
}

- (char)btd_charValueForKey:(id<NSCopying>)key default:(char)def {
    RETURN_VALUE(charValue,key,def);
}

- (unsigned char)btd_unsignedCharValueForKey:(id<NSCopying>)key default:(unsigned char)def {
    RETURN_VALUE(unsignedCharValue,key,def);
}

- (short)btd_shortValueForKey:(id<NSCopying>)key default:(short)def {
    RETURN_VALUE(shortValue,key,def);
}

- (unsigned short)btd_unsignedShortValueForKey:(id<NSCopying>)key default:(unsigned short)def {
    RETURN_VALUE(unsignedShortValue,key,def);
}

- (int)btd_intValueForKey:(id<NSCopying>)key default:(int)def {
    RETURN_VALUE(intValue,key,def);
}

- (unsigned int)btd_unsignedIntValueForKey:(id<NSCopying>)key default:(unsigned int)def {
    RETURN_VALUE(unsignedIntValue,key,def);
}

- (long)btd_longValueForKey:(id<NSCopying>)key default:(long)def {
    RETURN_VALUE(longValue,key,def);
}

- (unsigned long)btd_unsignedLongValueForKey:(id<NSCopying>)key default:(unsigned long)def {
    RETURN_VALUE(unsignedLongValue,key,def);
}

- (long long)btd_longLongValueForKey:(id<NSCopying>)key default:(long long)def {
    RETURN_VALUE(longLongValue,key,def);
}

- (unsigned long long)btd_unsignedLongLongValueForKey:(id<NSCopying>)key default:(unsigned long long)def {
    RETURN_VALUE(unsignedLongLongValue,key,def);
}

- (float)btd_floatValueForKey:(id<NSCopying>)key default:(float)def {
    RETURN_VALUE(floatValue,key,def);
}

- (double)btd_doubleValueForKey:(id<NSCopying>)key default:(double)def {
    RETURN_VALUE(doubleValue,key,def);
}

- (NSInteger)btd_integerValueForKey:(id<NSCopying>)key default:(NSInteger)def {
    RETURN_VALUE(integerValue,key,def);
}

- (NSUInteger)btd_unsignedIntegerValueForKey:(id<NSCopying>)key default:(NSUInteger)def {
    RETURN_VALUE(unsignedIntegerValue,key,def);
}

- (NSNumber *)btd_numberValueForKey:(id<NSCopying>)key default:(NSNumber *)def {
    if (!key) return def;
    id value = self[key];
    if (!value || value == [NSNull null]) return def;
    if ([value isKindOfClass:[NSNumber class]]) return value;
    if ([value isKindOfClass:[NSString class]]) return NSNumberFromID(value);
    return def;
}

- (NSString *)btd_stringValueForKey:(id<NSCopying>)key default:(NSString *)def {
    if (!key) return def;
    id value = self[key];
    if (!value || value == [NSNull null]) return def;
    if ([value isKindOfClass:[NSString class]]) return value;
    if ([value isKindOfClass:[NSNumber class]]) return ((NSNumber *)value).description;
    return def;
}

- (NSArray *)btd_arrayValueForKey:(id<NSCopying>)key default:(NSArray *)def {
    if (key == nil) {
        return def;
    }
    id value = self[key];
    if ([value isKindOfClass:[NSArray class]]) {
        return value;
    }
    return def;
}

- (NSDictionary *)btd_dictionaryValueForKey:(id<NSCopying>)key default:(NSDictionary *)def {
    if (key == nil) {
        return def;
    }
    id value = self[key];
    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    return def;
}

- (id)btd_objectForKey:(id<NSCopying>)key default:(id)def {
    if (key == nil) {
        return def;
    }
    id value = self[key];
    return value ? : def;
}

- (void)btd_forEach:(void (^)(id _Nonnull, id _Nonnull))block {
    NSParameterAssert(block != nil);
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        block(key, obj);
    }];
}

- (BOOL)btd_contain:(BOOL (^)(id _Nonnull, id _Nonnull))block {
    NSParameterAssert(block != nil);
    __block BOOL result = NO;
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (block(key, obj)) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

- (BOOL)btd_all:(BOOL (^)(id _Nonnull, id _Nonnull))block {
    NSParameterAssert(block != nil);
    __block BOOL result = YES;
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (!block(key, obj)) {
            result = NO;
            *stop = YES;
        }
    }];
    return result;
}

- (NSDictionary *)btd_filter:(BOOL (^)(id _Nonnull, id _Nonnull))block {
    NSParameterAssert(block != nil);
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (block(key, obj)) {
            result[key] = obj;
        }
    }];
    return [result copy];
}

- (NSDictionary *)btd_map:(id  _Nullable (^)(id _Nonnull, id _Nonnull))block {
    NSParameterAssert(block != nil);
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        result[key] = block(key, obj) ? : [NSNull null];
    }];
    return [result copy];
}

- (NSDictionary *)btd_compactMap:(id  _Nullable (^)(id _Nonnull, id _Nonnull))block {
    NSParameterAssert(block != nil);
    NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        result[key] = block(key, obj);
    }];
    return [result copy];
}

- (NSString *)btd_URLQueryString {
    NSMutableArray<NSString *> *items = [NSMutableArray arrayWithCapacity:self.count];
    [self btd_forEach:^(id  _Nonnull key, id  _Nonnull obj) {
        [items addObject:[NSString stringWithFormat:@"%@=%@", key, obj]];
    }];
    return [items componentsJoinedByString:@"&"];
}

- (NSString *)btd_URLQueryStringWithEncoding {
    NSMutableArray<NSString *> *items = [NSMutableArray arrayWithCapacity:self.count];
    [self btd_forEach:^(id  _Nonnull key, id  _Nonnull obj) {
        id value = obj;
        if ([value isKindOfClass:[NSString class]]) {
            value = [(NSString *)value btd_stringByURLEncode];
        }
        [items addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }];
    return [items componentsJoinedByString:@"&"];
}

@end


@implementation NSMutableDictionary (BTDAdditions)

- (void)btd_setObject:(id)anObject forKey:(id<NSCopying>)key {
    if (key != nil && anObject != nil) {
        [self setObject:anObject forKey:key];
    }
}

@end
