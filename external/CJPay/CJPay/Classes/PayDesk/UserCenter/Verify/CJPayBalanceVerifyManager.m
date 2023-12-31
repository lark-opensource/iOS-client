//
//  CJPayBalanceVerifyManager.m
//  Pods
//
//  Created by wangxiaohong on 2021/12/6.
//

#import "CJPayBalanceVerifyManager.h"

#import "CJPayBalanceVerifyManagerQueen.h"
#import "CJPayUIMacro.h"
#import "CJPayVerifyItemSignCard.h"
#import "CJPaySettingsManager.h"

@interface CJPayBalanceVerifyManager()

@property (nonatomic, strong) CJPayBalanceVerifyManagerQueen *queen;

@end

@implementation CJPayBalanceVerifyManager

- (CJPayBaseVerifyManagerQueen *)verifyManagerQueen {
    return self.queen;
}

- (CJPayBalanceVerifyManagerQueen *)queen {
    if (!_queen) {
        _queen = [CJPayBalanceVerifyManagerQueen new];
        [_queen bindManager:self];
    }
    return _queen;
}

- (void)onBindCardAndPayAction {
    [super onBindCardAndPayAction];
    CJPayBindCardSharedDataModel *model = [self.response buildBindCardCommonModel];
    model.cardBindSource = self.balanceVerifyType == CJPayBalanceVerifyTypeRecharge ? CJPayCardBindSourceTypeBalanceRecharge : CJPayCardBindSourceTypeBalanceWithdraw;
    if (model.cardBindSource == CJPayCardBindSourceTypeBalanceRecharge) {
        model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceRechargeBindCardAndPay;
    } else if (model.cardBindSource == CJPayCardBindSourceTypeBalanceWithdraw) {
        model.lynxBindCardBizScence = CJPayLynxBindCardBizScenceWithdrawBindCardAndPay;
    }
    model.jhMerchantId = self.response.merchant.intergratedMerchantId;
    model.jhAppId = self.response.merchant.jhAppId;
    model.completion = ^(CJPayBindCardResultModel * _Nonnull resModel) {
        if (resModel.result != CJPayBindCardResultSuccess) {
            return;
        }
        self.bindcardResultModel = resModel;
        [self submitConfimRequest:@{} fromVerifyItem:nil];
    };
    [CJ_OBJECT_WITH_PROTOCOL(CJPayCardManageModule) i_bindCardAndPay:model];
}

- (NSDictionary *)buildConfirmRequestParamsByCurPayChannel {
    NSMutableDictionary *dic = [[super buildConfirmRequestParamsByCurPayChannel] mutableCopy];
    [dic addEntriesFromDictionary:self.payContext.confirmRequestParams];
    return [dic copy];
}

- (void)confirmRequestSuccess:(CJPayOrderConfirmResponse *)response withChannelType:(CJPayChannelType)channelType {
    if (![response isSuccess]) {
        @CJStopLoading(self);
        if ([response.code hasPrefix:@"GW4009"]) {
            NSNumber *delayTime = @(0);
            if (response.code.length >= 6) {
                delayTime = @([[response.code substringFromIndex:6] intValue]);
            }
            [self sendEventTOVC:CJPayHomeVCEventFreezeConfirmBtn obj:delayTime];
            return;
        }
        
        if ([self.lastConfirmVerifyItem isKindOfClass:CJPayVerifyItemSignCard.class]) {
            [self sendEventTOVC:CJPayHomeVCEventSignAndPayFailed obj:response.msg];
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
        
        [CJMonitor trackService:@"wallet_rd_paydesk_confirm_failed"
                       category:@{@"code":CJString(response.code),
                                  @"msg":CJString(response.msg),
                                  @"desk_identify": self.balanceVerifyType == CJPayBalanceVerifyTypeRecharge ? @"余额充值收银台" : @"余额提现收银台"}
                          extra:@{}];
        return;
    }
    [super confirmRequestSuccess:response withChannelType:channelType];
}

@end
