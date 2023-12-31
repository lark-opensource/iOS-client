//
//  CJPayDYVerifyManagerQueen.m
//  CJPay
//
//  Created by wangxiaohong on 2020/2/20.
//

#import "CJPayDYVerifyManagerQueen.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayUIMacro.h"
#import "CJPayBDTypeInfo.h"
#import "CJPayKVContext.h"

@implementation CJPayDYVerifyManagerQueen

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
    [self trackCashierWithEventName:@"wallet_cashier_result" params:@{
        @"result" : (response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) ? @"1" : @"0",
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"risk_type" : CJString([self.verifyManager allRiskVerifyTypes]),
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType])
    }];
}

- (NSDictionary *)cashierExtraTrackerParams {
    CJPayDefaultChannelShowConfig *selectConfig = self.verifyManager.homePageVC.curSelectConfig;
    NSString *payTypeStr = [CJPayBDTypeInfo getChannelStrByChannelType:selectConfig.type
                                                        isCombinePay:selectConfig.isCombinePay];
    NSMutableDictionary *mutableDic = [@{
        @"pay_type" : CJString(payTypeStr),
        @"is_have_balance" : @"0", // 余额支付是否展示
        @"user_open_fxh_flag" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsIsCreavailable]),
        @"fxh_method_list" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsCreditStageList]),
        @"fxh_method" : CJString([CJPayKVContext kv_stringForKey:CJPayTrackerCommonParamsCreditStage]),
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType])
    } mutableCopy];
    
    [mutableDic cj_setObject:self.verifyManager.response.processInfo.processId forKey:@"process_id"];
    return [mutableDic copy];
}

@end
