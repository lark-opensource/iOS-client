//
//  CJPayECVerifyManager.m
//  Pods
//
//  Created by wangxiaohong on 2020/11/15.
//

#import "CJPayECVerifyManager.h"
#import "CJPayECVerifyManagerQueen.h"
#import "CJPayUIMacro.h"
#import "CJPayVerifyItemSignCard.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayECController.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayBindCardManager.h"
#import "CJPayDeskUtil.h"

@interface CJPayECVerifyManager()

@property (nonatomic, strong) CJPayECVerifyManagerQueen *queen;

@end

@implementation CJPayECVerifyManager

+ (instancetype)managerWith:(id<CJPayHomeVCProtocol>)homePageVC {
    NSDictionary *defaultVerifyItemsDic = @{
        @(CJPayVerifyTypeSignCard)          : @"CJPayECVerifyItemSignCard",
        @(CJPayVerifyTypeBioPayment)        : @"CJPayECVerifyItemBioPayment",
        @(CJPayVerifyTypePassword)          : @"CJPayECVerifyItemPassword",
        @(CJPayVerifyTypeSMS)               : @"CJPayECVerifyItemSMS",
        @(CJPayVerifyTypeUploadIDCard)      : @"CJPayECVerifyItemUploadIDCard",
        @(CJPayVerifyTypeAddPhoneNum)       : @"CJPayECVerifyItemAddPhoneNum",
        @(CJPayVerifyTypeIDCard)            : @"CJPayVerifyItemIDCard",
        @(CJPayVerifyTypeRealNameConflict)  : @"CJPayECVerifyItemRealNameConflict",
        @(CJPayVerifyTypeFaceRecog)         : @"CJPayVerifyItemRecogFace",
        @(CJPayVerifyTypeForgetPwdFaceRecog): @"CJPayVerifyItemForgetPwdRecogFace",
        @(CJPayVerifyTypeFaceRecogRetry)    : @"CJPayVerifyItemRecogFaceRetry",
        @(CJPayVerifyTypeSkipPwd)           : @"CJPayECVerifyItemSkipPwd",
        @(CJPayVerifyTypeSkip)              : @"CJPayVerifyItemSkip",
        @(CJPayVerifyTypeToken)             : @"CJPayVerifyItemToken"
    };
    return [self managerWith:homePageVC withVerifyItemConfig:defaultVerifyItemsDic];
}

- (CJPayBaseVerifyManagerQueen *)verifyManagerQueen {
    return self.queen;
}

- (CJPayECVerifyManagerQueen *)queen {
    if (!_queen) {
        _queen = [CJPayECVerifyManagerQueen new];
        [_queen bindManager:self];
    }
    return _queen;
}

- (NSDictionary *)buildConfirmRequestParamsByCurPayChannel {
    NSMutableDictionary *dic = [[super buildConfirmRequestParamsByCurPayChannel] mutableCopy];
    
    CJPayDefaultChannelShowConfig *selectChannel = self.defaultConfig;
    CJPayBDCreateOrderResponse *createResponse = self.payContext.orderResponse;
    
    if (selectChannel.type == BDPayChannelTypeCreditPay) {
        NSString *creditInstallment = CJString(createResponse.payInfo.creditPayInstallment);
        if (createResponse.payInfo.subPayTypeDisplayInfoList) {
            creditInstallment = Check_ValidString(selectChannel.payTypeData.curSelectCredit.installment) ? selectChannel.payTypeData.curSelectCredit.installment : @"1";
        }
        NSDictionary *creditItemDict = @{
            @"credit_pay_installment" : CJString(creditInstallment),
            @"decision_id" : CJString(createResponse.payInfo.decisionId)
        };
        [dic cj_setObject:creditItemDict forKey:@"credit_item"];
    } else if (selectChannel.type == BDPayChannelTypeAfterUsePay) {
        if ([dic cj_dictionaryValueForKey:@"exts"]) {
            NSMutableDictionary *extsDic = [[dic cj_dictionaryValueForKey:@"exts"] mutableCopy];
            [extsDic cj_setObject:@(self.payContext.orderResponse.userInfo.payAfterUseActive) forKey:@"pay_after_use_active"];
            [dic cj_setObject:extsDic forKey:@"exts"];
        } else {
            NSMutableDictionary *extsDic = [NSMutableDictionary new];
            [extsDic cj_setObject:@(self.payContext.orderResponse.userInfo.payAfterUseActive) forKey:@"pay_after_use_active"];
            [dic cj_setObject:extsDic forKey:@"exts"];
        }
    } else if (selectChannel.type == BDPayChannelTypeCombinePay) {
        [dic cj_setObject:CJString(self.payContext.orderResponse.payInfo.combineType)
                   forKey:@"combine_type"];
        if (![self.payContext.orderResponse.payInfo.primaryPayType isEqualToString:@"new_bank_card"]) {
            NSDictionary *cardItemDic = @{@"bank_card_id": CJString(self.payContext.orderResponse.payInfo.bankCardId)};
            [dic cj_setObject:cardItemDic
                       forKey:@"card_item"];
        }
    }
    
    if (selectChannel.isSecondPayCombinePay) {
        [dic cj_setObject:@"combinepay" forKey:@"pay_type"];
        [dic cj_setObject:@"3" forKey:@"combine_type"];
    }
    
    
    if (createResponse.payInfo.voucherNoList) {
        [dic cj_setObject:createResponse.payInfo.voucherNoList forKey:@"voucher_no_list"];
    }
    [dic addEntriesFromDictionary:self.payContext.confirmRequestParams];
    return [dic copy];
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

- (void)confirmRequestSuccess:(CJPayOrderConfirmResponse *)response withChannelType:(CJPayChannelType)channelType {
    
    if (![response isSuccess]) {
        @CJStopLoading(self);
        
        if ([response.code isEqualToString:@"CD005008"]) {
            [self sendEventTOVC:CJPayHomeVCEventPayMethodDisabled obj:response];
            return;
        }
        
        if ([response.code isEqualToString:@"CD005028"]) {
            [self sendEventTOVC:CJPayHomeVCEventDiscountNotAvailable obj:response];
            return;
        }
        
        NSString *msg = response.msg;
        if (!Check_ValidString(msg)) {
            msg = CJPayLocalizedStr(@"支付失败，请重试");
        }
        
        if (!response) {
            msg = CJPayNoNetworkMessage;
        }
        
        if ([self.lastConfirmVerifyItem isKindOfClass:CJPayVerifyItemSignCard.class]) {
            [self sendEventTOVC:CJPayHomeVCEventSignAndPayFailed obj:msg];
            return;
        }
        
        if ([self p_isHitBizShowTipsErrorWithConfirmResponse:response] && response.iconTips) {
            [self sendEventTOVC:CJPayHomeVCEventClosePayDesk
                                          obj:@(CJPayHomeVCCloseActionSourceFromClosePayDeskShowBizError)];

            return;
        }
    
        [CJToast toastText:msg inWindow:[self.homePageVC topVC].cj_window];
        
        if (self.isBindCardAndPay && ![self p_isInCJPay]) {
            [self sendEventTOVC:CJPayHomeVCEventClosePayDesk obj:@(CJPayHomeVCCloseActionSourceFromRequestError)];
            return;
        }
     
        // 顶部不是财经自己的页面，confirm请求失败直接回调业务方
        if ([self.homePageVC isKindOfClass:[CJPayECController class]]) {
            CJPayECController *homeController = (CJPayECController *)self.homePageVC;
            if (![homeController topVCIsCJPay]) {
                [self sendEventTOVC:CJPayHomeVCEventClosePayDesk
                                obj:@(CJPayHomeVCCloseActionSourceFromRequestError)];
                return;
            }
        }
        // 新验密页->选卡页进行绑卡，绑卡成功但支付失败时，关闭支付流程进入继续支付页
        if (self.isBindCardAndPay && self.response.payInfo.subPayTypeDisplayInfoList) {
            [self sendEventTOVC:CJPayHomeVCEventClosePayDesk
                            obj:@(CJPayHomeVCCloseActionSourceFromBindAndPayFail)];
            return;
        }
        [CJMonitor trackService:@"wallet_rd_paydesk_confirm_failed" category:@{@"code":CJString(response.code), @"msg":CJString(response.msg), @"desk_identify": @"电商收银台"} extra:@{}];
        return;
    }
    
    [super confirmRequestSuccess:response withChannelType:channelType];
}

- (NSDictionary *)getPerformanceInfo {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict cj_setObject:@(self.queen.beforeConfirmRequestTimestamp) forKey:@"C_ORDER_TTPAY_CONFIRM_PAY_START"];
    [dict cj_setObject:@(self.queen.afterConfirmRequestTimestamp) forKey:@"C_ORDER_TTPAY_CHECK_PAY_START"];
    [dict cj_setObject:@(self.queen.afterQueryResultTimestamp) forKey:@"C_ORDER_TTPAY_END"];

    return [dict copy];
}

- (BOOL)p_isInCJPay {
    UIViewController *topVC = [UIViewController cj_topViewController];
    return [topVC isKindOfClass:[CJPayBaseViewController class]];
}

- (BOOL)p_isHitBizShowTipsErrorWithConfirmResponse:(CJPayOrderConfirmResponse *)orderConfirmResponse {
    NSArray *bizErrorCodes = @[@"CD005102",
                               @"CD005111",
                               @"CD005112",
                               @"CD005113",
                               @"CD005114",
                               @"CD005103"];
    return [bizErrorCodes containsObject:CJString(orderConfirmResponse.code)];
}

#pragma mark - CJPayVerifyManagerPayNewCardProtocol

- (void)onBindCardAndPayAction {
    [super onBindCardAndPayAction];
    [self p_bindCardAction];
}

- (void)p_bindCardAction {
    CJPayBindCardSharedDataModel *bindModel = [self.response buildBindCardCommonModel];
    bindModel.isEcommerceAddBankCardAndPay = YES;
    bindModel.bindCardInfo = [self.payContext.extParams cj_dictionaryValueForKey:@"bind_card_info"];
    bindModel.frontIndependentBindCardSource = [[self.payContext.extParams cj_dictionaryValueForKey:@"track_info"] cj_stringValueForKey:@"source"];
    bindModel.trackerParams = [self.payContext.extParams cj_dictionaryValueForKey:@"track_info"];
    bindModel.trackInfo = bindModel.trackerParams;
    if (self.bindCardStartLoadingBlock) {
        self.bindCardStartLoadingBlock();
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
    }
    
    @CJWeakify(self)
    bindModel.dismissLoadingBlock = ^{
        if (weak_self.bindCardStopLoadingBlock) {
            weak_self.bindCardStopLoadingBlock();
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
    };
    
    bindModel.completion = ^(CJPayBindCardResultModel * _Nonnull resModel) {
        @CJStrongify(self)
        switch (resModel.result) {
            case CJPayBindCardResultSuccess:
                self.bindcardResultModel = resModel;
                [[CJPayLoadingManager defaultService] stopLoading];
                [self submitConfimRequest];
                break;
            case CJPayBindCardResultFail:
                [self p_closeBindCardWithObject:@(CJPayHomeVCCloseActionSourceFromBindAndPayFail)];
                break;
            case CJPayBindCardResultCancel:
                [self p_closeBindCardWithObject:@(CJPayHomeVCCloseActionSourceFromBack)];
                break;
            default:
                [self p_closeBindCardWithObject:@(CJPayHomeVCCloseActionSourceFromBindAndPayFail)];
                break;
        }
    };
    
    CJPayCashierScene cashierScene;
    if ([self.homePageVC isKindOfClass:CJPayECController.class]) {
        cashierScene = ((CJPayECController *)self.homePageVC).cashierScene;
    }
    if (cashierScene == CJPayCashierSceneEcommerce) {
        [[CJPayLoadingManager defaultService] stopLoading];
        bindModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceECCashier;
    } else if (cashierScene == CJPayCashierScenePreStandard) {
        bindModel.lynxBindCardBizScence = CJPayLynxBindCardBizScencePreStandardPay;
    }
    
    [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:bindModel];
}

- (void)submitConfimRequest {
    NSMutableDictionary *extraParamDic = [NSMutableDictionary new];
    if (self.defaultConfig.type == BDPayChannelTypeAfterUsePay) {
        NSMutableDictionary *payAfterUseInfoDic = [NSMutableDictionary new];
        [payAfterUseInfoDic cj_setObject:@(YES)
                                  forKey:@"is_pay_after_use"];
        [payAfterUseInfoDic cj_setObject:@(self.payContext.orderResponse.userInfo.payAfterUseActive)
                                  forKey:@"pay_after_use_active"];
        [extraParamDic cj_setObject:payAfterUseInfoDic forKey:@"pay_after_use_info"];
    }
    
    [super submitConfimRequest:extraParamDic fromVerifyItem:nil];
}

- (void)p_closeBindCardWithObject:(id)object {
    if (self.isNotSufficient) {
        return;
    }
    // 新验密页从绑卡流程退出时，重置isBindCardAndPay = NO
    if (self.response.payInfo.subPayTypeDisplayInfoList) {
        [self exitBindCardStatus];
        return;
    }
    [self sendEventTOVC:CJPayHomeVCEventClosePayDesk obj:object];
}

@end
