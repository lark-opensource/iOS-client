//
//  NSArray+HMDSafe.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/14.
//

#import "NSArray+HMDSafe.h"

@implementation NSArray (HMDSafe)

- (id _Nullable)hmd_objectAtIndex:(NSUInteger)index
{
    if (index >= self.count) {
        return nil;
    }
    return [self objectAtIndex:index];
}

- (id _Nullable)hmd_objectAtIndex:(NSUInteger)index class:(Class)clazz
{
    id obj = [self hmd_objectAtIndex:index];
    if ([obj isKindOfClass:clazz]) {
        return obj;
    }
    return nil;
}

- (void)hmd_enumerateObjectsUsingBlock:(void (^)(id _Nonnull, NSUInteger, BOOL * _Nonnull))block class:(Class)clazz
{
    if (!block) {
        return;
    }
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (clazz && [obj isKindOfClass:clazz]) {
            block(obj,idx,stop);
        }
    }];
}

@end

@implementation NSMutableArray (HMDSafe)

- (void)hmd_addObject:(id)anObject
{
    if (anObject == nil) {
        return;
    }
    [self addObject:anObject];
}

- (void)hmd_insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if (index > self.count) {
        return;
    }
    if (anObject == nil) {
        return;
    }
    [self insertObject:anObject atIndex:index];
}

- (void)hmd_removeObjectAtIndex:(NSUInteger)index
{
    if (index >= self.count) {
        return;
    }
    [self removeObjectAtIndex:index];
}

- (void)hmd_addObjects:(NSArray *)array
{
    if (array && [array isKindOfClass:NSArray.class] && array.count) {
        [self addObjectsFromArray:array];
    }
}

@end
