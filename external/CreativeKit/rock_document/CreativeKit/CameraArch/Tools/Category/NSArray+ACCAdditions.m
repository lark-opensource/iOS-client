//
//  NSArray+ACCAdditions.m
//  Pods
//
//  Created by chengfei xiao on 2019/9/27.
//

#import "NSArray+ACCAdditions.h"


@implementation NSArray (ACCAdditions)

- (id)acc_objectAtIndex:(NSUInteger)index {
    if (index < self.count) {
        return self[index];
    } else {
        return nil;
    }
}

- (NSString *)acc_stringWithIndex:(NSUInteger)index {
    id value = [self acc_objectAtIndex:index];
    if (value == nil || value == [NSNull null]) {
        return nil;
    }

    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }

    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }

    return nil;
}


- (NSDictionary *)acc_dictionaryWithIndex:(NSUInteger)index {
    id value = [self acc_objectAtIndex:index];
    if (value == nil || value == [NSNull null]) {
        return nil;
    }

    if ([value isKindOfClass:[NSDictionary class]]) {
        return value;
    }

    return nil;
}

- (NSArray *)acc_mapObjectsUsingBlock:(id  _Nonnull (^)(id _Nonnull, NSUInteger))block
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result addObject:block(obj, idx)];
    }];
    return result.copy;
}

- (id)acc_match:(BOOL (^)(id _Nonnull))matcher
{
    if (!matcher) {
        return nil;
    }
    for (id item in [self copy]) {
        if (matcher(item)) {
            return item;
        }
    }
    return nil;
}

- (NSArray *)acc_filter:(BOOL (^)(id _Nonnull))filter
{
    if (!filter) {
        return self;
    }
    NSArray *tmp = [self copy];
    NSMutableArray *array = [NSMutableArray array];
    for (id item in tmp) {
        if (filter(item)) {
            [array addObject:item];
        }
    }
    return [array copy];
}

- (id)acc_safeJsonObject
{
    NSMutableArray *safeEncodingArray = [NSMutableArray array];
    for (id arrayValue in (NSArray *)self) {
        [safeEncodingArray addObject:[arrayValue acc_safeJsonObject]];
    }
    return safeEncodingArray.copy;
}

- (NSArray *)acc_map:(id  _Nonnull (^)(id _Nonnull))transform
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    for (id object in self) {
        id tran = transform(object);
        if (tran) {
            [result addObject:tran];
        } else {
            NSAssert(tran, @"tran is nil");
        }
    }
    return [result copy];
}

- (NSArray *)acc_compactMap:(nullable id (^)(id obj))transform
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    for (id object in self) {
        id tran = transform(object);
        if (tran) {
            [result addObject:tran];
        }
    }
    return [result copy];
}

- (NSArray *)acc_flatMap:(NSArray* (^)(id obj))transform;
{
    NSMutableArray *result = [NSMutableArray array];
    for (id object in self) {
        [result addObjectsFromArray:transform(object)];
    }
    return [result copy];
}

- (void)acc_forEach:(void (^)(id _Nonnull))block
{
    [self acc_forEachWithIndex:^(id  _Nonnull obj, NSUInteger index) {
        block(obj);
    }];
}

- (void)acc_forEachWithIndex:(void (^)(id _Nonnull, NSUInteger))block
{
    for (NSUInteger i = 0; i < self.count; i++) {
        block(self[i], i);
    }
}

- (id)acc_reduce:(id)initial
         reducer:(id  _Nonnull (^)(id _Nonnull, id _Nonnull))reducer
{
    id cur = initial;
    for (id object in self) {
        cur = reducer(cur, object);
    }
    return cur;
}

- (NSInteger)acc_indexOf:(BOOL (^)(id _Nonnull))condition
{
    for (NSUInteger i = 0; i < self.count; i++) {
        if (condition(self[i])) {
            return i;
        }
    }
    return NSNotFound;
}

- (BOOL)acc_all:(BOOL (^)(id _Nonnull))condition
{
    for (id object in self) {
        if (!condition(object)) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)acc_allWithIndex:(BOOL (^)(id obj, NSInteger index))condition
{
    for (NSUInteger i = 0; i < self.count; i++) {
        if (!condition(self[i], i)) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)acc_any:(BOOL (^)(id _Nonnull))condition
{
    for (id object in self) {
        if (condition(object)) {
            return YES;
        }
    }
    return NO;
}

@end


@implementation NSMutableArray (ACCAdditions)

- (void)acc_addObject:(id)anObject {
    if (anObject != nil) {
        [self addObject:anObject];
//    } else {
//        NSAssert(NO, @"Object can't be nil");
    }
}

- (void)acc_addObjectsFromArray:(NSArray *)otherArray {
    if (otherArray != nil && otherArray.count > 0) {
        for (id object in otherArray) {
            [self acc_addObject:object];
        }
    }
}

- (void)acc_removeObject:(id)anObject {
    if (anObject != nil) {
        [self removeObject:anObject];
    } else {
        NSAssert(NO, @"Object can't be nil");
    }
}

- (void)acc_removeObjectAtIndex:(NSUInteger)index {
    if (index < self.count) {
        [self removeObjectAtIndex:index];
    } else {
        NSAssert(NO, @"Invalid index");
    }
}

- (void)acc_insertObject:(id)anObject atIndex:(NSUInteger)index {
    if (anObject != nil && index <= self.count) {
        [self insertObject:anObject atIndex:index];
    } else {
        NSAssert(NO, @"Invalid index / Object can't be nil");
    }
}

- (void)acc_replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject {
    if (anObject != nil && index < self.count) {
        [self replaceObjectAtIndex:index withObject:anObject];
    }
}

- (void)acc_moveObjectFromIndex:(NSUInteger)fromIndex
                        toIndex:(NSUInteger)toIndex
{
    if (fromIndex >= self.count || toIndex >= self.count) {
        NSAssert(NO, @"Invalid index");
    }
    
    if (fromIndex == toIndex) {
        return;
    }
    
    id fromObject = [self acc_objectAtIndex:fromIndex];
    [self acc_removeObjectAtIndex:fromIndex];
    [self acc_insertObject:fromObject atIndex:toIndex];
}

@end


@implementation NSArray (ACCJSONString)

- (NSString *)acc_JSONString {
    NSString *jsonString = [self acc_JSONStringWithOptions:NSJSONWritingPrettyPrinted];
    return jsonString;
}

- (NSString *)acc_JSONStringWithOptions:(NSJSONWritingOptions)opt {
    NSError *error = nil;
    NSData *jsonData;
    @try {
        jsonData = [NSJSONSerialization dataWithJSONObject:self
                                                   options:opt
                                                     error:&error];
    } @catch (NSException *exception) {
    }
    if (jsonData == nil) {
        NSAssert(error,@"fail to get JSON");
        return nil;
    }
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end

