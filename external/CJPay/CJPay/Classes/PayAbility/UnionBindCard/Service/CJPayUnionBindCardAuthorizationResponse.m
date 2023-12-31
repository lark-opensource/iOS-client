//
//  CJPayUnionBindCardAuthorizationResponse.m
//  Pods
//
//  Created by chenbocheng on 2021/9/28.
//

#import "CJPayUnionBindCardAuthorizationResponse.h"

@implementation CJPayUnionBindCardAuthorizationResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"authorizationIconUrl" : @"response.union_pay_authorization.authorization_icon_url",
        @"nameMask" : @"response.union_pay_authorization.name_mask",
        @"idCodeMask" : @"response.union_pay_authorization.id_code_mask",
        @"mobileMask" : @"response.union_pay_authorization.mobile_mask",
        @"guideMessage" : @"response.union_pay_authorization.guide_message",
        @"protocolGroupNames" : @"response.union_pay_authorization.protocol_group_names",
        @"agreements" : @"response.union_pay_authorization.protocol_list",
    }];
    [dic addEntriesFromDictionary:[self basicDict]];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dic copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
