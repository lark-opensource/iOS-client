//
//  CJPaySignPayTemplateInfo.m
//  CJPay-a399f1d1
//
//  Created by wangxiaohong on 2022/9/15.
//

#import "CJPaySignPayTemplateInfo.h"

@implementation CJPaySignPayTemplateInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"templateId": @"template_id",
                @"zgMerchantId": @"zg_merchant_id",
                @"zgMerchantName": @"zg_merchant_name",
                @"zgMerchantAppid": @"zg_merchant_app_id",
                @"serviceName": @"service_name",
                @"icon": @"icon",
                @"serviceDesc": @"service_desc",
                @"pageTitle": @"page_title",
                @"buttonDesc": @"button_desc",
                @"supportPayType": @"support_pay_type"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end
