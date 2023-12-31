//
//  CJPayDyPayVerifyManagerQueen.m
//  Pods
//
//  Created by 利国卿 on 2022/9/19.
//

#import "CJPayDyPayVerifyManagerQueen.h"

#import "CJPayBaseVerifyManager.h"
#import "CJPayUIMacro.h"
#import "CJPayBDTypeInfo.h"
#import "CJPayKVContext.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeSumInfoModel.h"

@implementation CJPayDyPayVerifyManagerQueen

- (void)beforeConfirmRequest {
    [self.verifyManager sendEventTOVC:CJPayHomeVCEventEnableConfirmBtn obj:@(NO)];
}

- (void)afterConfirmRequestWithResponse:(nonnull CJPayOrderConfirmResponse *)orderResponse {
    [self trackVerifyWithEventName:@"wallet_cashier_confirm_error_info"
                            params:@{@"error_code": CJString(orderResponse.code),
                                     @"error_message": CJString(orderResponse.msg)}];
    [self.verifyManager sendEventTOVC:CJPayHomeVCEventEnableConfirmBtn obj:@(YES)];
    
}

- (void)afterLastQueryResultWithResultResponse:(CJPayBDOrderResultResponse *)response {
    
    BOOL isSkipPwdPay = [self.verifyManager.response.userInfo.pwdCheckWay isEqualToString:@"3"];
    [self trackCashierWithEventName:@"wallet_cashier_result" params:@{
        @"result" : (response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) ? @"1" : @"0",
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"risk_type" : CJString([self.verifyManager allRiskVerifyTypes]),
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType]),
        @"is_newcard" : self.verifyManager.isBindCardAndPay ? @"1" : @"0",
        @"activity_info" : [self p_activityInfoParamsWithVoucherArray:response.voucherDetails],
        @"pswd_pay_type" : isSkipPwdPay ? @"1" : @"0",
    }];
}

// 新追光埋点通参
- (NSDictionary *)cashierExtraTrackerParams {
    CJPayDefaultChannelShowConfig *selectConfig = self.verifyManager.homePageVC.curSelectConfig;
    NSString *payTypeStr = [CJPayBDTypeInfo getChannelStrByChannelType:selectConfig.type
                                                        isCombinePay:selectConfig.isCombinePay];
    CJPayBDCreateOrderResponse *response = self.verifyManager.response;
    CJPaySubPayTypeSumInfoModel *sumInfoModel = response.payTypeInfo.subPayTypeSumInfo;
    CJPaySubPayTypeInfoModel *firstInfoModel = sumInfoModel.subPayTypeInfoList.firstObject;
    BOOL isHaveBalance = [firstInfoModel.subPayType isEqualToString:@"balance"];    
    
    
    NSMutableDictionary *mutableDic = [@{
        @"pay_type" : CJString(payTypeStr),
        @"is_have_balance" : isHaveBalance ? @"1" : @"0", // 余额支付是否展示
        @"user_open_fxh_flag" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsIsCreavailable]), // 抖音月付是否可用
        @"fxh_method_list" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsCreditStageList]), // 抖音月付分期面板期数
        @"fxh_method" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsCreditStage]), // 抖音月付分期面板选中期数
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType]),
        @"first_method_list": @"bytepay",  //首页展示的一级支付方式
        @"second_method_list": CJString(payTypeStr), //首页展示的二级支付方式
        @"is_comavailable": @"0",  //组合支付是否可用
        @"is_balavailable" : sumInfoModel.balanceTypeData.balanceAmount > response.tradeInfo.tradeAmount ? @"1" : @"0",  //余额支付是否可用
        @"is_bankcard": sumInfoModel.isBindedCard ? @"1" : @"0", //首页是否展示绑卡
    } mutableCopy];
    
    [mutableDic cj_setObject:CJString([self.verifyManager.bizParams cj_stringValueForKey:@"prepayid"]) forKey:@"prepay_id"];
    [mutableDic cj_setObject:self.verifyManager.response.processInfo.processId forKey:@"process_id"];
    
    return [mutableDic copy];
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
@end
