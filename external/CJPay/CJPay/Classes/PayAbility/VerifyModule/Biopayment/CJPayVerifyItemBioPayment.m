//
//  CJPayVerifyItemBioPayment.m
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import "CJPayVerifyItemBioPayment.h"
#import "CJPayMemberEnableBioPayRequest.h"
#import "CJPayBioManager.h"
#import "CJPayTouchIdManager.h"
#import "CJPayUIMacro.h"
#import "CJPayBioPaymentTimeCorrectRequest.h"
#import "CJPaySafeUtil.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayAlertUtil.h"
#import "CJPayBDBioConfirmViewController.h"
#import "CJPayToast.h"
#import "CJPayBioVerifyUtil.h"

#import <LocalAuthentication/LocalAuthentication.h>

@interface CJPayVerifyItemBioPayment()

@property (nonatomic, weak) CJPayBDBioConfirmViewController *confirmVC;
@property (nonatomic, assign) BOOL disableSwitchToPasswordInVerifying;
@property (nonatomic, strong) CJPayEvent *event;

@end

@implementation CJPayVerifyItemBioPayment

- (NSDictionary *)p_buildBioPaymentOneTimePWD:(CJPayBioSafeModel *)model {
    NSData *tokenData = [model.seedHexString hexToBytes];
    NSString *token = [CJPayBioManager generatorTOTPToken:tokenData dateCorrect:CJPayLocalTimeServerTimeDelta digits:model.tokenLength period:model.timeStep];
    NSMutableDictionary *dic = [NSMutableDictionary new];
    if (self.manager.isOneKeyQuickPay || self.manager.isSkipPWDForbiddenOpt) {
        if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace) {
            [dic cj_setObject:@"2" forKey:@"pwd_type"];
        } else {
            [dic cj_setObject:@"1" forKey:@"pwd_type"];
        }
    } else {
        [dic cj_setObject:self.manager.response.userInfo.pwdCheckWay forKey:@"pwd_type"];
    }
    NSString *tokenWithProcessID = [NSString stringWithFormat:@"%@%@", token, CJString(self.manager.response.processInfo.processId)];
    NSString *serialNumWithProcessID = [NSString stringWithFormat:@"%@%@", model.serialNum, CJString(self.manager.response.processInfo.processId)];

    [dic cj_setObject:[CJPaySafeUtil encryptField:tokenWithProcessID] forKey:@"token_code"];
    [dic cj_setObject:[CJPaySafeUtil encryptField:serialNumWithProcessID] forKey:@"serial_num"];
    return dic;
}

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    CJPayBioPaymentType bioType = [CJPayTouchIdManager currentSupportBiopaymentType];

    // APP生物权限被关闭
    if ([CJPayTouchIdManager isBiometryNotAvailable] || [CJPayTouchIdManager isTouchIDNotEnrolled]) {
        self.manager.isNeedShowBioTips = YES;
        NSString *tipMsg = CJPayLocalizedStr(@"生物信息不可用，此次使用密码支付");
        
        switch (bioType) {
            case CJPayBioPaymentTypeFace:
                tipMsg = CJPayLocalizedStr(@"面容信息不可用，此次使用密码支付");
                break;
            case CJPayBioPaymentTypeFinger:
                tipMsg = CJPayLocalizedStr(@"指纹信息不可用，此次使用密码支付");
                break;
            default:
                break;
        }
        
        CJPayEvent *event = [[CJPayEvent alloc] initWithName:@(CJPayVerifyTypePassword).stringValue data:tipMsg];
        [self p_switchToPasswordPassiveWithResponse:response passiveType:@"bioNotAvailable" reason:tipMsg];

        return;
    }

    if ([CJPayTouchIdManager touchIdInfoDidChange]) {
        NSString *tipMsg = bioType == CJPayBioPaymentTypeFace ? CJPayLocalizedStr(@"面容信息变更，此次使用密码支付") : CJPayLocalizedStr(@"指纹信息变更，此次使用密码支付");
        CJPayEvent *event = [[CJPayEvent alloc] initWithName:@(CJPayVerifyTypePassword).stringValue data:tipMsg];
        [self p_switchToPasswordPassiveWithResponse:response passiveType:@"bioChange" reason:tipMsg];
        return;
    }
    
    static int errorTimes = 0;

    CJPayBioPaymentBaseRequestModel *requestModel = [CJPayBioPaymentBaseRequestModel new];
    requestModel.uid = response.userInfo.uid;
    requestModel.appId = response.merchant.appId;
    requestModel.merchantId = response.merchant.merchantId;
    CJPayBioSafeModel *model = [CJPayBioManager getSafeModelBy:requestModel];
    
    // 当前的token文件无效，或指纹无信息
    if (![model isValid] || ![CJPayTouchIdManager currentOriTouchIdData]) {
        [self p_switchToPasswordPassiveWithResponse:response passiveType:@"tokenInvalid" reason:nil];
        return;
    }
    
    // 生物验证被锁定（连续多次验证失败后）
    if ([CJPayTouchIdManager isErrorBiometryLockout]) {
        BioPaymentAction action = [self p_bioPaymentAction];
            [self p_lockoutSwitchToPasswordShowTopRightButtonWithResponse:response];
        return;
    }
    
    errorTimes += 1;
    [self.manager sendEventTOVC:CJPayHomeVCEventUpdateConfirmBtnTitle obj:CJPayLocalizedStr(@"等待付款中")];
    [self setConfirmButtonEnableStatus:NO];
    
    NSString *localizedReason = CJPayLocalizedStr(@"请验证已有的指纹，用于支付");
    if (bioType == CJPayBioPaymentTypeFace) {
        localizedReason = CJPayLocalizedStr(@"面容验证失败");
    }
    
    // 极速支付验证面容时需要新增加首页
    if (bioType == CJPayBioPaymentTypeFace && self.manager.isOneKeyQuickPay) {
        CJPayBDBioConfirmViewController *bioConfirmVC = [CJPayBDBioConfirmViewController new];
        @CJWeakify(self)
        bioConfirmVC.verifyReasonText = CJString(response.msg);
        bioConfirmVC.confirmBlock = ^{
            @CJStrongify(self)
            [self bioPayWithResponse:response
                               model:model
                     localizedReason:localizedReason
                   isSkipPwdSelected:NO
                          completion:nil];
        };
        self.confirmVC = bioConfirmVC;
        [self.manager.homePageVC push:bioConfirmVC animated:YES];
    } else {
        [self bioPayWithResponse:response
                           model:model
                 localizedReason:localizedReason
               isSkipPwdSelected:self.manager.isSkipPwdSelected
                      completion:nil];
    }
    // 这个toast延迟弹出，主要是避免被面容确认页盖住，同时也能够接收receiveEvent
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BOOL isActive = [self.event.data cj_boolValueForKey:@"is_active"]; // 是否主动切换到面容
        if (!isActive && response.payInfo.verifyDescType == 4 && Check_ValidString(response.payInfo.verifyDesc)) {
                [CJToast toastText:response.payInfo.verifyDesc inWindow:[self.manager.homePageVC topVC].cj_window location:CJPayToastLocationBottom];
        }
    });
}

- (void)bioPayWithResponse:(CJPayBDCreateOrderResponse *)response
                     model:(CJPayBioSafeModel *)model
           localizedReason:(NSString *)localizedReason
         isSkipPwdSelected:(BOOL)isSkipPwdSelected
                completion:(void (^ __nullable)(BOOL isUserCancel))completion {
    NSDictionary *nopwdDic = @{
        @"nopwd_disable_reason": CJString(response.payInfo.verifyDowngradeReason)
    };
    [self event:@"wallet_fingerprint_verify_page_imp" params:nopwdDic];
    [self event:@"wallet_fingerprint_verify_page_input" params:nil];
    
    BioPaymentAction action = [self p_bioPaymentAction];

    NSString *cancelTitle = CJPayLocalizedStr(@"取消");
    NSString *falldBackTitle = CJPayLocalizedStr(@"密码支付");
    
    if (action == BioPaymentActionExchangeTitleCancelToPWD) {
        cancelTitle = CJPayLocalizedStr(@"密码支付");
        falldBackTitle = CJPayLocalizedStr(@"取消");
    }

    @CJWeakify(self)
    [CJPayTouchIdManager showTouchIdWithLocalizedReason:localizedReason
                                            cancelTitle:cancelTitle
                                         falldBackTitle:falldBackTitle
                                          fallBackBlock:^{
        @CJStrongify(self)
        CJPayEvent *event = [self buildEventSwitchToPasswordWithReason:@"" isActive:YES];
        BioPaymentClickType clickType = BioPaymentClickTypeUserFallback;
        if (action == BioPaymentActionExchangeTitleCancelToPWD || action == BioPaymentActionCancelToPWD) {
            clickType = BioPaymentClickTypeUserCancel;
            [self p_trackShowTopRightButtonWithBioEvent:CJPayBioEventCancelToPWD];
        }
        
        [self p_verifyingSwitchToPassword:response event:event clickType:clickType];
        CJ_CALL_BLOCK(completion, NO);
    } resultBlock:^(BOOL useable, BOOL success, NSError * _Nonnull error, NSInteger policy) {
        @CJStrongify(self)
        [self setConfirmButtonEnableStatus:YES];
        [self.manager sendEventTOVC:CJPayHomeVCEventUpdateConfirmBtnTitle obj:CJPayLocalizedStr(@"确认支付")];
        
        [self event:@"wallet_fingerprint_verify_page_verify_result" params:@{
            @"result" : success ? @"1" : @"0",
            @"error_code" : @(error.code),
            @"error_message" : CJString([error localizedDescription]),
            @"error_cn_message" : CJString([CJPayBioVerifyUtil bioCNErrorMessageWithError:error])
        }];

        if (success) {
            // 指纹或面容验证成功
            NSMutableDictionary *pwdDic = [NSMutableDictionary new];
            if (self.manager.confirmResponse && [@[@"CD002006", @"CD002007"] containsObject:self.manager.confirmResponse.code]) {
                if ([self.manager.confirmResponse.code isEqualToString:@"CD002006"]) {
                    [pwdDic cj_setObject:@"7" forKey:@"req_type"];
                } else {
                    [pwdDic cj_setObject:@"8" forKey:@"req_type"];
                }
            }
            
            if (self.manager.response.skipPwdGuideInfoModel.needGuide) {
                [pwdDic cj_setObject:@(isSkipPwdSelected) forKey:@"selected_open_nopwd"];
            }
            
            [pwdDic cj_setObject:[self p_buildBioPaymentOneTimePWD: model] forKey:@"one_time_pwd"];
            [pwdDic addEntriesFromDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypePassword]];
            [[NSNotificationCenter defaultCenter] postNotificationName:CJPayShowPasswordKeyBoardNotification object:@(0)];
            [self.manager submitConfimRequest:pwdDic fromVerifyItem:self];
            CJ_CALL_BLOCK(completion, NO);
            self.disableSwitchToPasswordInVerifying = NO;
        } else {
            if ([CJPayTouchIdManager isErrorBiometryLockout] && (action == BioPaymentActionExchangeTitleCancelToPWD || action == BioPaymentActionCancelToPWD)) {
                // 增加延时，防止触发生物锁定时仍未调用receiveEvent，导致重复拉起验密页
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self p_lockoutSwitchToPasswordShowTopRightButtonWithResponse:response];
                });
                CJ_CALL_BLOCK(completion, NO);
                return;
            }
            
            CJPayEvent *event = [self buildEventSwitchToPasswordWithReason:@"" isActive:YES];
            if (error.code == LAErrorUserCancel) {
                if (action == BioPaymentActionExchangeTitleCancelToPWD || action == BioPaymentActionCancelToPWD) {
                    BioPaymentClickType clickType = action == BioPaymentActionCancelToPWD ? BioPaymentClickTypeUserCancel : BioPaymentClickTypeUserFallback;
                    [self p_verifyingSwitchToPassword:response event:event clickType:clickType];
                    [self p_trackShowTopRightButtonWithBioEvent:CJPayBioEventCancelToPWD];
                    CJ_CALL_BLOCK(completion, NO);
                    return;
                }
                
                [self event:@"wallet_fingerprint_verify_page_click" params:@{
                    @"button_name" : @"取消"
                }];
                [self.manager sendEventTOVC:CJPayHomeVCEventUserCancelRiskVerify obj:@(CJPayVerifyTypeBioPayment)];
                CJ_CALL_BLOCK(completion, YES);
                return;
            }
            
            // 生物验证时APP切后台，则系统退出验证
            if (error.code == LAErrorSystemCancel && [self.manager.response.payInfo.cashierTags containsObject:@"bio_recover"]) {
                [self p_verifyingSwitchToPassword:response event:event clickType:BioPaymentClickTypeNone];
                [self p_trackShowTopRightButtonWithBioEvent:CJPayBioEventSystemCancelToPWD];
                CJ_CALL_BLOCK(completion, NO);
                return;
            }
            
            if (error.code == LAErrorAuthenticationFailed) {
                if (action == BioPaymentActionExchangeTitleCancelToPWD || action == BioPaymentActionCancelToPWD) {
                    [self p_verifyingSwitchToPassword:response event:event clickType:BioPaymentClickTypeNone];
                    [self p_trackShowTopRightButtonWithBioEvent:CJPayBioEventCancelToPWD];
                    CJ_CALL_BLOCK(completion, NO);
                    return;
                }
            }
            
            [self verifyTypeSwitchToPassCode:response event:event];
            CJ_CALL_BLOCK(completion, NO);
        }
    }];
}

- (void)receiveEvent:(CJPayEvent *)event {
    if (![event.name isEqualToString:CJPayVerifyEventSwitchToBio]) {
        return;
    }
    self.event = event;
    if ([event.data isKindOfClass:NSDictionary.class]) {
        NSDictionary *dict = (NSDictionary *)event.data;
        BOOL isActive = [dict cj_boolValueForKey:@"is_active"];
        self.disableSwitchToPasswordInVerifying = isActive; // 从密码切换为生物验证，再次切换为密码时无需重复唤起验密组件
    }
}

- (void)setConfirmButtonEnableStatus:(BOOL)isEnable {
    [self.manager sendEventTOVC:CJPayHomeVCEventEnableConfirmBtn obj:@(isEnable)];
}

- (void)p_alertTipsWithResponse:(CJPayOrderConfirmResponse *)response {
    NSString *bioTypeStr = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace ? CJPayLocalizedStr(@"面容支付") : CJPayLocalizedStr(@"指纹支付");
    
    NSString *title = [NSString stringWithFormat:CJPayLocalizedStr(@"%@功能已失效"), bioTypeStr];
    NSString *content = [NSString stringWithFormat:CJPayLocalizedStr(@"请支付后重新开通%@"), bioTypeStr];
    
    [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(title)
                                 content:CJPayLocalizedStr(content)
                              buttonDesc:CJPayLocalizedStr(@"使用密码支付")
                             actionBlock:^{
        CJPayEvent *event = [self buildEventSwitchToPasswordWithReason:nil isActive:NO];
        [self verifyTypeSwitchToPassCode:self.manager.response event:event];
    } useVC:[self.manager.homePageVC topVC]];
}

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 免密的场景下指纹面容支持加验
    if ([@[@"CD002006", @"CD002007"] containsObject:CJString(response.code)]) {
        return YES;
    }
    
    if ([response.code isEqualToString:@"CD006008"]) {
        return YES;
    }
    
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response {
    // 免密的场景下指纹面容支持加验
    if ([@[@"CD002006", @"CD002007"] containsObject:CJString(response.code)]) {
        [self requestVerifyWithCreateOrderResponse:self.manager.response event:nil];
        if (self.manager.lastConfirmVerifyItem.verifyType == CJPayVerifyTypeSkipPwd) {
            [CJToast toastText:CJPayLocalizedStr(@"该笔订单无法使用免密支付，请验证后继续付款") inWindow:[self.manager.homePageVC topVC].cj_window];
        }
    }
    
    if ([response.code isEqualToString:@"CD006008"]) {
        [self p_alertTipsWithResponse:response];
    }
}

- (NSDictionary *)getLatestCacheData {
    CJPayBioPaymentBaseRequestModel *requestModel = [CJPayBioPaymentBaseRequestModel new];
    requestModel.uid = self.manager.response.userInfo.uid;
    requestModel.appId = self.manager.response.merchant.appId;
    requestModel.merchantId = self.manager.response.merchant.merchantId;
    CJPayBioSafeModel *model = [CJPayBioManager getSafeModelBy:requestModel];
    if ([model isValid]) {
        return @{@"one_time_pwd": [self p_buildBioPaymentOneTimePWD:model] ?: @{}};
    } else {
        return [self.manager loadSpecificTypeCacheData:CJPayVerifyTypePassword];
    }
}

// 切换至密码支付
- (void)verifyTypeSwitchToPassCode:(CJPayBDCreateOrderResponse *)response event:(nullable CJPayEvent *)event {
    // 如果是在验密页拉起的生物验证，那么从生物切换回密码时不需要额外再唤起验密组件，只需唤起键盘即可
    if (!self.disableSwitchToPasswordInVerifying) {
        [self.manager wakeSpecificType:CJPayVerifyTypePassword orderRes:response event:event];
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:CJPayShowPasswordKeyBoardNotification object:@(1)];
    }
    self.disableSwitchToPasswordInVerifying = NO;
}

- (CJPayEvent *)buildEventSwitchToPasswordWithReason:(NSString *)reasonTip isActive:(BOOL)isActive {
    NSDictionary *eventData = @{
        @"is_active": @(isActive), // 是否主动降级（生物不可用等原因为被动降级，主动点击切换/取消等为主动降级）
        @"other_verify_btn": CJString([self p_payName]), // 降级为密码后右上角验证按钮文案
        @"switch_reason": CJString(reasonTip) // 降级文案
    };
    CJPayEvent *event = [[CJPayEvent alloc] initWithName:CJPayVerifyEventSwitchToPassword data:eventData];
    event.verifySourceType = CJPayVerifyTypeBioPayment;
    return event;
}

- (NSString *)checkTypeName {
    if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace) {
        return @"面容";
    } else {
        return @"指纹";
    }
}

- (NSString *)checkType {
    if ([CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace) {
        return @"2";
    } else {
        return @"1";
    }
}

- (BioPaymentAction)p_bioPaymentAction {
    if (@available(iOS 10.0, *)) {
        if ([self.manager.response.payInfo.cashierTags containsObject:@"BioFailedPwdVerifyOptimizationV2"]) {
            return BioPaymentActionExchangeTitleCancelToPWD;
        }
    }
    
    if ([self.manager.response.payInfo.cashierTags containsObject:@"BioFailedPwdVerifyOptimizationV1"]
        || [self.manager.response.payInfo.cashierTags containsObject:@"BioFailedPwdVerifyOptimizationV2"]) {
        return BioPaymentActionCancelToPWD;
    }
    return BioPaymentActionNomal;
}

// 生物验证 主动降级为密码验证
- (void)p_verifyingSwitchToPassword:(CJPayBDCreateOrderResponse *)response event:(nullable CJPayEvent *)event clickType:(BioPaymentClickType)clickType {
    
    [self verifyTypeSwitchToPassCode:response event:event];
    
    [self setConfirmButtonEnableStatus:YES];
    [self.manager sendEventTOVC:CJPayHomeVCEventUpdateConfirmBtnTitle obj:CJPayLocalizedStr(@"确认支付")];
    
    NSString * errorCode = @"";
    NSString * buttonName= @"";
    
    if (clickType == BioPaymentClickTypeUserFallback) {
        errorCode = @(LAErrorUserFallback).stringValue;
        buttonName = @"输入密码";
    } else if (clickType == BioPaymentClickTypeUserCancel) {
        errorCode = @(LAErrorUserCancel).stringValue;
        buttonName = @"取消";
    }
    
    [self event:@"wallet_fingerprint_verify_page_click" params: @{
        @"error_code" : CJString(errorCode),
        @"button_name" : CJString(buttonName)
    }];
}

// 生物验证 被动降级为密码验证
- (void)p_switchToPasswordPassiveWithResponse:(CJPayBDCreateOrderResponse *)response
                                  passiveType:(NSString *)passiveType
                                       reason:(nullable NSString *)reason {
    
    NSString *downgradeReason = CJString(response.payInfo.verifyDesc);
    if (Check_ValidString(reason)) {
        downgradeReason = reason;
    }
    [self event:@"wallet_rd_bio_downgrade_password_passive"
         params: @{
        @"type" : CJString(passiveType),
        @"reason" : CJString(reason)
    }];
    
    CJPayEvent *event = [self buildEventSwitchToPasswordWithReason:downgradeReason isActive:NO];
    [self verifyTypeSwitchToPassCode:response event:event];
}

- (NSString *)p_payName {
    return [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFace ? CJPayLocalizedStr(@"面容支付"): CJPayLocalizedStr(@"指纹支付");;
}

- (void)p_lockoutSwitchToPasswordShowTopRightButtonWithResponse:(CJPayBDCreateOrderResponse *)response  {
    NSString *msg = CJPayLocalizedStr(@"不支持指纹/面容");
    CJPayBioPaymentType type = [CJPayTouchIdManager currentSupportBiopaymentType];
    
    if (type == CJPayBioPaymentTypeFinger) {
        msg = CJPayLocalizedStr(@"指纹已锁定，可在「设置-触控ID与密码」验证密码解锁");
    } else if (type == CJPayBioPaymentTypeFace) {
        msg = CJPayLocalizedStr(@"面容已锁定，可在「设置-面容ID与密码」验证密码解锁");
    }
    
    // 面容/指纹被锁定，降级为密码验证
    CJPayEvent *event = [self buildEventSwitchToPasswordWithReason:msg isActive:YES]; // 这里传YES是因为验证完开机密码后仍可继续使用生物验证，需要与其他被动降级case区分开
    [self p_verifyingSwitchToPassword:response event:event clickType:BioPaymentClickTypeNone];
}

- (void)p_trackShowTopRightButtonWithBioEvent:(CJPayBioEvent)event {
    NSString *buttonName = [self p_payName];
    NSString *featureType = event == CJPayBioEventCancelToPWD ? @"首次面容失败" : @"生物识别失败挽留";
    
    [self event:@"wallet_cashier_fingerprint_enable_guide_success_imp"
         params:@{@"button_name": CJString(buttonName),
                  @"feature_type": CJString(featureType)
                }];
}

@end
