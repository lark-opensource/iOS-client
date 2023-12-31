//
//  NSDictionary+Safe.m
//
//
//  Created by zhangtianfu on 2019/1/10.
//

#import "NSDictionary+Safe.h"

@implementation NSDictionary (Safe)
    
- (NSString *)flutter_stringValueForKey:(NSString *)key {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        return value;
    } else if(value && [value isKindOfClass:[NSNumber class]]){
        return [value stringValue];
    } else{
        return nil;
    }
}
    
- (NSNumber *)flutter_numberValueForKey:(NSString *)key {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSString class]]) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        return [formatter numberFromString:value];
    } else if(value && [value isKindOfClass:[NSNumber class]]){
        return value;
    } else{
        return nil;
    }
}

- (NSArray *)flutter_arrayValueForKey:(NSString *)key {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSArray class]]) {
        return value;
    } else {
        return nil;
    }
}

- (NSDictionary *)flutter_dictionaryValueForKey:(NSString *)key {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:[NSDictionary class]]) {
        return value;
    } else {
        return nil;
    }
}

- (id)flutter_objectOfClass:(Class)theClass forKey:(NSString *)key {
    id value = [self objectForKey:key];
    if (value && [value isKindOfClass:theClass]) {
        return value;
    } else {
        return nil;
    }
}
    
@end


