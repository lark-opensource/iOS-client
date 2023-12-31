//
//  CJPayFastPayVerifyManager.m
//  Pods
//
//  Created by wangxiaohong on 2022/11/1.
//

#import "CJPayFastPayVerifyManager.h"

#import "CJPayUIMacro.h"
#import "CJPayEnumUtil.h"
#import "CJPayOneKeyConfirmRequest.h"
#import "CJPayMetaSecManager.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayToast.h"
#import "UIViewController+CJPay.h"

@implementation CJPayFastPayVerifyManager

- (void)requestConfirmPayWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse withExtraParams:(NSDictionary *)extraParams completion:(void (^)(NSError * _Nonnull, CJPayOrderConfirmResponse * _Nonnull))completionBlock {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeRiskUserVerifyResult];
    [CJPayOneKeyConfirmRequest startWithOrderResponse:orderResponse
                                      withExtraParams:extraParams
                                           completion:^(NSError * _Nonnull error, CJPayOrderConfirmResponse * _Nonnull response) {
        CJ_CALL_BLOCK(completionBlock,error,response);
    }];
}

- (void)confirmRequestSuccess:(CJPayOrderConfirmResponse *)response withChannelType:(CJPayChannelType)channelType
{
    if (![response isSuccess]) {
        @CJStopLoading(self);
        NSString *toastMsg = Check_ValidString(response.msg) ? response.msg : CJPayNoNetworkMessage;
        [CJToast toastText:toastMsg inWindow:[self.homePageVC topVC].cj_window];
        [CJMonitor trackService:@"wallet_rd_paydesk_confirm_failed"
                       category:@{@"code":CJString(response.code),
                                  @"msg":CJString(response.msg),
                                  @"desk_identify": @"极速支付收银台",
                                  @"is_pay_newcard": self.isBindCardAndPay ? @"1" : @"0"}
                          extra:@{}];
        [self sendEventTOVC:CJPayHomeVCEventOccurUnHandleConfirmError obj:response];
        
        return;
    }
    // 一键极速支付不用查单, 直接回调聚合支付成功
    NSDictionary *queryResponseDic = @{@"response": response.tradeQueryResponseDic ?: @{}};
    CJPayBDOrderResultResponse *orderResultResponse = [[CJPayBDOrderResultResponse alloc] initWithDictionary:queryResponseDic
                                                                                             error:nil];
    if (self.verifyManagerQueen && [self.verifyManagerQueen respondsToSelector:@selector(afterLastQueryResultWithResultResponse:)]) {
        [self.verifyManagerQueen afterLastQueryResultWithResultResponse:orderResultResponse];
    }
    [self.homePageVC endVerifyWithResultResponse:orderResultResponse];
}

@end
