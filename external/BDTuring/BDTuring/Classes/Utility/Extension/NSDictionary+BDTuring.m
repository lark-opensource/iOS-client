//
//  NSDictionary+BDTuring.m
//  BDTuring
//
//  Created by bob on 2019/8/25.
//

#import "NSDictionary+BDTuring.h"
#import "NSObject+BDTuring.h"
#import "BDTuringMacro.h"

@implementation NSDictionary (BDTuring)

- (double)turing_doubleValueForKey:(NSString *)key {
    return [self turing_doubleValueForKey:key defaultValue:0.0];
}

- (double)turing_doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue {
    if (key == nil) {
        return defaultValue;
    }
    
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value doubleValue];
    }

    if ([value isKindOfClass:[NSString class]]) {
        return [value doubleValue];
    }

    return defaultValue;
}

- (long long)turing_longLongValueForKey:(NSString *)key defaultValue:(long long)defaultValue {
    if (key == nil) {
        return defaultValue;
    }
    
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value longLongValue];
    }

    if ([value isKindOfClass:[NSString class]]) {
        return [value longLongValue];
    }

    return defaultValue;
}

- (BOOL)turing_boolValueForKey:(NSString *)key {
    if (key == nil) {
        return NO;
    }
    
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value boolValue];
    }

    if ([value isKindOfClass:[NSString class]]) {
        return [value boolValue];
    }

    return NO;
}

- (NSInteger)turing_integerValueForKey:(NSString *)key {
    if (key == nil) {
        return 0;
    }
    
    id value = [self objectForKey:key];
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value integerValue];
    }

    if ([value isKindOfClass:[NSString class]]) {
        return [value integerValue];
    }

    return 0;
}

- (NSString *)turing_stringValueForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    
    id value = [self objectForKey:key];

    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }

    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }

    return nil;
}

- (NSDictionary *)turing_dictionaryValueForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    
    id value = [self objectForKey:key];

    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }

    return nil;
}

- (NSMutableDictionary *)turing_mutableDictionaryValueForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    
    id value = [self objectForKey:key];
    
    if ([value isKindOfClass:[NSMutableDictionary class]]) {
        return value;
    }
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        return [value mutableCopy];
    }
    
    return nil;
}

- (NSArray *)turing_arrayValueForKey:(NSString *)key {
    if (key == nil) {
        return nil;
    }
    
    id value = [self objectForKey:key];

    if ([value isKindOfClass:[NSArray class]]) {
        return value;
    }

    return nil;
}

- (id)turing_safeJsonObject {
    /// roughly set factor = 50% 
    NSUInteger capacity = self.count * 2;
    NSMutableDictionary *safeEncodingDict = [NSMutableDictionary dictionaryWithCapacity:capacity];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        id safeKey = [key turing_safeJsonObject];
        id safeValue = [value turing_safeJsonObject];
        if (safeKey!= nil && safeValue != nil) {
            [safeEncodingDict setValue:safeValue forKey:safeKey];
        }
    }];
    
    return safeEncodingDict.copy;
}

@end
