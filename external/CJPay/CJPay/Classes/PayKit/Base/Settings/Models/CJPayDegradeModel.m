//
//  BDPayMercahntMappingModel.m
//  Pods
//
//  Created by wangxiaohong on 2020/8/19.
//

#import "CJPayDegradeModel.h"

@implementation CJPayDegradeModel

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"bdpayAppId" : @"bdpay_app_id",
                @"cjpayAppId" : @"cjpay_app_id",
                @"bdpayMerchantId" : @"bdpay_merchant_id",
                @"cjpayMerchantId" : @"cjpay_merchant_id",
                @"isPayUseH5" : @"is_pay_use_h5",
                @"isBalanceWithdrawUseH5" : @"is_balance_withdraw_use_h5",
                @"isBalanceRechargeUseH5" : @"is_balance_recharge_use_h5",
                @"isCardListUseH5" : @"is_card_list_use_h5",
                @"isBDPayUseH5" : @"is_bdpay_use_h5",
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end
