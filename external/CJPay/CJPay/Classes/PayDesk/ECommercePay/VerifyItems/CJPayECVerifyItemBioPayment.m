//
//  CJPayECVerifyItemBioPayment.m
//  Pods
//
//  Created by 王新华 on 2020/11/25.
//

#import "CJPayECVerifyItemBioPayment.h"
#import "CJPayBioConfirmViewController.h"
#import "CJPayBioHeader.h"
#import "CJPayStyleButton.h"
#import "CJPayCommonSafeHeader.h"
#import "CJPayEnumUtil.h"
#import "CJPayECController.h"
#import "CJPayRetainUtil.h"
#import "UIViewController+CJPay.h"
#import "CJPayECVerifyManager.h"
#import "CJPayPayAgainChoosePayMethodViewController.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayRetainInfoModel.h"
#import "CJPayAlertUtil.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayKVContext.h"
#import "CJPayMetaSecManager.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPaySettingsManager.h"
#import "CJPayRetainInfoV2Config.h"
#import "CJPayUIMacro.h"

@interface CJPayECVerifyItemBioPayment()

@property (nonatomic, weak) CJPayBioConfirmViewController *bioHomeVC;

@end

@implementation CJPayECVerifyItemBioPayment

// MARK: - override

- (void)bioPayWithResponse:(CJPayBDCreateOrderResponse *)response
                     model:(CJPayBioSafeModel *)model
           localizedReason:(NSString *)localizedReason
         isSkipPwdSelected:(BOOL)isSkipPwdSelected
                completion:(void (^)(BOOL isUserCancel))completion {
    if (![self.manager isKindOfClass:CJPayECVerifyManager.class]) {
        return;
    }

    CJPayECVerifyManager *verifyManager = (CJPayECVerifyManager *)self.manager;

    if ([self p_isShowBioConfirmVC:verifyManager response:response]) {
        [self p_pullUpBioVCWithResponse:response
                                  model:model
                        localizedReason:localizedReason];
    } else {
        if (!verifyManager.isNotSufficient) {
            [self setConfirmButtonEnableStatus:NO];
        }

        [self p_superBioPayWithResponse:response
                                  model:model
                        localizedReason:localizedReason
                      isSkipPwdSelected:isSkipPwdSelected
                        isNotSufficient:verifyManager.isNotSufficient
                             completion:completion];
    }
}

- (void)setConfirmButtonEnableStatus:(BOOL)isEnable {
    [self.bioHomeVC setConfirmButtonEnableStatus:isEnable];
}

#pragma mark - Private Method

- (void)p_pullUpBioVCWithResponse:(CJPayBDCreateOrderResponse *)response
                            model:(CJPayBioSafeModel *)model
                  localizedReason:(NSString *)localizedReason {
    CJPayBioConfirmViewController *bioVC = [CJPayBioConfirmViewController new];
    bioVC.model = self.manager.response;
    
    [self event:@"wallet_fingerprint_verify_pay_page_imp" params:[self p_buildImpTrackerParams:response]];
    
    @CJWeakify(self)
    bioVC.passCodePayBlock = ^{ //使用密码支付
        @CJStrongify(self)
        NSDictionary * params = [self p_buildClickTrackerParams:response type:CJPayClickButtonUsePWD];
        [self event:@"wallet_fingerprint_verify_pay_confirm_click" params:params];
        CJPayEvent *event = [self buildEventSwitchToPasswordWithReason:nil isActive:YES];
        [self verifyTypeSwitchToPassCode:response event:event];
    };
    
    bioVC.confirmPayBlock = ^(BOOL isSkipPwdSelected) {
        @CJStrongify(self)
        [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeConfirmPay];
        NSDictionary * params = [self p_buildClickTrackerParams:response type:CJPayClickButtonConfirm];
        [self event:@"wallet_fingerprint_verify_pay_confirm_click" params:params];
        [self setConfirmButtonEnableStatus:NO];
        [super bioPayWithResponse:response
                            model:model
                  localizedReason:localizedReason
                isSkipPwdSelected:isSkipPwdSelected
                       completion:nil];
    };
    
    bioVC.trackerBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull params) {
        @CJStrongify(self)
        [self event:event params:params];
    };
    
    if ([self.manager.homePageVC isKindOfClass:CJPayECController.class]) {
        bioVC.cjBackBlock = ^{
            @CJStrongify(self)
            NSDictionary * params = [self p_buildClickTrackerParams:response type:CJPayClickButtonCancel];
            [self event:@"wallet_fingerprint_verify_pay_confirm_click" params:params];
            [self p_handleCloseActionWithRedoBlock:nil];
        };
    }
    
    [self.manager.homePageVC push:bioVC animated:YES];
    self.bioHomeVC = bioVC;
}

- (void)p_superBioPayWithResponse:(CJPayBDCreateOrderResponse *)response
                            model:(CJPayBioSafeModel *)model
                  localizedReason:(NSString *)localizedReason
                isSkipPwdSelected:(BOOL)isSkipPwdSelected
                  isNotSufficient:(BOOL)isNotSufficient
                       completion:(void (^)(BOOL isUserCancel))completion {
    @CJWeakify(self)
    [super bioPayWithResponse:response
                        model:model
              localizedReason:localizedReason
            isSkipPwdSelected:isSkipPwdSelected
                   completion:^(BOOL isUserCancel) {
        @CJStrongify(self)
        if (!isUserCancel || isNotSufficient) {
            return;
        }
        
        if (response.skipBioConfirmPage || [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger) {
            @CJWeakify(self)
            [self p_handleCloseActionWithRedoBlock:^{
                @CJStrongify(self)
                [self p_superBioPayWithResponse:response
                                          model:model
                                localizedReason:localizedReason
                              isSkipPwdSelected:isSkipPwdSelected
                                isNotSufficient:isNotSufficient
                                     completion:completion];
                
            }];
        } else if (!self.manager.isSkipPWDForbiddenOpt) {
            [self p_pullUpBioVCWithResponse:response
                                      model:model
                            localizedReason:localizedReason];
        }
    }];

}


- (void)p_handleCloseActionWithRedoBlock:(void (^)(void))redoBlock {
    if (![self p_shouldShowRetainVCWithRedoBlock:redoBlock]) {
        [self p_closePayDesk];
    }
}

- (BOOL)p_lynxRetain:(CJPayRetainUtilModel *)retainUtilModel sourceVC:(UIViewController *)sourceVC redoBlock:(void (^)(void))redoBlock {
    retainUtilModel.retainInfoV2Config.fromScene = @"bio_verify";
    @CJWeakify(self)
    retainUtilModel.lynxRetainActionBlock = ^(CJPayLynxRetainEventType eventType, NSDictionary * _Nonnull data) {
        @CJStrongify(self)
        switch (eventType) {
            case CJPayLynxRetainEventTypeOnConfirm:
                CJ_CALL_BLOCK(redoBlock);
                break;
            case CJPayLynxRetainEventTypeOnCancelAndLeave:
                [self p_closePayDesk];
                break;
            default:
                break;
        }
    };
    
    return [CJPayRetainUtil couldShowLynxRetainVCWithSourceVC:[UIViewController cj_topViewController] retainUtilModel:retainUtilModel completion:nil];
}

- (BOOL)p_shouldShowRetainVCWithRedoBlock:(void (^)(void))redoBlock {
    CJPayRetainUtilModel *retainUtilModel = [self buildRetainUtilModel];
    retainUtilModel.positionType = CJPayRetainBiopaymentPage;
    retainUtilModel.isBonusPath = YES;
    UIViewController *sourceVC = self.bioHomeVC ?: [self.manager.homePageVC topVC];
    
    if ([retainUtilModel.retainInfoV2Config isOpenLynxRetain]) {
        return [self p_lynxRetain:retainUtilModel sourceVC:(UIViewController *)sourceVC redoBlock:redoBlock];
    }
    
    @CJWeakify(self);
    retainUtilModel.confirmActionBlock = redoBlock;
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self)
        [self p_closePayDesk];
    };
    return [CJPayRetainUtil couldShowRetainVCWithSourceVC:sourceVC retainUtilModel:retainUtilModel];
}

- (BOOL)p_isShowBioConfirmVC:(CJPayECVerifyManager *)verifyManager response:(CJPayBDCreateOrderResponse *)response {
    //仅有电商场景，当前置展示了面容前置，且默认下发验证方式为面容，并且抖音端版本>20.3.0时，后端下发true
    if (response.skipBioConfirmPage) {
        return NO;
    }
    
    if ([self.manager.homePageVC isKindOfClass:[CJPayECController class]]) {
        CJPayECController *homePageVC = (CJPayECController *)self.manager.homePageVC;
        if (homePageVC.cashierScene == CJPayCashierScenePreStandard) {
            if ([[CJPayABTest getABTestValWithKey:CJPayABFontpPayBioConfirmPage] isEqualToString:@"1"]) {
                return NO;
            } else {
                return YES;
            }
        }
    }
    
    if (verifyManager.isNotSufficient) {
        UIViewController *topVC = [UIViewController cj_topViewController];
        //余额不足卡列表页&&不命中实验，显示生物确页
        return [topVC isKindOfClass:CJPayPayAgainChoosePayMethodViewController.class];
    }
    
    // 标准前置不显示指纹面容首页
    if ([self.manager isKindOfClass:[CJPayECVerifyManager class]]) {
        CJPayECVerifyManager *ecommerceVerifyManager = (CJPayECVerifyManager *)self.manager;
        if (ecommerceVerifyManager.payContext.isPreStandardDesk) {
            return NO;
        }
    }
    
    if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger) {
        return NO;
    }
    
    //免密禁用密码页切换指纹/面容支付
    if (self.manager.isSkipPWDForbiddenOpt) {
        return NO;
    }
    
    return YES;
}

- (void)p_closePayDesk {
    [self.manager sendEventTOVC:CJPayHomeVCEventClosePayDesk obj:@(CJPayHomeVCCloseActionSourceFromBack)];
}

#pragma mark - Tracker

- (NSDictionary *)p_buildClickTrackerParams:(CJPayBDCreateOrderResponse *)response type:(CJPayClickButtonType)type{
    NSMutableDictionary *params = [NSMutableDictionary new];
    switch (type) {
        case CJPayClickButtonConfirm:
            [params cj_setObject:@"1" forKey:@"button_name"];
            break;
        case CJPayClickButtonUsePWD:
            [params cj_setObject:@"5" forKey:@"button_name"];
            break;
        case CJPayClickButtonCancel:
            [params cj_setObject:@"0" forKey:@"button_name"];
            break;
        default:
            [params cj_setObject:@"-1" forKey:@"button_name"];
            break;
    }
    [params addEntriesFromDictionary:[self p_buildVoucherMsgTrackerParams:response]];
    return [params copy];
}

- (NSDictionary *)p_buildImpTrackerParams:(CJPayBDCreateOrderResponse *)response {
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params cj_setObject:@YES forKey:@"is_pswd_button"];
    [params cj_setObject:response.payInfo.verifyDesc forKey:@"tips_label"];
    [params addEntriesFromDictionary:[self p_buildVoucherMsgTrackerParams:response]];
    return [params copy];
}

- (NSDictionary *)p_buildVoucherMsgTrackerParams:(CJPayBDCreateOrderResponse *)response {
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params cj_setObject:[self p_getVoucherMsg:response] forKey:@"activity_label"];
    return [params copy];
}

- (NSString *)p_getVoucherMsg:(CJPayBDCreateOrderResponse *)response {
    NSString *voucherMsg = @"";
    CJPayInfo *payInfo = response.payInfo;
    
    if (payInfo == nil) {
        return voucherMsg;
    }
    
    int type = [response.payInfo.voucherType intValue];
    
    switch ((CJPayVoucherType)type) {
        case CJPayVoucherTypeNone:
            break;
        case CJPayVoucherTypeImmediatelyDiscount:
        case CJPayVoucherTypeRandomDiscount:
        case CJPayVoucherTypeBankCardImmediatelyDiscount:
        case CJPayVoucherTypeBankCardOtherDiscount:
            voucherMsg = response.payInfo.voucherMsg;
            break;
        case CJPayVoucherTypeFreeCharge:
            voucherMsg = [NSString stringWithFormat:@"¥%@x%@期（免手续费）", CJString(response.payInfo.payAmountPerInstallment), CJString(response.payInfo.creditPayInstallment)];
            break;
        case CJPayVoucherTypeChargeDiscount:
            voucherMsg = [NSString stringWithFormat:@"¥%@x%@期（手续费¥%@ ¥%@/期）", CJString(response.payInfo.payAmountPerInstallment), CJString(response.payInfo.creditPayInstallment), CJString(response.payInfo.realFeePerInstallment),
                CJString(response.payInfo.originFeePerInstallment)];
            break;
        case CJPayVoucherTypeChargeNoDiscount:
            voucherMsg = [NSString stringWithFormat:@"¥%@x%@期（手续费¥%@/期）", CJString(response.payInfo.payAmountPerInstallment), CJString(response.payInfo.creditPayInstallment), Check_ValidString(response.payInfo.originFeePerInstallment) ? CJString(response.payInfo.originFeePerInstallment): CJString(response.payInfo.realFeePerInstallment)];//优先显示原手续费
            break;
        case CJPayVoucherTypeStagingWithDiscount:
        case CJPayVoucherTypeStagingWithRandomDiscount:
            voucherMsg = [NSString stringWithFormat:@"%@，¥%@x%@期（手续费¥%@/期）", CJString(response.payInfo.voucherMsg),
                CJString(response.payInfo.payAmountPerInstallment),
                CJString(response.payInfo.creditPayInstallment),
                CJString(response.payInfo.originFeePerInstallment)];
            break;
        default:
            break;
    }
    return [voucherMsg copy];
}

@end
