//
//  NSSet+BTDAdditions.m
//  Pods
//
//  Created by yanglinfeng on 2019/7/2.
//

#import "NSSet+BTDAdditions.h"

@implementation NSSet (BTDAdditions)

- (void)btd_forEach:(void (^)(id _Nonnull))block {
    NSParameterAssert(block != nil);
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        block(obj);
    }];
}

- (BOOL)btd_contains:(BOOL (^)(id _Nonnull))block {
    NSParameterAssert(block != nil);
    __block BOOL result = NO;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (block(obj)) {
            result = YES;
            *stop = YES;
        }
    }];
    return result;
}

- (BOOL)btd_all:(BOOL (^)(id _Nonnull))block {
    NSParameterAssert(block != nil);
    __block BOOL result = YES;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (!block(obj)) {
            result = NO;
            *stop = YES;
        }
    }];
    return result;
}

- (id)btd_find:(BOOL (^)(id _Nonnull))block {
    NSParameterAssert(block != nil);
    __block id result = nil;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (block(obj)) {
            result = obj;
            *stop = YES;
        }
    }];
    return result;
}

- (NSSet *)btd_filter:(BOOL (^)(id _Nonnull))block {
    NSParameterAssert(block != nil);
    NSMutableSet *result = [NSMutableSet setWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (block(obj)) {
            [result addObject:obj];
        }
    }];
    return [result copy];
}

- (NSSet<id> *)btd_map:(id  _Nullable (^)(id _Nonnull))block {
    NSParameterAssert(block != nil);
    NSMutableSet *result = [NSMutableSet setWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        id mapped = block(obj) ? : [NSNull null];
        [result addObject:mapped];
    }];
    return [result copy];
}

- (NSSet<id> *)btd_compactMap:(id  _Nullable (^)(id _Nonnull))block {
    NSParameterAssert(block != nil);
    NSMutableSet *result = [NSMutableSet setWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        id mapped = block(obj);
        if (mapped) {
            [result addObject:mapped];
        }
    }];
    return [result copy];
}

- (id)btd_reduce:(id)initialValue reducer:(id  _Nullable (^)(id _Nullable, id _Nonnull))block {
    NSParameterAssert(block != nil);
    __block id result = initialValue;
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        result = block(result, obj);
    }];
    return result;
}

@end

@implementation NSMutableSet (BTDAdditions)

- (void)btd_addObject:(id)object {
    if (object) {
        [self addObject:object];
    }
}

- (void)btd_removeObject:(id)object {
    if (object) {
        [self removeObject:object];
    }
}

@end

