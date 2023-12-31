//
//  CJPayAuthCreateResponse.m
//  CJPay
//
//  Created by wangxiaohong on 2020/5/26.
//

#import "CJPayAuthCreateResponse.h"

@implementation CJPayAuthCreateResponse

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"code": @"response.code",
        @"msg": @"response.msg"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
