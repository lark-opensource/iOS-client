//
//  CJPaySubPayTypeData.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/12.
//

#import "CJPaySubPayTypeData.h"
#import "CJPayCreditPayMethodModel.h"
#import "CJPaySubPayTypeIconTipModel.h"
#import "CJPayCombinePayInfoModel.h"
#import "CJPayUIMacro.h"

@interface CJPaySubPayTypeData()

@property (nonatomic, strong) CJPayBytePayCreditPayMethodModel *creditModel;

@end

@implementation CJPaySubPayTypeData

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:@{
        @"showCombinePay": @"show_combine_pay",
        @"mobileMask": @"mobile_mask",
        @"balanceAmount": @"balance_amount",
        @"incomeAmount": @"income_amount",
        @"voucherMsgList": @"voucher_msg_list",
        @"bytepayVoucherMsgList": @"bytepay_voucher_msg_list",
        @"subPayVoucherMsgList":@"sub_pay_voucher_msg_list",
        @"voucherInfo": @"voucher_info",
        @"voucherMsgV2Model": @"pay_type_voucher_msg_v2",
        @"freezedAmount": @"freezed_amount",
        @"bankCardId": @"bank_card_id",
        @"cardNo": @"card_no",
        @"cardNoMask": @"card_no_mask",
        @"cardType": @"card_type",
        @"cardTypeName": @"card_type_name",
        @"cardStyleShortName": @"card_style_short_name",
        @"supportOneKeySign": @"support_one_key_sign",
        @"frontBankCode": @"front_bank_code",
        @"frontBankCodeName": @"front_bank_code_name",
        @"bankName": @"bank_name",
        @"cardShowName": @"card_show_name",
        @"cardLevel": @"card_level",
        @"perdayLimit": @"perday_limit",
        @"perpayLimit": @"perpay_limit",
        @"bankCode": @"bank_code",
        @"signNo": @"sign_no",
        @"creditPayMethods": @"credit_pay_methods",
        @"cardAddExt": @"card_add_ext",
        @"iconTips": @"icon_tips",
        @"recommendType": @"recommend_type",
        @"isCreditActivate": @"is_credit_activate",
        @"decisionId": @"decision_id",
        @"creditActivateUrl": @"credit_activate_url",
        @"creditSignUrl" : @"credit_sign_url",
        @"standardRecDesc" : @"standard_rec_desc",
        @"standardShowAmount" : @"standard_show_amount",
        @"combineShowInfo": @"combine_show_info",
        @"combinePayInfo" : @"combine_pay_info",
        @"selectPageGuideText": @"select_page_guide_text",
        @"voucherDescText" : @"voucher_desc_text",
        @"tradeAreaVoucher": @"trade_area_voucher",
        @"subExt": @"sub_ext"
    }];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName
{
    return YES;
}

- (void)updateDefaultCreditModel:(CJPayBytePayCreditPayMethodModel *)creditModel {
    self.creditModel = creditModel;
}

- (CJPayBytePayCreditPayMethodModel *)curSelectCredit {
    __block CJPayBytePayCreditPayMethodModel *currentSelectModel = nil;
    if (Check_ValidArray(self.creditPayMethods)) {
        [self.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.choose) {
                currentSelectModel = obj;
                *stop = YES;
            }
        }];
    } else if (self.creditModel) {
        currentSelectModel = self.creditModel;
    } else {
        currentSelectModel = [CJPayBytePayCreditPayMethodModel new];
        currentSelectModel.installment = @"1";
        currentSelectModel.standardRecDesc = self.standardRecDesc;
        currentSelectModel.standardShowAmount = self.standardShowAmount;
        currentSelectModel.payTypeDesc = CJPayLocalizedStr(@"不分期");
        currentSelectModel.feeDesc = CJPayLocalizedStr(@"免手续费");
    }
    return currentSelectModel;
}

- (NSString *)obtainOutDisplayMsg:(CJPayOutDisplayTradeAreaMsgType)msgType {
    NSString *tradeAreaMsgKey = @"";
    if (msgType == CJPayOutDisplayTradeAreaMsgTypePayBackVoucher) {
        tradeAreaMsgKey = @"pay_back_voucher";
    } else if (msgType == CJPayOutDisplayTradeAreaMsgTypeSubPayTypeVoucher) {
        tradeAreaMsgKey = @"sub_pay_type_voucher";
    } else if (msgType == CJPayOutDisplayTradeAreaMsgTypeOrderAmountText) {
        tradeAreaMsgKey = @"order_amount_text";
    } else if (msgType == CJPayOutDisplayTradeAreaMsgTypeSubPayTypeCombineVoucher) {
        tradeAreaMsgKey = @"sub_pay_type_combine_voucher";
    }
    return [self.tradeAreaVoucher cj_stringValueForKey:tradeAreaMsgKey defaultValue:@""];
}

@end
