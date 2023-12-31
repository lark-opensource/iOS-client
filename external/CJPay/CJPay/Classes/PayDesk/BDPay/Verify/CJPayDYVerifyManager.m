//
//  CJPayDYVerifyManager.m
//  Pods
//
//  Created by wangxiaohong on 2020/2/19.
//

#import "CJPayDYVerifyManager.h"

#import "CJPayUIMacro.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayToast.h"
#import "UIViewController+CJPay.h"

@implementation CJPayDYVerifyManager

- (NSDictionary *)buildConfirmRequestParamsByCurPayChannel {
    if (!self.isPayAgainRecommend) {
        return [super buildConfirmRequestParamsByCurPayChannel];
    }
    NSMutableDictionary *dict = [[super buildConfirmRequestParamsByCurPayChannel] mutableCopy];
    NSDictionary *processInfoParams = [self.confirmResponse.processInfo toDictionary];
    [dict cj_setObject:processInfoParams forKey:@"process_info"];
    return [dict copy];
}

- (void)confirmRequestSuccess:(CJPayOrderConfirmResponse *)response withChannelType:(CJPayChannelType)channelType
{
    if (![response isSuccess]) {
        @CJStopLoading(self);
        if ([response.code isEqualToString:@"CD005008"]) {
            [self sendEventTOVC:CJPayHomeVCEventRecommendPayAgain obj:response];
            return;
        }
        if ([response.code isEqualToString:@"CD005028"]) {
            [self sendEventTOVC:CJPayHomeVCEventDiscountNotAvailable obj:response];
            return;
        }
        
        if (self.isBindCardAndPay) { // 绑卡成功支付失败
            [self sendEventTOVC:CJPayHomeVCEventBindCardSuccessPayFail obj:response];
            return;
        }
        
        NSString *msg = response.msg;
        if (!Check_ValidString(msg)) {
            msg = CJPayLocalizedStr(@"支付失败，请重试");
        }
        if (!response) {
            msg = CJPayNoNetworkMessage;
        }
        [CJToast toastText:msg inWindow:[self.homePageVC topVC].cj_window];
        [CJMonitor trackService:@"wallet_rd_paydesk_confirm_failed" category:@{@"code":CJString(response.code), @"msg":CJString(response.msg), @"desk_identify": @"三方收银台", @"is_pay_newcard": self.isBindCardAndPay ? @"1" : @"0"} extra:@{}];
        return;
    }
    [super confirmRequestSuccess:response withChannelType:channelType];
}

#pragma mark - CJPayVerifyManagerPayNewCardProtocol
- (void)onBindCardAndPayAction {
    [super onBindCardAndPayAction];
    
    CJPayBindCardSharedDataModel *bindModel = [self.response buildBindCardCommonModel];
    @CJWeakify(self)
    @CJStartLoading(self.homePageVC)
    bindModel.dismissLoadingBlock = ^{
        @CJStrongify(self);
        @CJStopLoading(self.homePageVC)
    };
    
    bindModel.completion = ^(CJPayBindCardResultModel * _Nonnull resModel) {
        @CJStrongify(self);
        switch (resModel.result) {
            case CJPayBindCardResultSuccess: {
                self.bindcardResultModel = resModel;
                [self sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
                [self submitConfimRequest:@{} fromVerifyItem:nil];
                break;
            }
            case CJPayBindCardResultCancel:
            default:
                break;
        }
    };
    
    bindModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceBdpayCashier;
    [CJ_OBJECT_WITH_PROTOCOL(CJPayCardManageModule) i_bindCardAndPay:bindModel];
}

@end
