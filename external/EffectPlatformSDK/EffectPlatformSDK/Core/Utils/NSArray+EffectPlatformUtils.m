//
//  NSArray+EffectPlatformUtils.m
//  Pods
//
//  Created by li xingdong on 2019/4/14.
//

#import "NSArray+EffectPlatformUtils.h"
#import "NSDictionary+EffectPlatfromUtils.h"

@implementation NSArray (EffectPlatformUtils)

- (NSArray *)arrayByRemoveNULL
{
    NSMutableArray *resultArr = [NSMutableArray array];
    for (id value in self) {
        id item = value;
        if (![item isKindOfClass:[NSNull class]]) {
            if ([item isKindOfClass:[NSArray class]]) {
                item = [item arrayByRemoveNULL];
            } else if ([item isKindOfClass:[NSDictionary class]]) {
                item = [item dictionaryByRemoveNULL];
            }
            [resultArr addObject:item];
        }
    }
    return resultArr;
}

- (NSArray *)ep_compact:(id (^)(id obj))block {
    NSParameterAssert(block != nil);
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:self.count];
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        id value = block(obj);
        if(value) {
            [result addObject:value];
        }
    }];
    return result;
}

@end
