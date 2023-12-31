//
//  NSMutableDictionary+BDTuring.m
//  BDTuring
//
//  Created by bob on 2020/7/14.
//

#import "NSMutableDictionary+BDTuring.h"
#import "BDTuringMacro.h"
#import "NSDictionary+BDTuring.h"
#import "BDTuringUtility.h"

@implementation NSMutableDictionary (BDTuring)

- (void)turing_defaultMerge:(NSDictionary *)value {
    if (!BDTuring_isValidDictionary(value)) {
        return;
    }
    
    [value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSMutableDictionary *origin = [self objectForKey:key];
        if ([origin isKindOfClass:[NSMutableDictionary class]]) {
            [origin turing_defaultMerge:obj];
        } else if ([origin isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *merge = [origin mutableCopy];
            [merge turing_defaultMerge:obj];
            [self setObject:merge forKey:key];
        } else if (origin == nil) {
            [self setObject:obj forKey:key];
        }
    }];
}

- (void)turing_overrideMerge:(NSDictionary *)value {
    if (!BDTuring_isValidDictionary(value)) {
        return;
    }
    
    [value enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSMutableDictionary *origin = [self objectForKey:key];
        if ([origin isKindOfClass:[NSMutableDictionary class]]) {
            [origin turing_overrideMerge:obj];
        } else if ([origin isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *merge = [origin mutableCopy];
            [merge turing_overrideMerge:obj];
            [self setObject:merge forKey:key];
        } else {
            [self setObject:obj forKey:key];
        }
    }];
}

- (void)addContentWithKey:(NSString *)key fromDic:(NSDictionary *)dic {
    NSString *str = [dic turing_stringValueForKey:key];
    if (str != nil) {
        [self setValue:str forKey:key];
    }
}

@end
