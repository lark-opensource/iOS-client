//
//  CJPayBackBlockModel.m
//  CJPay
//
//  Created by liyu on 2020/1/15.
//

#import "CJPayBackBlockModel.h"


@implementation CJBackBlockActionModel

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"title" : @"title",
                @"fontWeight" : @"font_weight",
                @"action" : @"action",
            }];
}

@end

@implementation CJPayBackBlockModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"title" : @"title",
                @"context" : @"context",
                @"policy" : @"policy",
                @"confirmModel" : @"confirm",
                @"cancelModel" : @"cancel"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

