//
//  NSDictionary+HMDImmutableCopy.m
//  Heimdallr
//
//  Created by 崔晓兵 on 24/4/2022.
//

#import "NSDictionary+HMDImmutableCopy.h"


@implementation NSDictionary (HMDImmutableCopy)

- (NSDictionary *)hmd_immutableCopy {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:self];
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSSet class]]) {
            [dict setValue:[obj hmd_immutableCopy] forKey:key];
        } else if ([obj isKindOfClass:[NSMutableString class]] || [obj isKindOfClass:[NSMutableData class]]) {
            [dict setValue:[obj copy] forKey:key];
        }
    }];
    return [dict copy];
}

@end


@interface NSSet (HMDImmutableCopy)

- (NSArray *)hmd_immutableCopy;

@end

@implementation NSSet (HMDImmutableCopy)

- (NSSet *)hmd_immutableCopy {
    NSMutableSet *result = [NSMutableSet setWithCapacity:self.count];
    for (id obj in self) {
        if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSSet class]]) {
            [result addObject:[obj hmd_immutableCopy]];
        } else if ([obj isKindOfClass:[NSMutableString class]] || [obj isKindOfClass:[NSMutableData class]]) {
            [result addObject:[obj copy]];
        } else {
            [result addObject:obj];
        }
    }
    return [result copy];
}
@end


@interface NSArray (HMDImmutableCopy)

- (NSArray *)hmd_immutableCopy;

@end

@implementation NSArray (HMDImmutableCopy)

- (NSArray *)hmd_immutableCopy {
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    for (id obj in self) {
        if ([obj isKindOfClass:[NSDictionary class]] || [obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSSet class]]) {
            [result addObject:[obj hmd_immutableCopy]];
        } else if ([obj isKindOfClass:[NSMutableString class]] || [obj isKindOfClass:[NSMutableData class]]) {
            [result addObject:[obj copy]];
        } else {
            [result addObject:obj];
        }
    }
    return [result copy];
}

@end


@implementation NSDictionary (HMDHasMutableContent)

- (BOOL)hmd_hasMutableContainer {
    if ([self isKindOfClass:[NSMutableDictionary class]]) return YES;
    __block BOOL hasMutable = NO;
    [self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[NSMutableDictionary class]] ||
            [obj isKindOfClass:[NSMutableArray class]] ||
            [obj isKindOfClass:[NSMutableSet class]]) {
            hasMutable = YES;
            *stop = YES;
        } else if ([obj isKindOfClass:[NSDictionary class]] ||
                   [obj isKindOfClass:[NSArray class]] ||
                   [obj isKindOfClass:[NSSet class]]) {
            hasMutable = [obj hmd_hasMutableContainer];
            if (hasMutable) *stop = YES;
        }
    }];
    return hasMutable;
}

@end


@interface NSSet (HMDHasMutableContent)

- (BOOL)hmd_hasMutableContainer;

@end

@implementation NSSet (HMDHasMutableContent)

- (BOOL)hmd_hasMutableContainer {
    if ([self isKindOfClass:[NSMutableSet class]]) return YES;
    BOOL hasMutable = NO;
    for (id obj in self) {
        if ([obj isKindOfClass:[NSMutableDictionary class]] ||
            [obj isKindOfClass:[NSMutableArray class]] ||
            [obj isKindOfClass:[NSMutableSet class]]) {
            hasMutable = YES;
            break;
        } else if ([obj isKindOfClass:[NSDictionary class]] ||
                   [obj isKindOfClass:[NSArray class]] ||
                   [obj isKindOfClass:[NSSet class]]) {
            hasMutable = [obj hmd_hasMutableContainer];
            if (hasMutable) break;
        }
    }
    return hasMutable;
}
@end


@interface NSArray (HMDHasMutableContent)

- (BOOL)hmd_hasMutableContainer;

@end

@implementation NSArray (HMDHasMutableContent)

- (BOOL)hmd_hasMutableContainer {
    if ([self isKindOfClass:[NSMutableArray class]]) return YES;
    BOOL hasMutable = NO;
    for (id obj in self) {
        if ([obj isKindOfClass:[NSMutableDictionary class]] ||
            [obj isKindOfClass:[NSMutableArray class]] ||
            [obj isKindOfClass:[NSMutableSet class]]) {
            hasMutable = YES;
            break;
        } else if ([obj isKindOfClass:[NSDictionary class]] ||
                   [obj isKindOfClass:[NSArray class]] ||
                   [obj isKindOfClass:[NSSet class]]) {
            hasMutable = [obj hmd_hasMutableContainer];
            if (hasMutable) break;
        }
    }
    return hasMutable;
}

@end

