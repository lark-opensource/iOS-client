//
//  CJPayInfo.m
//  Pods
//
//  Created by 易培淮 on 2020/11/17.
//

#import "CJPayInfo.h"
#import "CJPaySDKMacro.h"
#import "CJPaySubPayTypeDisplayInfo.h"
#import "CJPayBytePayCreditPayMethodModel.h"

@implementation BDPayCombinePayShowInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"combineType" : @"combine_type",
                @"combineMsg" : @"combine_msg"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

@end

@implementation CJPayInfo

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
                @"businessScene" : @"business_scene",
                @"bankCardId" : @"bank_card_id",
                @"creditPayInstallment":@"credit_pay_installment",
                @"payAmountPerInstallment": @"pay_amount_per_installment",
                @"originFeePerInstallment": @"origin_fee_per_installment",
                @"realFeePerInstallment": @"real_fee_per_installment",
                @"voucherNoList": @"voucher_no_list",
                @"decisionId": @"decision_id",
                @"realTradeAmount": @"real_trade_amount",
                @"realTradeAmountRaw" : @"real_trade_amount_raw",
                @"originTradeAmount": @"origin_trade_amount",
                @"voucherMsg": @"voucher_msg",
                @"isCreditActivate": @"is_credit_activate",
                @"creditActivateUrl": @"credit_activate_url",
                @"isNeedJumpTargetUrl" : @"is_need_jump_target_url",
                @"targetUrl" : @"target_url",
                @"voucherType": @"voucher_type",
                @"payName": @"pay_name",
                @"cashierTags": @"cashier_tag",
                @"verifyDescType": @"verify_desc_type",
                @"verifyDesc": @"verify_desc",
                @"localVerifyDownGradeDesc" : @"local_verify_downgrade_desc",
                @"verifyDowngradeReason" : @"verify_downgrade_reason",
                @"tradeDesc": @"trade_desc",
                @"currency": @"currency",
                @"hasRandomDiscount": @"has_random_discount",
                @"iconUrl": @"pay_icon",
                @"retainInfo": @"retain_info",
                @"retainInfoV2": @"retain_info_v2",
                @"combineType": @"combine_type",
                @"primaryPayType": @"primary_pay_type",
                @"combineShowInfo": @"combine_show_info",
                @"guideVoucherLabel" : @"guide_voucher_label",
                @"priceZoneShowStyle": @"price_zone_show_style",
                @"standardRecDesc": @"standard_rec_desc",
                @"standardShowAmount": @"standard_show_amount",
                @"subPayTypeDisplayInfoList": @"sub_pay_type_display_info_list",
                @"showChangePaytype": @"show_change_paytype"
            }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (BOOL)isCombinePay {
    return self.combineShowInfo.count != 0;
}

- (BOOL)needShowStandardVoucher {
    return [self.priceZoneShowStyle isEqualToString:@"LINE"] &&
    Check_ValidString(self.standardShowAmount) &&
    Check_ValidString(self.standardRecDesc);
}

- (CJPayBytePayCreditPayMethodModel *)buildCreditPayMethodModel {
    CJPayBytePayCreditPayMethodModel *model = [CJPayBytePayCreditPayMethodModel new];
    model.installment = CJString(self.creditPayInstallment);
    model.standardRecDesc = CJString(self.standardRecDesc);
    model.standardShowAmount = CJString(self.standardShowAmount);
    model.choose = YES;
    return model;
}

- (BOOL)isDynamicLayout {
    return [self.cashierTags containsObject:@"fe_tag_static_forget_pwd_style"] || [self.cashierTags containsObject:@"fe_tag_guide_mid_style"];
}
@end




