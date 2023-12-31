//
//  CJPayUserInfoPassModel.m
//  CJPay
//
//  Created by 王新华 on 10/29/19.
//

#import "CJPayUserInfoPassModel.h"
#import "CJPaySDKMacro.h"

@implementation CJPayUserInfoPassModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"extModel" : @"ext",
        @"extDic" : @"ext",
        @"isNeedLogin" : @"is_need_union_pass",
        @"passportStatus" : @"passport_status",
        @"url": @"url",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (NSString *)redirectUrl {
    return self.extModel.redirectUrl;
}

@end


@implementation CJPayPassExtModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary: @{
        @"agreements" : @"agreements",
        @"authUidMaskMobile" : @"authUidMaskMobile",
        @"entrance" : @"entrance",
        @"isNeedAgreementUpgrade" : @"isNeedAgreementUpgrade",
        @"merchantId" : @"merchantId",
        @"merchantName" : @"merchantName",
        @"mobileAuthPageInfo" : @"mobileAuthPageInfo",
        @"pidMobile" : @"pidMobile",
        @"redirectUrl" : @"redirectUrl",
        @"scene" : @"scene",
        @"status" : @"status",
        @"upgradeAgreements" : @"upgradeAgreements",
        @"aid":@"aid",
        @"createEntranceTitle":@"createEntranceTitle",
        @"dataUserStatus":@"dataUserStatus",
        @"isNeedCheck":@"isNeedCheck",
        @"randomStr":@"randomStr",
        @"tagAid": @"tagAid",
        @"uid": @"uid",
        @"upgradeIsNeedCheck": @"upgradeIsNeedCheck"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
