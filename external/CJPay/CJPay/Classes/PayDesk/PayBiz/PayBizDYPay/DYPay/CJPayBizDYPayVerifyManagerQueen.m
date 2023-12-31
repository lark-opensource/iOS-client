//
//  CJPayBizDYPayVerifyManagerQueen.m
//  Pods
//
//  Created by wangxiaohong on 2022/10/18.
//

#import "CJPayBizDYPayVerifyManagerQueen.h"

#import "CJPayBizDYPayVerifyManager.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayCombinePayFund.h"
#import "CJPayAlertUtil.h"
#import "CJPayHintInfo.h"
#import "CJPayKVContext.h"
#import "CJPayUIMacro.h"

@implementation CJPayBizDYPayVerifyManagerQueen

- (void)afterConfirmRequestWithResponse:(CJPayOrderConfirmResponse *)orderResponse
{
    [self trackVerifyWithEventName:@"wallet_cashier_confirm_error_info"
                            params:@{@"error_code": CJString(orderResponse.code),
                                     @"error_message": CJString(orderResponse.msg)}];
    [self.verifyManager sendEventTOVC:CJPayHomeVCEventConfirmRequestError obj:@{
        @"error_message": CJString(orderResponse.msg),
        @"error_code" : CJString(orderResponse.code)
    }];
}

- (NSArray *)p_activityInfoParamsWithVoucherArray:(NSArray<NSDictionary *> *)voucherArray {
    NSMutableArray *activityInfos = [NSMutableArray array];
    [voucherArray enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.count > 0) {
            [activityInfos btd_addObject:@{
                @"id" : CJString([obj cj_stringValueForKey:@"voucher_no"]),
                @"type": [[obj cj_stringValueForKey:@"voucher_type"] isEqualToString:@"discount_voucher"] ? @"0" : @"1",
                @"front_bank_code": Check_ValidString([obj cj_stringValueForKey:@"credit_pay_installment"]) ?
                    CJString([obj cj_stringValueForKey:@"credit_pay_installment"]) : CJString([obj cj_stringValueForKey:@"front_bank_code"]),
                @"reduce" : @([obj cj_intValueForKey:@"used_amount"]),
                @"label": CJString([obj cj_stringValueForKey:@"label"])
            }];
        }
    }];
    return activityInfos;
}

- (void)afterLastQueryResultWithResultResponse:(CJPayBDOrderResultResponse *)response {
    
    BOOL isSkipPwdPay = [self.verifyManager.response.userInfo.pwdCheckWay isEqualToString:@"3"];

    NSString *balanceAmount = @"";
    NSString *cardAmount = @"";
    for (CJPayCombinePayFund *fund in response.tradeInfo.combinePayFundList) {
        if ([fund.fundType isEqualToString:@"balance"]) {
            balanceAmount = @(fund.fundAmount).stringValue;
        }
        if ([fund.fundType isEqualToString:@"bankcard"]) {
            cardAmount = @(fund.fundAmount).stringValue;
        }
    }
    
    NSMutableDictionary *trackerParams = [NSMutableDictionary dictionary];
    [trackerParams addEntriesFromDictionary:@{
        @"result": (response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) ? @"1" : @"0",
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"risk_type": CJString([self.verifyManager allRiskVerifyTypes]),
        @"is_newcard" : self.verifyManager.isBindCardAndPay ? @"1" : @"0",
        @"activity_info" : [self p_activityInfoParamsWithVoucherArray:response.voucherDetails],
        @"bank_name" : CJString(response.tradeInfo.bankName),
        @"pswd_pay_type" : isSkipPwdPay ? @"1" : @"0",
        @"balance_amount": CJString(balanceAmount),
        @"card_amount": CJString(cardAmount),
        @"bank_type" : [response.tradeInfo.cardType isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡",
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType])
    }];
    [self trackCashierWithEventName:@"wallet_cashier_result" params:[trackerParams copy]];
}


- (NSDictionary *)cashierExtraTrackerParams {
    CJPayBDCreateOrderResponse *response = self.verifyManager.response;
    CJPayDefaultChannelShowConfig *selectConfig = self.verifyManager.homePageVC.curSelectConfig;
    NSString *payTypeStr = [CJPayBDTypeInfo getChannelStrByChannelType:selectConfig.type
                                                        isCombinePay:selectConfig.isCombinePay];
    NSString *preMethod = CJString(response.payInfo.businessScene);
    if([preMethod isEqualToString:@"Pre_Pay_Combine"]) {
        if([response.payInfo.primaryPayType isEqualToString:@"bank_card"]) {
            preMethod = @"Pre_Pay_Balance_Bankcard";
        }
        else if ([response.payInfo.primaryPayType isEqualToString:@"new_bank_card"]) {
            preMethod = @"Pre_Pay_Balance_Newcard";
        }
    }
    NSMutableDictionary *mutableDic = [@{
        @"pre_method" : preMethod,
        @"is_pswd_guide" : response.skipPwdGuideInfoModel.needGuide ? @"1" : @"0",
        @"is_pswd_default" : response.skipPwdGuideInfoModel.isChecked ? @"1" : @"0",
        @"pswd_pay_type" : [response.userInfo.pwdCheckWay isEqualToString:@"3"] ? @"1" : @"0",
        @"user_open_fxh_flag" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsIsCreavailable]),
        @"fxh_method_list" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsCreditStageList]),
        @"fxh_method" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsCreditStage]),
        @"pay_type" : CJString(payTypeStr),
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType])
    } mutableCopy];
    
    if ([self.verifyManager isKindOfClass:CJPayBizDYPayVerifyManager.class]) {
        CJPayBizDYPayVerifyManager *verifyManager = (CJPayBizDYPayVerifyManager *)self.verifyManager;
        [mutableDic addEntriesFromDictionary:verifyManager.trackParams];
        [mutableDic cj_setObject:self.verifyManager.response.processInfo.processId forKey:@"process_id"];
    }
    
    return [mutableDic copy];
}


@end
