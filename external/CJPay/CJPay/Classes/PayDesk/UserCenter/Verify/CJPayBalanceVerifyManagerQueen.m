//
//  CJPayBalanceVerifyManagerQueen.m
//  Pods
//
//  Created by wangxiaohong on 2021/12/6.
//

#import "CJPayBalanceVerifyManagerQueen.h"

#import "CJPayBaseVerifyManager.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayBalanceVerifyManager.h"
#import "CJPayBindCardManager.h"

@implementation CJPayBalanceVerifyManagerQueen

- (void)afterConfirmRequestWithResponse:(CJPayOrderConfirmResponse *)orderResponse {
    [self trackVerifyWithEventName:@"wallet_cashier_confirm_error_info"
                            params:@{@"error_code": CJString(orderResponse.code),
                                     @"error_message": CJString(orderResponse.msg)}];
}

- (NSDictionary *)cashierExtraTrackerParams {
    if (![self.verifyManager isKindOfClass:CJPayBalanceVerifyManager.class]) {
        return @{};
    }
    CJPayBalanceVerifyManager *balanceVerifyManager = (CJPayBalanceVerifyManager *)self.verifyManager;
    
    CJPayBDCreateOrderResponse *response = self.verifyManager.response;
    NSString *amountStr = CJString([[balanceVerifyManager.payContext.confirmRequestParams cj_dictionaryValueForKey:@"pre_params"] cj_stringValueForKey:@"total_amount"]);
    
    NSDictionary *bindCardTrackerBaseParams = [[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams];
    NSMutableDictionary *mutableDict = [@{
        @"twoelements_verify_status": @"0",
        @"type": @"可变金额",
        @"balance_amount": CJString(response.userInfo.balanceAmount),
        @"account_type": @"银行卡",
        @"version": @"普通",
        @"is_have_balance" : CJString(response.preTradeInfoWrapper.trackInfo.balanceStatus), // 余额支付是否展示
        @"caijing_source": balanceVerifyManager.balanceVerifyType == CJPayBalanceVerifyTypeRecharge ? @"充值收银台" : @"提现收银台",
        @"amount": amountStr,
        @"check_type" : CJString([self.verifyManager lastVerifyCheckTypeName]),
        @"issue_check_type": CJString([self.verifyManager issueCheckType]),
        @"real_check_type":CJString([self.verifyManager.lastWakeVerifyItem checkType]),
        @"is_bankcard": CJString(response.preTradeInfoWrapper.trackInfo.bankCardStatus),
        @"needidentify" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"needidentify"]),
        @"haspass" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"haspass"])
    } mutableCopy];
    
    if (balanceVerifyManager.balanceVerifyType == CJPayBalanceVerifyTypeWithdraw) {
        [mutableDict cj_setObject:@(response.tradeInfo.tradeAmount) forKey:@"tixian_amount"];
    }
    return [mutableDict copy];
}

@end
