//
//  CJPayDyPayVerifyManager.m
//  Pods
//
//  Created by 利国卿 on 2022/9/19.
//

#import "CJPayDyPayVerifyManager.h"

#import "CJPayUIMacro.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPayDyPayController.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayToast.h"
#import "CJPayFrontCashierResultModel.h"

@implementation CJPayDyPayVerifyManager

+ (instancetype)managerWith:(id<CJPayHomeVCProtocol>)homePageVC {
    NSDictionary *defaultVerifyItemsDic = @{
        @(CJPayVerifyTypeSignCard)          : @"CJPayVerifyItemSignCard",
        @(CJPayVerifyTypeBioPayment)        : @"CJPayVerifyItemBioPayment",
        @(CJPayVerifyTypePassword)          : @"CJPayDyPayVerifyItemPassword",
        @(CJPayVerifyTypeSMS)               : @"CJPayVerifyItemSMS",
        @(CJPayVerifyTypeUploadIDCard)      : @"CJPayVerifyItemUploadIDCard",
        @(CJPayVerifyTypeAddPhoneNum)       : @"CJPayVerifyItemAddPhoneNum",
        @(CJPayVerifyTypeIDCard)            : @"CJPayVerifyItemIDCard",
        @(CJPayVerifyTypeRealNameConflict)  : @"CJPayVerifyItemRealNameConflict",
        @(CJPayVerifyTypeFaceRecog)         : @"CJPayVerifyItemRecogFace",
        @(CJPayVerifyTypeForgetPwdFaceRecog): @"CJPayVerifyItemForgetPwdRecogFace",
        @(CJPayVerifyTypeFaceRecogRetry)    : @"CJPayVerifyItemRecogFaceRetry",
        @(CJPayVerifyTypeSkipPwd)           : @"CJPayVerifyItemSkipPwd",
        @(CJPayVerifyTypeSkip)              : @"CJPayVerifyItemSkip"
    };
    return [self managerWith:homePageVC withVerifyItemConfig:defaultVerifyItemsDic];
}

- (NSDictionary *)buildConfirmRequestParamsByCurPayChannel {
    NSMutableDictionary *dict = [[super buildConfirmRequestParamsByCurPayChannel] mutableCopy];
    
    if ([[self.bizParams cj_stringValueForKey:@"pay_type"] isEqualToString:@"deduct"]) {
        [dict cj_setObject:@"deduct" forKey:@"pay_type"];
    }
    
    NSDictionary *deductParams = [self.bizParams cj_dictionaryValueForKey:@"deduct_params"];
    if (Check_ValidDictionary(deductParams)) {
        [dict cj_setObject:deductParams forKey:@"deduct_params"];
    }

    CJPayDefaultChannelShowConfig *selectChannel = self.defaultConfig;
    if (selectChannel.type == BDPayChannelTypeCreditPay && [self.homePageVC isKindOfClass:CJPayDyPayController.class]) {
        
        CJPayDyPayController *homeVC = (CJPayDyPayController *)self.homePageVC;
        NSDictionary *creditItemDict = @{
            @"credit_pay_installment" : CJString(homeVC.creditPayInstallment),
            @"decision_id" : CJString(selectChannel.decisionId)
        };
        [dict cj_setObject:creditItemDict forKey:@"credit_item"];
    }
    
    if (!self.isPayAgainRecommend) {
        return [dict copy];
    }
    NSDictionary *processInfoParams = [self.confirmResponse.processInfo toDictionary];
    [dict cj_setObject:processInfoParams forKey:@"process_info"];
    return [dict copy];
}

- (CJPayDefaultChannelShowConfig *)defaultConfig {
    if (self.isBindCardAndPay && self.bindcardConfig) {
        return self.bindcardConfig;
    }
    return [super defaultConfig];
}

// 点击确认按钮，发起支付的网络请求
- (void)submitConfimRequest:(NSDictionary *)extraParams fromVerifyItem:(CJPayVerifyItem *)verifyItem {
    
    NSMutableDictionary *params = [extraParams mutableCopy];
    // 外部商户唤端需重设method字段
    if (self.isPayOuterMerchant) {
        if (self.isBindCardAndPay) {
            [params cj_setObject:@"cashdesk.out.pay.pay_new_card" forKey:@"method"];
        } else {
            [params cj_setObject:@"cashdesk.out.pay.confirm" forKey:@"method"];
        }
    }
    [super submitConfimRequest:params fromVerifyItem:verifyItem];
}

// 查单请求额外参数
- (NSDictionary *)otherExtsParamsForQueryOrder {
    NSMutableDictionary *exts = [NSMutableDictionary new];
    
    NSString *issueCheckType = [self issueCheckType];
    NSString *realCheckType = [self.lastConfirmVerifyItem checkType];
    if ([issueCheckType isEqualToString:@"2"]
        && ![issueCheckType isEqualToString:realCheckType]
        && [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) isBiometryNotAvailable]) {
        [exts cj_setObject:@{@"verify_change_type": @"downgrade"} forKey:@"verify_info"];
    }
    
    // 外部商户唤端需重设method字段
    if (self.isPayOuterMerchant) {
        [exts cj_setObject:@"cashdesk.out.pay.query" forKey:@"method"];
        [exts cj_setObject:@(YES) forKey:@"pay_outer_merchant"];
    }
    return [exts copy];
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
            [self exitBindCardStatus];
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

#pragma mark - CJPayDyPayNewCardProtocol
- (void)onBindCardAndPayAction {
    [super onBindCardAndPayAction];
    
    CJPayBindCardSharedDataModel *bindModel = [self.response buildBindCardCommonModel];
    bindModel.referVC = [self.homePageVC topVC];
    @CJWeakify(self)
    if (self.bindCardStartLoadingBlock) {
        self.bindCardStartLoadingBlock();
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    }
    
    bindModel.dismissLoadingBlock = ^{
        if (weak_self.bindCardStopLoadingBlock) {
            weak_self.bindCardStopLoadingBlock();
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
    };
    
    bindModel.bindCardInfo = @{
        @"bank_code" : CJString(self.bindcardConfig.frontBankCode),
        @"card_type" : CJString(self.bindcardConfig.cardType),
        @"card_add_ext" : CJString(self.bindcardConfig.cardAddExt)
    };
    
    bindModel.completion = ^(CJPayBindCardResultModel * _Nonnull resModel) {
        @CJStrongify(self);
        switch (resModel.result) {
            case CJPayBindCardResultSuccess: {
                self.bindcardResultModel = resModel;
                [self submitConfimRequest:@{} fromVerifyItem:nil];
                break;
            }
            case CJPayBindCardResultCancel:
            default:
                [self exitBindCardStatus];
                break;
        }
    };
    bindModel.lynxBindCardBizScence = CJPayLynxBindCardBizScenceOuterDypay;
    if ([self.payContext.extParams cj_dictionaryValueForKey:@"bind_card_info"]) {
        bindModel.bindCardInfo = [self.payContext.extParams cj_dictionaryValueForKey:@"bind_card_info"];
    }
    [CJ_OBJECT_WITH_PROTOCOL(CJPayCardManageModule) i_bindCardAndPay:bindModel];
}

@end
