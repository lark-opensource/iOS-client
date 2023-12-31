//
//  CJPayAuthDisplayContentModel.m
//  CJPay
//
//  Created by wangxiaohong on 2020/5/25.
//

#import "CJPayAuthDisplayContentModel.h"

@implementation CJPayAuthDisplayContentModel

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"displayDesc": @"display_desc",
        @"displayUrl": @"display_url"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
