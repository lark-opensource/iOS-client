//
//  CJPayBizDYPayVerifyManager.m
//  Pods
//
//  Created by wangxiaohong on 2022/10/18.
//

#import "CJPayBizDYPayVerifyManager.h"

#import "CJPayUIMacro.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayEnumUtil.h"
#import "CJPayOneKeyConfirmRequest.h"
#import "CJPayMetaSecManager.h"
#import "CJPayAlertUtil.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayHintInfo.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayToast.h"
#import "UIViewController+CJPay.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayBDCreateOrderResponse+BindCardModel.h"
#import "CJPaySettingsManager.h"

@implementation CJPayBizDYPayVerifyManager

- (BOOL)sendEventTOVC:(CJPayHomeVCEvent)event obj:(id)object {
    if (event == CJPayHomeVCEventNotifySufficient) {
        if ([self.homePageVC curSelectConfig].isCombinePay) {
            return [super sendEventTOVC:event obj:object];
        }
        
        if (self.isBindCardAndPay && [object isKindOfClass:CJPayOrderConfirmResponse.class]) {
            //新卡绑卡并支付余额不足拦截
            [CJToast toastText:CJString(((CJPayOrderConfirmResponse *)object).msg) inWindow:[self.homePageVC topVC].cj_window];
            return YES;
        }
    }
    return [super sendEventTOVC:event obj:object];
}

- (NSDictionary *)buildConfirmRequestParamsByCurPayChannel {
    NSMutableDictionary *dic = [[super buildConfirmRequestParamsByCurPayChannel] mutableCopy];
    
    CJPayDefaultChannelShowConfig *selectChannel = self.defaultConfig;
    if (selectChannel.isCombinePay) {
        if (selectChannel.combineType == BDPayChannelTypeIncomePay) {
            [dic cj_setObject:@"129" forKey:@"combine_type"];
        } else {
            [dic cj_setObject:@"3" forKey:@"combine_type"];
        }
    }
    if (selectChannel.type == BDPayChannelTypeCreditPay) {
        NSString *creditInstallment = CJString(self.homePageVC.createOrderResponse.payInfo.creditPayInstallment);
        if (self.homePageVC.createOrderResponse.payInfo.subPayTypeDisplayInfoList) {
            creditInstallment = Check_ValidString(selectChannel.payTypeData.curSelectCredit.installment) ? selectChannel.payTypeData.curSelectCredit.installment : @"1";
        }
        NSDictionary *creditItemDict = @{
            @"credit_pay_installment" : CJString(creditInstallment),
            @"decision_id" : CJString(self.homePageVC.createOrderResponse.payInfo.decisionId)
        };
        [dic cj_setObject:creditItemDict forKey:@"credit_item"];
    }
    return [dic copy];
}

- (BOOL)p_isReachLimitCode:(NSString *)code {
    return [code isEqualToString:@"CD005111"] ||
    [code isEqualToString:@"CD005112"] ||
    [code isEqualToString:@"CD005113"] ||
    [code isEqualToString:@"CD005114"];
}

- (NSDictionary *)otherExtsParamsForQueryOrder {
    NSString *issueCheckType = [self issueCheckType];
    NSString *realCheckType = [self.lastConfirmVerifyItem checkType];
    
    if ([issueCheckType isEqualToString:@"2"]
        && ![issueCheckType isEqualToString:realCheckType]
        && CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin)
        && [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBiometryNotAvailable]) {
        return @{@"verify_info": @{@"verify_change_type": @"downgrade"}};
    }
    return nil;
}

- (void)confirmRequestSuccess:(CJPayOrderConfirmResponse *)response withChannelType:(CJPayChannelType)channelType
{
    if ([response.code isEqualToString:@"CD005103"] ) {
        @CJStopLoading(self);
        [self sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
        [self sendEventTOVC:CJPayHomeVCEventRefreshTradeCreate obj:response];
        [CJPayAlertUtil singleAlertWithTitle:response.hintInfo.msg
                                 content:nil
                              buttonDesc:CJPayLocalizedStr(@"知道了")
                             actionBlock:nil useVC:self.homePageVC.topVC];
        return;
    }
    
    if ([@[@"CD005102",@"CD005104"] containsObject:CJString(response.code)] || [self p_isReachLimitCode:response.code]) {
        @CJStopLoading(self);
        [self sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
        [self sendEventTOVC:CJPayHomeVCEventPayLimit obj:response];
        return;
    }
    
    if ([response.code isEqualToString:@"CD005008"] ) {
        @CJStopLoading(self);
        [self sendEventTOVC:CJPayHomeVCEventPayMethodDisabled obj:response];
        return;
    }
    
    if ([response.code isEqualToString:@"CD005028"]) {
        @CJStopLoading(self);
        [self sendEventTOVC:CJPayHomeVCEventDiscountNotAvailable obj:response];
        return;
    }
    
    // 新验密页->选卡页进行绑卡，绑卡成功但支付失败时，退出当前验证流程回到聚合首页
    if (![response isSuccess] && self.isBindCardAndPay && self.response.payInfo.subPayTypeDisplayInfoList) {
        [self sendEventTOVC:CJPayHomeVCEventDismissAllAboveVCs obj:@(0)];
        [self exitBindCardStatus];
        return;
    }
    if (![response isSuccess]) {
        @CJStopLoading(self);
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
                                  @"desk_identify": @"聚合收银台",
                                  @"is_pay_newcard": self.isBindCardAndPay ? @"1" : @"0"}
                          extra:@{}];
        [self sendEventTOVC:CJPayHomeVCEventOccurUnHandleConfirmError obj:response];
        
        return;
    }
    
    if ([self.defaultConfig.payChannel isKindOfClass:CJPayChannelModel.class]) {
        [self submitQueryRequest];
    } else if (self.isBindCardAndPay) {
        [super confirmRequestSuccess:response withChannelType:channelType];
    } else {
        CJPayLogInfo(@"该支付渠道不能进行");
        [self sendEventTOVC:CJPayHomeVCEventShowState obj:@(CJPayStateTypeFailure)];
    }
}

#pragma mark - CJPayVerifyManagerPayNewCardProtocol

- (void)onBindCardAndPayAction {
    [super onBindCardAndPayAction];
    CJPayBindCardSharedDataModel *bindModel = [self.response buildBindCardCommonModel];
    UIViewController *topVC = [self.homePageVC topVC];
    bindModel.referVC = topVC;
    NSMutableDictionary *params = [self.trackParams mutableCopy];
    bindModel.trackerParams = [params copy];
    @CJWeakify(self)
    if (self.bindCardStartLoadingBlock) {
        self.bindCardStartLoadingBlock();
    } else {
        @CJStartLoading(self.homePageVC)
    }
    bindModel.dismissLoadingBlock = ^{
        @CJStrongify(self);
        if (self.bindCardStopLoadingBlock) {
            self.bindCardStopLoadingBlock();
        } else {
            @CJStopLoading(self.homePageVC)
        }
    };
    bindModel.bindCardInfo = @{
        @"bank_code" : CJString(self.homePageVC.curSelectConfig.frontBankCode),
        @"card_type" : CJString(self.homePageVC.curSelectConfig.cardType),
        @"card_add_ext" : CJString(self.homePageVC.curSelectConfig.cardAddExt)
    };
    
    bindModel.completion = ^(CJPayBindCardResultModel * _Nonnull resModel) {
        // 只有取消的时候，才需要动画
        @CJStrongify(self);
        switch (resModel.result) {
            case CJPayBindCardResultSuccess:{
                self.bindcardResultModel = resModel;
                [self submitConfimRequest:@{} fromVerifyItem:nil];
                break;
            }
            case CJPayBindCardResultCancel:
            case CJPayBindCardResultFail:
                // 新验密页从绑卡流程退出时，重置isBindCardAndPay = NO
                if (self.response.payInfo.subPayTypeDisplayInfoList) {
                    [self exitBindCardStatus];
                    return;
                }
                break;
            default:
                break;
        }
    };
    
    bindModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceIntegratedCashier;
    [CJ_OBJECT_WITH_PROTOCOL(CJPayCardManageModule) i_bindCardAndPay:bindModel];
}

@end
