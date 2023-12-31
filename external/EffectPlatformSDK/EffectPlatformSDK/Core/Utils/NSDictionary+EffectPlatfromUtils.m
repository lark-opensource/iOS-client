//
//  NSDictionary+EffectPlatfromUtils.m
//  Pods
//
//  Created by li xingdong on 2019/4/14.
//

#import "NSDictionary+EffectPlatfromUtils.h"
#import "NSArray+EffectPlatformUtils.h"

@implementation NSDictionary (EffectPlatfromUtils)

- (NSDictionary *)dictionaryByRemoveNULL {
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    for (NSString *key in self) {
        id value = self[key];
        if (![value isKindOfClass:[NSNull class]]) {
            if ([value isKindOfClass:[NSDictionary class]]) {
                value = [value dictionaryByRemoveNULL];
            } else if ([value isKindOfClass:[NSArray class]]) {
                value = [value arrayByRemoveNULL];
            }
            [resultDict setObject:value forKey:key];
        }
    }
    return resultDict;
}

@end
