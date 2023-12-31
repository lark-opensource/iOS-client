//
//  NSDictionary+ACCAdditions.m
//  CreativeKit-Pods-Aweme
//
//  Created by raomengyun on 2021/5/10.
//

#import "NSDictionary+ACCAdditions.h"

@implementation NSDictionary (ACCAdditions)

- (NSArray *)acc_map:(id  _Nonnull (^)(id _Nonnull, id _Nonnull))transform
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.allKeys.count];
    for (id key in self.allKeys) {
        id trans = transform(key, self[key]);
        if (trans) {
            [array addObject:trans];
        } else {
            NSAssert(trans, @"tran is nil");
        }
    }
    return [array copy];
}

- (NSDictionary *)acc_filter:(BOOL (^)(id _Nonnull, id _Nonnull))condition
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (id key in self.allKeys) {
        if (condition(key, self[key])) {
            dic[key] = self[key];
        }
    }
    return [dic copy];
}

- (NSArray *)acc_flatMap:(NSArray * _Nonnull (^)(id _Nonnull, id _Nonnull))transform
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:self.allKeys.count];
    for (id key in self.allKeys) {
        id trans = transform(key, self[key]);
        if (trans) {
            [array addObjectsFromArray:trans];
        }
    }
    return [array copy];
}

- (void)acc_forEach:(void (^)(id _Nonnull, id _Nonnull))block
{
    for (id key in self.allKeys) {
        block(key, self[key]);
    }
}

- (id)acc_reduce:(id)initial reducer:(id  _Nonnull (^)(id _Nonnull, id _Nonnull, id _Nonnull))reducer
{
    id cur = initial;
    for (id key in self.allKeys) {
        cur = reducer(cur, key, self[key]);
    }
    return cur;
}

- (BOOL)acc_all:(BOOL (^)(id _Nonnull, id _Nonnull))condition
{
    for (id key in self.allKeys) {
        if (!condition(key, self[key])) {
            return NO;
        }
    }
    return YES;
}

- (BOOL)acc_any:(BOOL (^)(id _Nonnull, id _Nonnull))condition
{
    for (id key in self.allKeys) {
        if (condition(key, self[key])) {
            return YES;
        }
    }
    return NO;
}

- (NSArray *)acc_match:(BOOL (^)(id _Nonnull, id _Nonnull))condition
{
    for (id key in self.allKeys) {
        if (condition(key, self[key])) {
            return @[key, self[key]];
        }
    }
    return nil;
}

@end
