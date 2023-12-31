//
//  CJPaySuperPayVerifyManagerQueen.m
//  Pods
//
//  Created by wangxiaohong on 2022/11/1.
//

#import "CJPaySuperPayVerifyManagerQueen.h"
#import "CJPaySuperPayVerifyManager.h"
#import "CJPayCombinePayFund.h"
#import "CJPayAlertUtil.h"
#import "CJPayHintInfo.h"
#import "CJPayKVContext.h"
#import "CJPaySDKMacro.h"
#import "CJPaySuperPayController.h"

@implementation CJPaySuperPayVerifyManagerQueen

- (void)afterConfirmRequestWithResponse:(CJPayOrderConfirmResponse *)orderResponse {
    [self trackCashierWithEventName:@"wallet_cashier_confirm_error_info"
                             params:@{@"order_check": CJString([self.verifyManager lastVerifyCheckTypeName]),
                                      @"loading_time": [NSString stringWithFormat:@"%f", orderResponse.responseDuration],
                                      @"result": [orderResponse isSuccess] ? @"1" : @"0",
                                      @"error_code": CJString(orderResponse.code),
                                      @"error_msg": CJString(orderResponse.msg)}];
}

- (void)afterLastQueryResultWithResultResponse:(CJPayBDOrderResultResponse *)response {
        
    NSMutableDictionary *trackerParams = [[self p_buildStatusTrackParams:response] mutableCopy];
    [trackerParams addEntriesFromDictionary:@{
        @"result": (response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) ? @"1" : @"0",
        @"activity_info" : @"",
        @"bank_name" : CJString(response.tradeInfo.bankName),
        @"bank_type" : [response.tradeInfo.cardType isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡"
    }];
    [self trackCashierWithEventName:@"wallet_cashier_result" params:[trackerParams copy]];
}

- (NSDictionary *)cashierExtraTrackerParams {
    CJPayBDCreateOrderResponse *response = self.verifyManager.response;

    NSMutableDictionary *trackDic = [@{
        @"pre_method" : @"Pre_Pay_SuperPay",
        @"is_pswd_guide" : response.skipPwdGuideInfoModel.needGuide ? @"1" : @"0",
        @"is_pswd_default" : response.skipPwdGuideInfoModel.isChecked ? @"1" : @"0",
        @"is_chaselight" : @"1",
        @"identity_type" : @"1",
        @"pswd_pay_type" : @"2",
        @"is_newcard" : self.verifyManager.isBindCardAndPay ? @"1" : @"0",
        @"risk_type": CJString([self.verifyManager allRiskVerifyTypes]),
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType])
    } mutableCopy];
    if ([self.verifyManager.homePageVC isKindOfClass:CJPaySuperPayController.class]) {
        [trackDic cj_setObject:CJString(((CJPaySuperPayController *)self.verifyManager.homePageVC).tradeNo) forKey:@"trade_no"];
    }
    
    return [trackDic copy];
}

- (NSDictionary *)p_buildStatusTrackParams:(CJPayBDOrderResultResponse *)response {
    NSString *errorMessage, *errorCode, *status;
    switch (response.tradeInfo.tradeStatus) {
        case CJPayOrderStatusSuccess:
            errorMessage = @"";
            errorCode = @"";
            status = @"成功";
            break;
        case CJPayOrderStatusFail:
            errorMessage = @"极速付付款失败";
            errorCode = @"";
            status = @"失败";
        default:
            errorMessage = @"极速付付款超时";
            errorCode = @"";
            status = @"超时";
    }
    NSMutableDictionary *trackParams = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"status" : CJString(status),
        @"error_code" : CJString(errorCode),
        @"error_message" : CJString(errorMessage),
    }];
    return [trackParams copy];
}
@end
