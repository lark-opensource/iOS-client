//
//  CJPaySignPageInfoModel.m
//  CJPaySandBox
//
//  Created by ByteDance on 2023/6/30.
//

#import "CJPaySignPageInfoModel.h"
#import "CJPayMemAgreementModel.h"

@implementation CJPaySignPageInfoModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"merchantName" :@"merchant_name",
        @"serviceName" :@"service_name",
        @"icon" :@"icon",
        @"serviceDesc" :@"service_desc",
        @"templateId" :@"template_id",
        @"tradeAmount" :@"trade_amount",
        @"realTradeAmount" :@"real_trade_amount",
        @"promotionDesc" :@"promotion_desc",
        @"nextDeductDate" :@"next_deduct_date",
        @"protocolInfo" :@"protocol_info",
        @"protocolGroupNames" :@"protocol_group_names",
        @"paySignSwitch" :@"pay_sign_switch",
        @"paySignSwitchInfo" :@"pay_sign_switch_info",
        @"deductMethodSubDesc" :@"deduct_method_sub_desc",
        @"buttonAction" :@"button_action",
        @"buttonDesc" :@"button_desc",
        @"signPageURL":@"sign_page_url",
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}


@end
