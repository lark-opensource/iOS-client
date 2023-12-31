//
//  NSDictionary+BDPExtension.m
//  Timor
//
//  Created by muhuai on 2018/1/25.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "NSDictionary+BDPExtension.h"

static void freePtr(void* ptr, void* ctx)
{
    free(ptr);
}

@implementation NSDictionary (BDPExtension)

#pragma mark - Safe Function
/*-----------------------------------------------*/
//            Safe Function - 安全方法
/*-----------------------------------------------*/
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

- (BOOL)boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        NSString *stringValue = (NSString *)value;
        return [stringValue boolValue];
    }
    if (value && [value isKindOfClass:[NSNumber class]]) {
        return [value integerValue] != 0;
    }
    return defaultValue;
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

#pragma mark - Safe Function(Default)
/*-----------------------------------------------*/
//    Safe Function(Default) - 安全方法(含默认值)
/*-----------------------------------------------*/
- (id)bdp_objectForKey:(NSString *)key
{
    return [self objectForKey:key defalutObj:nil];
}

- (id)bdp_objectForKey:(id)aKey ofClass:(Class)aClass
{
    return [self objectForKey:aKey ofClass:aClass defaultObj:nil];
}

- (int)bdp_intValueForKey:(NSString *)key
{
    return [self intValueForKey:key defaultValue:0];
}

- (NSInteger)bdp_integerValueForKey:(NSString *)key
{
    return [self integerValueForKey:key defaultValue:0];
}

- (NSUInteger)bdp_unsignedIntegerValueForKey:(NSString *)key
{
    return [self unsignedIntegerValueForKey:key defaultValue:0];
}

- (float)bdp_floatValueForKey:(NSString *)key
{
    return [self floatValueForKey:key defaultValue:0.f];
}

- (double)bdp_doubleValueForKey:(NSString *)key
{
    return [self doubleValueForKey:key defaultValue:0.];
}

- (long)bdp_longValueForKey:(NSString *)key
{
    return [self longValueForKey:key defaultValue:0];
}

- (long long)bdp_longlongValueForKey:(NSString *)key
{
    return [self longlongValueForKey:key defaultValue:0];
}

- (BOOL)bdp_boolValueForKey:(NSString *)key
{
    return [self integerValueForKey:key defaultValue:0] != 0;
}

- (BOOL)bdp_boolValueForKey2:(NSString *)key {
    return [self boolValueForKey:key defaultValue:NO];
}

- (NSString *)bdp_stringValueForKey:(NSString *)key
{
    return [self stringValueForKey:key defaultValue:nil];
}

- (NSArray *)bdp_arrayValueForKey:(NSString *)key
{
    return [self arrayValueForKey:key defaultValue:nil];
}

- (NSDictionary *)bdp_dictionaryValueForKey:(NSString *)key
{
    return [self dictionaryValueForKey:key defalutValue:nil];
}

#pragma mark - NativeBuffer Process
/*-----------------------------------------------*/
//    NativeBuffer Process - NativeBuffer处理
/*-----------------------------------------------*/
- (NSDictionary *)decodeNativeBuffersIfNeed
{
    NSArray<NSDictionary *> *buffers = [self bdp_arrayValueForKey:@"__nativeBuffers__"];
    if (!buffers.count) {
        return self;
    }
    
    NSMutableDictionary *new = [self mutableCopy];
    [new removeObjectForKey:@"__nativeBuffers__"];
    
    for (NSDictionary *buffer in buffers) {
        
        if (![buffer isKindOfClass:[NSDictionary class]] || !buffer.count) {
            continue;
        }
        
        NSString *key = [buffer bdp_stringValueForKey:@"key"];
        NSString *base64 = [buffer bdp_stringValueForKey:@"base64"];
        
        if (!key.length || !base64.length) {
            continue;
        }
        
        NSData *data = [[NSData alloc] initWithBase64EncodedString:base64 options:0];
        [new setValue:data forKey:key];
    }
    
    return [new copy];
}

- (NSDictionary *)encodeNativeBuffersIfNeed
{
    NSMutableArray<NSDictionary *> *buffers = [[NSMutableArray alloc] initWithCapacity:5];
    [self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSData class]]) {
            return;
        }
        
        NSString *base64 = [((NSData *)obj) base64EncodedStringWithOptions:0];
        if (!base64) {
            return;
        }
        
        [buffers addObject:@{@"key": key,
                             @"base64": base64}];
    }];
    
    if (!buffers.count) {
        return self;
    }
    
    NSMutableDictionary *new = [self mutableCopy];
    for (NSDictionary *buffer in buffers) {
        [new removeObjectForKey:buffer[@"key"]];
    }
    
    [new setValue:[buffers copy] forKey:@"__nativeBuffers__"];
    return [new copy];
}

- (JSValue *)bdp_jsvalueInContext:(JSContext *)context
{
    JSContextRef ctx = [context JSGlobalContextRef];
    NSMutableArray<NSDictionary *> *buffers = [[NSMutableArray alloc] initWithCapacity:5];
    [self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, NSData *obj, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[NSData class]]) {
            return;
        }
        
        void *buffer = malloc(obj.length);
        [obj getBytes:buffer length:obj.length];
        JSObjectRef dataRef = JSObjectMakeArrayBufferWithBytesNoCopy(ctx, buffer, [obj length], freePtr, NULL, NULL);
        JSValue *value = [JSValue valueWithJSValueRef:dataRef inContext:context];

        [buffers addObject:@{@"key": key,
                             @"value": value}];
    }];
    
    if (!buffers.count) {
        return [JSValue valueWithObject:self inContext:context];
    }
    
    NSMutableDictionary *new = [self mutableCopy];
    for (NSDictionary *buffer in buffers) {
        [new removeObjectForKey:buffer[@"key"]];
    }
    
    [new setValue:[buffers copy] forKey:@"__nativeBuffers__"];
    return [JSValue valueWithObject:new inContext:context];
}

- (NSDictionary *)bdp_dictionaryWithLowercaseKeys
{
    NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithCapacity:[[self allKeys] count]];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        [newDic setValue:obj forKey:[key lowercaseString]];
    }];
    
    return [newDic copy];
}

- (NSDictionary *)bdp_dictionaryWithCapitalizedKeys
{
    NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithCapacity:[[self allKeys] count]];
    
    [self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL * _Nonnull stop) {
        [newDic setValue:obj forKey:[key capitalizedString]];
    }];
    
    return [newDic copy];
}

-(NSString *)bdp_URLQueryString
{
    NSMutableArray<NSString *> *items = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, BOOL * stop) {
        [items addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
    }];
    return [items componentsJoinedByString:@"&"];
}

+ (NSDictionary *)bdp_dictionaryWithJsonString:(NSString *)jsonString {
    if (!jsonString || jsonString.length == 0) {
        return nil;
    }

    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];

    if (err) {
        return nil;
    }

    return dic;
}

- (NSString *)bdp_jsonString {
    if (!self) {
        return nil;
    }

    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:NSJSONWritingPrettyPrinted error:&parseError];

    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

@end
