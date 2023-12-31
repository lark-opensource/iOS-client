//
//  CJPayAuthQueryResponse.m
//  CJPay
//
//  Created by wangxiaohong on 2020/5/25.
//

#import "CJPayAuthQueryResponse.h"

@implementation CJPayAuthQueryResponse

+ (JSONKeyMapper *)keyMapper
{
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"code": @"response.code",
        @"msg": @"response.msg",
        @"isAuthorize": @"response.is_authorize",
        @"isAuth": @"response.is_auth",
        @"authUrl": @"response.auth_url",
        @"agreementContentModel": @"response.authorization_agreement_info"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
