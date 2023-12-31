//
//  CJPayDouPayProcessVerifyManager.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/5/31.
//

#import "CJPayDouPayProcessVerifyManager.h"
#import "CJPayDouPayProcessVerifyManagerQueen.h"
#import "CJPayUIMacro.h"
#import "CJPayVerifyItemSignCard.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayBindCardSharedDataModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPaySettingsManager.h"
#import "CJPayBindCardManager.h"
#import "CJPayDeskUtil.h"
#import "CJPayOutDisplayInfoModel.h"
#import "CJPaySkipPwdConfirmViewController.h"
#import "CJPaySkipPwdConfirmHalfPageViewController.h"
#import "CJPaySkipPwdConfirmModel.h"
#import "CJPayUIMacro.h"

@interface CJPayDouPayProcessVerifyManager()

@property (nonatomic, strong) CJPayDouPayProcessVerifyManagerQueen *queen;
@property (nonatomic, weak) CJPayPopUpBaseViewController<CJPayBaseLoadingProtocol> *skipPwdVC;
@property(nonatomic, weak) CJPaySkipPwdConfirmHalfPageViewController<CJPayBaseLoadingProtocol> *skipPwdHalfPageVC;

@end


@implementation CJPayDouPayProcessVerifyManager

+ (instancetype)managerWith:(id<CJPayHomeVCProtocol>)homePageVC {
    NSDictionary *defaultVerifyItemsDic = @{
        @(CJPayVerifyTypeSignCard)          : @"CJPayVerifyItemSignCard",
        @(CJPayVerifyTypeBioPayment)        : @"CJPayVerifyItemStandardBioPayment",
        @(CJPayVerifyTypePassword)          : @"CJPayVerifyItemPassword",
        @(CJPayVerifyTypeSMS)               : @"CJPayVerifyItemSMS",
        @(CJPayVerifyTypeUploadIDCard)      : @"CJPayVerifyItemUploadIDCard",
        @(CJPayVerifyTypeAddPhoneNum)       : @"CJPayVerifyItemAddPhoneNum",
        @(CJPayVerifyTypeIDCard)            : @"CJPayVerifyItemIDCard",
        @(CJPayVerifyTypeRealNameConflict)  : @"CJPayVerifyItemRealNameConflict",
        @(CJPayVerifyTypeFaceRecog)         : @"CJPayVerifyItemStandardRecogFace",
        @(CJPayVerifyTypeForgetPwdFaceRecog): @"CJPayVerifyItemStandardForgetPwdRecogFace",
        @(CJPayVerifyTypeFaceRecogRetry)    : @"CJPayVerifyItemStandardRecogFaceRetry",
        @(CJPayVerifyTypeSkipPwd)           : @"CJPayVerifyItemSkipPwd",
        @(CJPayVerifyTypeSkip)              : @"CJPayVerifyItemSkip",
        @(CJPayVerifyTypeToken)             : @"CJPayVerifyItemToken",
        @(CJPayVerifyTypeAdditionalSignCard): @"CJPayVerifyItemAdditionalSignCard"
    };
    return [self managerWith:homePageVC withVerifyItemConfig:defaultVerifyItemsDic];
}

- (CJPayBaseVerifyManagerQueen *)verifyManagerQueen {
    return self.queen;
}

- (NSDictionary *)buildConfirmRequestParamsByCurPayChannel {
    NSMutableDictionary *dic = [[super buildConfirmRequestParamsByCurPayChannel] mutableCopy];
    
    BOOL isSignAndPay = [[self.bizParams cj_stringValueForKey:@"pay_type"] isEqualToString:@"deduct"];// 这里是签约并支付的 特殊逻辑， 签约并支付传回pay_type是deduct的时候 trade_confirm传的就是deduct
    BOOL isDeductFront = [self.response.payTypeInfo.outDisplayInfo isDeductPayMode];// 走「签约前置」轮扣的时候要把pay_type 改为轮扣样式
    if (isSignAndPay || isDeductFront) {
        [dic cj_setObject:@"deduct" forKey:@"pay_type"];
    }
    
    CJPayDefaultChannelShowConfig *selectChannel = self.defaultConfig;
    CJPayBDCreateOrderResponse *createResponse = self.response;
    
    if (selectChannel.type == BDPayChannelTypeCreditPay) {
        NSDictionary *creditItemDict = @{
            @"credit_pay_installment" : CJString(selectChannel.payTypeData.curSelectCredit.installment),
            @"decision_id" : CJString(selectChannel.decisionId)
        };
        [dic cj_setObject:creditItemDict forKey:@"credit_item"];
    } else if (selectChannel.type == BDPayChannelTypeAfterUsePay) {
        if ([dic cj_dictionaryValueForKey:@"exts"]) {
            NSMutableDictionary *extsDic = [[dic cj_dictionaryValueForKey:@"exts"] mutableCopy];
            [extsDic cj_setObject:@(self.homePageVC.createOrderResponse.userInfo.payAfterUseActive) forKey:@"pay_after_use_active"];
            [dic cj_setObject:extsDic forKey:@"exts"];
        } else {
            NSMutableDictionary *extsDic = [NSMutableDictionary new];
            [extsDic cj_setObject:@(self.homePageVC.createOrderResponse.userInfo.payAfterUseActive) forKey:@"pay_after_use_active"];
            [dic cj_setObject:extsDic forKey:@"exts"];
        }
    }
    
    if (createResponse.payInfo.voucherNoList) {
        [dic cj_setObject:createResponse.payInfo.voucherNoList forKey:@"voucher_no_list"];
    }
    
    // 外部商户唤端需重设method字段
    if (self.isPaymentForOuterApp) {
        if (self.isBindCardAndPay) {
            [dic cj_setObject:@"cashdesk.out.pay.pay_new_card" forKey:@"method"];
        } else {
            [dic cj_setObject:@"cashdesk.out.pay.confirm" forKey:@"method"];
        }
    }
    
    return [dic copy];
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
    
        [CJToast toastText:msg inWindow:[self.homePageVC topVC].cj_window];
        
        if (self.isBindCardAndPay) {
            [self sendEventTOVC:CJPayHomeVCEventBindCardSuccessPayFail obj:response];
            [self exitBindCardStatus];
            return;
        }
        
        [self sendEventTOVC:CJPayHomeVCEventConfirmRequestError obj:response];

        [CJMonitor trackService:@"wallet_rd_paydesk_confirm_failed" category:@{@"code":CJString(response.code), @"msg":CJString(response.msg), @"desk_identify": @"电商收银台"} extra:@{}];
        [CJKeyboard recoverFirstResponder];
        return;
    }
    
    [super confirmRequestSuccess:response withChannelType:channelType];
}

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
    if (self.isPaymentForOuterApp) {
        [exts cj_setObject:@"cashdesk.out.pay.query" forKey:@"method"];
        [exts cj_setObject:@(YES) forKey:@"pay_outer_merchant"];
    }
    return [exts copy];
}

- (void)onBindCardAndPayAction {
    [super onBindCardAndPayAction];
    [self p_bindCardAction];
}

- (NSDictionary *)getPerformanceInfo {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict cj_setObject:@(self.queen.beforeConfirmRequestTimestamp) forKey:@"C_ORDER_TTPAY_CONFIRM_PAY_START"];
    [dict cj_setObject:@(self.queen.afterConfirmRequestTimestamp) forKey:@"C_ORDER_TTPAY_CHECK_PAY_START"];
    [dict cj_setObject:@(self.queen.afterQueryResultTimestamp) forKey:@"C_ORDER_TTPAY_END"];

    return [dict copy];
}

- (void)p_bindCardAction {
    CJPayBindCardSharedDataModel *bindModel = [self.response buildBindCardCommonModel];
    bindModel.isEcommerceAddBankCardAndPay = YES; //标准化流程逻辑对齐电商，删除老架构代码时可以一并删除此属性
    bindModel.bindCardInfo = [self.extParams cj_dictionaryValueForKey:@"bind_card_info"];
    NSDictionary *trackInfoDict = [self.extParams cj_dictionaryValueForKey:@"track_info"];
    bindModel.frontIndependentBindCardSource = [trackInfoDict cj_stringValueForKey:@"source"];
    bindModel.trackerParams = trackInfoDict;
    bindModel.trackInfo = bindModel.trackerParams;
    if (self.bindCardStartLoadingBlock) {
        self.bindCardStartLoadingBlock();
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
    }
    
    @CJWeakify(self)
    bindModel.dismissLoadingBlock = ^{
        @CJStrongify(self)
        if (self.bindCardStopLoadingBlock) {
            self.bindCardStopLoadingBlock();
        } else {
            [[CJPayLoadingManager defaultService] stopLoading];
        }
    };
    
    bindModel.completion = ^(CJPayBindCardResultModel * _Nonnull resModel) {
        @CJStrongify(self)
        [self.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_main_process" params:@{
            @"process_name" : @"绑卡完成",
            @"process_source" : @"标准化流程",
            @"ext_params" : @{
                @"bindcard_result" : @(resModel.result),
                @"biz_scence" : @(self.lynxBindCardBizScence),
                @"secondard_confirm_info" : CJString([[self.response.secondaryConfirmInfo toDictionary] cj_toStr])
            }
        }];
        switch (resModel.result) {
            case CJPayBindCardResultSuccess:
                self.bindcardResultModel = resModel;
                [[CJPayLoadingManager defaultService] stopLoading];
                if (self.response.secondaryConfirmInfo) {
                    [self p_secondaryConfirm];
                } else {
                    [self submitConfimRequest:@{} fromVerifyItem:nil];
                }
                break;
            case CJPayBindCardResultFail:
                [self p_closeBindCardWithObject:CJPayHomeVCCloseActionSourceFromBindAndPayFail];
                break;
            case CJPayBindCardResultCancel:
                [self p_closeBindCardWithObject:CJPayHomeVCCloseActionSourceFromBack];
                break;
            default:
                [self p_closeBindCardWithObject:CJPayHomeVCCloseActionSourceFromBindAndPayFail];
                break;
        }
    };
    [[CJPayLoadingManager defaultService] stopLoading];
    bindModel.lynxBindCardBizScence = self.lynxBindCardBizScence;
    [[CJPayBindCardManager sharedInstance] bindCardWithCommonModel:bindModel];
}

- (void)p_secondaryConfirm {
    if ([self.response.secondaryConfirmInfo.style isEqualToString:@"bindcard_popup"]) {
        CJPaySkipPwdConfirmModel *model = [self p_confirmModel:self.response];
        CJPaySkipPwdConfirmViewController *skipPwdConfirmVC = [[CJPaySkipPwdConfirmViewController alloc] initWithModel:model];
        self.skipPwdVC = skipPwdConfirmVC;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [self.homePageVC push: skipPwdConfirmVC animated:YES];
            [CJTracker event:@"wallet_cashier_bankcard_tip_imp" params:@{}];
        });
    } else if ([self.response.secondaryConfirmInfo.style isEqualToString:@"bindcard_halfpage"]) {
        CJPaySkipPwdConfirmModel *model = [self p_confirmModel:self.response];
        CJPaySkipPwdConfirmHalfPageViewController *skipPwdConfirmVC = [[CJPaySkipPwdConfirmHalfPageViewController alloc] initWithModel:model];
        skipPwdConfirmVC.forceOriginPresentAnimation = YES;
        skipPwdConfirmVC.animationType = HalfVCEntranceTypeFromBottom;
        [skipPwdConfirmVC showMask:YES];
        
        self.skipPwdHalfPageVC = skipPwdConfirmVC;
        skipPwdConfirmVC.animationType = HalfVCEntranceTypeFromBottom;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(500 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [self.homePageVC push: skipPwdConfirmVC animated:YES];
            [CJTracker event:@"wallet_cashier_bankcard_tip_imp" params:@{}];
        });
    }
}

- (CJPaySkipPwdConfirmModel *)p_confirmModel:(CJPayBDCreateOrderResponse *)response {
    CJPaySkipPwdConfirmModel *model = [CJPaySkipPwdConfirmModel new];
    model.createOrderResponse = self.response;
    model.verifyManager = self;
    model.confirmInfo = self.response.secondaryConfirmInfo;
    
    @CJWeakify(self)
    model.confirmBlock = ^{
        @CJStrongify(self)
        [CJTracker event:@"wallet_cashier_bankcard_tip_click" params:@{@"button_name":@"1"}];
        if (self.skipPwdHalfPageVC) {
            [self.skipPwdHalfPageVC closeWithAnimation:YES comletion:^(BOOL isFinish) {
                @CJStrongify(self)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self submitConfimRequest:@{} fromVerifyItem:nil];
                });
            }];
            return;
        }
        
        [self.skipPwdVC dismissSelfWithCompletionBlock:^{
            @CJStrongify(self)
            [self submitConfimRequest:@{} fromVerifyItem:nil];
        }];
    };
    
    model.backCompletionBlock = ^{
        @CJStrongify(self)
        [CJTracker event:@"wallet_cashier_bankcard_tip_click" params:@{@"button_name":@"0"}];
        if (self.skipPwdHalfPageVC) {
            [self.skipPwdHalfPageVC closeWithAnimation:YES comletion:^(BOOL isFinish) {
                @CJStrongify(self)
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self p_closeBindCardWithObject:@(CJPayHomeVCCloseActionSourceFromBack)];
                });
            }];
            return;
        }
        
        [self.skipPwdVC dismissSelfWithCompletionBlock:^{
            @CJStrongify(self)
            [self p_closeBindCardWithObject:@(CJPayHomeVCCloseActionSourceFromBack)];
        }];
    };
    
    return model;
}

- (void)p_closeBindCardWithObject:(CJPayHomeVCCloseActionSource)source {
    //从绑卡流程退出时，重置isBindCardAndPay = NO
    [self exitBindCardStatus];
    [self sendEventTOVC:CJPayHomeVCEventBindCardFailed obj:@(source)];
}

#pragma mark - Getter
- (CJPayDouPayProcessVerifyManagerQueen *)queen {
    if (!_queen) {
        _queen = [CJPayDouPayProcessVerifyManagerQueen new];
        [_queen bindManager:self];
    }
    return _queen;
}


@end
