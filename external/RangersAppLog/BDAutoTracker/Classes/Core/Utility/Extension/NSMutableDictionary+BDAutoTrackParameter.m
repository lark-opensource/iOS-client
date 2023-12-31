//
//  NSMutableDictionary+BDAutoTrackParameter.m
//  RangersAppLog
//
//  Created by SoulDiver on 2022/5/30.
//

#import "NSMutableDictionary+BDAutoTrackParameter.h"

@implementation NSMutableDictionary (BDAutoTrackParameter)

- (void)bdheader_setValue:(nullable id)value forKey:(NSString *)key
{
    if (![key isKindOfClass:[NSString class]] || [key length] == 0) {
        return;
    }
    NSString *formatedKey = [key copy];
    if ([key hasPrefix:@"$"]) {
        formatedKey = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
    }
    [self setValue:value forKey:formatedKey];
}

- (void)bdheader_keyFormat;
{
    NSArray<NSString *> *allkeys = [self allKeys];
    [allkeys enumerateObjectsUsingBlock:^(NSString * _Nonnull headerKey, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([headerKey hasPrefix:@"$"]) {
            NSString *formatedKey = [headerKey stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
            // 直接将带 $ 的字符覆盖原值，以带 $ 字段的值为准
            id v = [self valueForKey:headerKey];
            [self setValue:v forKey:formatedKey];
            [self removeObjectForKey:headerKey];
        }
    }];
}

@end
