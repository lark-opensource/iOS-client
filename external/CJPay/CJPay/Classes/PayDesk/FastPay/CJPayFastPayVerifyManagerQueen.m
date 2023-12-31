//
//  CJPayFastPayVerifyManagerQueen.m
//  Pods
//
//  Created by wangxiaohong on 2022/11/1.
//

#import "CJPayFastPayVerifyManagerQueen.h"

#import "CJPayFastPayVerifyManager.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayCombinePayFund.h"
#import "CJPayAlertUtil.h"
#import "CJPayHintInfo.h"
#import "CJPayKVContext.h"
#import "CJPayUIMacro.h"

@implementation CJPayFastPayVerifyManagerQueen

- (void)afterConfirmRequestWithResponse:(CJPayOrderConfirmResponse *)orderResponse
{
    [self trackCashierWithEventName:@"wallet_cashier_fastpay_confirm_info"
                             params:@{@"order_check": CJString([self.verifyManager lastVerifyCheckTypeName]),
                                      @"loading_time": [NSString stringWithFormat:@"%f", orderResponse.responseDuration],
                                      @"result": [orderResponse isSuccess]? @"1": @"0",
                                      @"error_code": CJString(orderResponse.code),
                                      @"error_msg": CJString(orderResponse.msg)}];
}

- (void)afterLastQueryResultWithResultResponse:(CJPayBDOrderResultResponse *)response {
    NSMutableDictionary *trackerParams = [NSMutableDictionary dictionary];
    [trackerParams addEntriesFromDictionary:@{
        @"result": (response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess) ? @"1" : @"0",
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"risk_type": CJString([self.verifyManager allRiskVerifyTypes]),
        @"bank_name" : CJString(response.tradeInfo.bankName),
        @"bank_type" : [response.tradeInfo.cardType isEqualToString:@"DEBIT"] ? @"储蓄卡" : @"信用卡",
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType])
    }];
    NSString *resultEventName = @"wallet_cashier_fastpay_result";
    [self trackCashierWithEventName:resultEventName params:[trackerParams copy]];
}

- (NSDictionary *)cashierExtraTrackerParams {
    NSMutableDictionary *mutableDic = [@{
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType])
    } mutableCopy];
    return [mutableDic copy];
}

@end
