//
//  NSMutableDictionary+OK.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "NSMutableDictionary+OK.h"
#import "OKUtility.h"

@implementation NSMutableDictionary (OK)

- (void)ok_setObject:(id)anObject forKey:(id<NSCopying>)aKey {
    if (aKey == nil) {
        return;
    }
    
    if (anObject == nil) {
        [self removeObjectForKey:aKey];
    } else {
        [self setObject:anObject forKey:aKey];
    }
}

- (void)ok_skipMerge:(NSDictionary *)value {
    if (!OK_isValidDictionary(value)) {
        return;
    }
    
    [value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSMutableDictionary *origin = [self objectForKey:key];
        if ([origin isKindOfClass:[NSMutableDictionary class]]) {
            [origin ok_skipMerge:obj];
        } else if ([origin isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *merge = [origin mutableCopy];
            [merge ok_skipMerge:obj];
            [self setObject:merge forKey:key];
        } else if (origin == nil) {
            [self setObject:obj forKey:key];
        }
    }];
}

- (void)ok_overrideMerge:(NSDictionary *)value {
    if (!OK_isValidDictionary(value)) {
        return;
    }
    
    [value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSMutableDictionary *origin = [self objectForKey:key];
        if ([origin isKindOfClass:[NSMutableDictionary class]]) {
            [origin ok_overrideMerge:obj];
        } else if ([origin isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *merge = [origin mutableCopy];
            [merge ok_overrideMerge:obj];
            [self setObject:merge forKey:key];
        } else {
            [self setObject:obj forKey:key];
        }
    }];
}

@end
