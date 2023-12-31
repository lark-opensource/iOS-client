//
//  NSDictionary+TTVideoEngine.m
//  Pods
//
//  Created by guikunzhi on 16/12/22.
//
//

#import "NSDictionary+TTVideoEngine.h"
#import "TTVideoEngineUtil.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineEventLoggerProtocol.h"

@implementation NSDictionary (TTVideoEngine)

- (NSDictionary *)ttVideoEngineDictionaryValueForKey:(NSString *)key defaultValue:(NSDictionary *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSDictionary class]]) ? value : defaultValue;
}

- (NSArray *)ttVideoEngineArrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue {
    id value = [self objectForKey:key];
    return (value && [value isKindOfClass:[NSArray class]]) ? value : defaultValue;
}

- (int)ttVideoEngineIntValueForKey:(NSString *)key defaultValue:(int)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value intValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value intValue] : defaultValue;
}

- (NSInteger)ttVideoEngineIntegerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value integerValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value integerValue] : defaultValue;
}

- (NSString *)ttVideoEngineStringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return ((NSString*)value).copy;
    }
    return defaultValue;
}

- (BOOL)ttVideoEngineBoolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue {
    id value = [self objectForKey:key];
    if (value == [NSNull null]) {
        return NO;
    }
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value boolValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value boolValue] : defaultValue;
}

- (NSString *)ttvideoengine_jsonString {
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (CGFloat)ttVideoEngineFloatValueForKey:(NSString *)key defalutValue:(CGFloat)defaultValue {
    id value = [self objectForKey:key];
    if (value == [NSNull null]) {
        return 0.0;
    }
    if (value && [value isKindOfClass:[NSString class]]) {
        return [(NSString *)value floatValue];
    }
    return (value && [value isKindOfClass:[NSNumber class]]) ? [value floatValue] : defaultValue;
}

@end

@implementation NSMutableDictionary(TTVideoEngine)

- (void)ttvideoengine_setObject:(id)anObject forKey:(id<NSCopying>)aKey{
    if (!aKey) {
        return;
    }
    
    if (!anObject) {
        return;
    }
    
    [self setObject:anObject forKey:aKey];
}

- (id)ttvideoengine_objectForKey:(id)aKey{
    if (!aKey) {
        TTVideoEngineLog(@"ttvideo_objectForKey:  error [aKey = nil]");
        return nil;
    }
    
    return [self objectForKey:aKey];
}

@end
