//
//  CJPayMerchantInfo.m
//  CJPay
//
//  Created by jiangzhongping on 2018/8/21.
//

#import "CJPayMerchantInfo.h"

@implementation CJPayMerchantInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"merchantId" : @"merchant_id",
                @"merchantName" : @"merchant_name",
                @"merchantShortName" : @"merchant_short_name",
                @"merchantShortToCustomer" : @"merchant_short_to_customer",
                @"appId" : @"app_id",
                @"intergratedMerchantId" : @"jh_merchant_id",
                @"jhAppId": @"jh_app_id"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
