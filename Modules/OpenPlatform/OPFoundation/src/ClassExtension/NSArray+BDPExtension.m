//
//  NSArray+BDPExtension.m
//  Timor
//
//  Created by liuxiangxin on 2019/6/19.
//

#import "NSArray+BDPExtension.h"

@implementation NSArray (BDPExtension)

- (NSArray *)bdp_arrayByRemoveDuplicateObject
{
    NSMutableSet *set = [NSMutableSet set];
    NSMutableArray *newArray = [NSMutableArray array];
    [self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![set containsObject:obj]) {
            [newArray addObject:obj];
            [set addObject:obj];
        }
    }];
    
    return newArray.copy;
}

- (NSArray *)bdp_addObject:(id)object {
    if (!object) {
        return self;
    }
    if (!self.count) {
        return @[object];
    } else {
        NSMutableArray *mObjects = [self mutableCopy];
        [mObjects addObject:object];
        return [mObjects copy];
    }
}

@end
