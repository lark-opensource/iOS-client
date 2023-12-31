//
//  CJPayDouPayProcessController.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2023/5/31.
//

#import "CJPayDouPayProcessController.h"
#import "CJPayDouPayProcessVerifyManager.h"
#import "CJPayDouPayProcessVerifyManagerQueen.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayLoadingManager.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayWebViewUtil.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPayNavigationController.h"
#import "UIViewController+CJTransition.h"
#import "CJPayEnumUtil.h"
#import "CJPayHintInfo.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayLoadingButton.h"
#import "CJPayECPopUpNotSufficientViewController.h"
#import "CJPayECHalfNotSufficientViewController.h"
#import "CJPayPayAgainHalfViewController.h"
#import "CJPayKVContext.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPayPayCancelRetainViewController.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayRequestParam.h"
#import "CJPaySafeUtil.h"
#import "CJPayBDResultPageViewController.h"
#import "CJPaySkippwdGuideUtil.h"
#import "CJPayBioSystemSettingGuideViewController.h"
#import "CJPayCreditPayUtil.h"
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import "CJPayAlertUtil.h"
#import "CJPayTimerManager.h"
#import "CJPaySettingsManager.h"
#import "CJPayGuideResetPwdPopUpViewController.h"
#import "CJPayChooseDyPayMethodManager.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayDeskUtil.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayTradeInfo.h"
#import "CJPayResultPageModel.h"
#import "CJPayFullResultPageViewController.h"
#import "CJPayAuthUtil.h"
#import "CJPayHalfVerifyPasswordV3ViewController.h"
#import "CJPayPasswordContentViewV3.h"
#import "CJPayLynxShowInfo.h"
#import "CJPayPayCancelLynxRetainViewController.h"
#import "CJPayUnlockBankCardRequest.h"
#import "CJPayCombinePayInfoModel.h"

NSString *const kDouPayResultCreditPayDisableStrKey = @"creditpay_disable_msg_key";
NSString *const kDouPayResultTradeStatusStrKey = @"bdtrade_status_str_key";
NSString *const kDouPayResultBDProcessInfoStrKey = @"bd_process_info_str_key";

@implementation CJPayDouPayProcessModel

@end

@implementation CJPayDouPayProcessResultModel

- (BOOL)isReachOrderFinalState {
    NSArray *finalStatesList = @[@(CJPayDouPayResultCodeOrderSuccess),
                                 @(CJPayDouPayResultCodeOrderProcess),
                                 @(CJPayDouPayResultCodeOrderFail),
                                 @(CJPayDouPayResultCodeOrderTimeout),
                                 @(CJPayDouPayResultCodeOrderUnknown),
                                 @(CJPayDouPayResultCodeClose)];
    return [finalStatesList containsObject:@(self.resultCode)];
}

@end

@interface CJPayDouPayProcessController() <CJPayHomeVCProtocol, CJPayChooseDyPayMethodDelegate, CJPayPayAgainDelegate, CJPayTrackerProtocol, CJPayDeskRouteDelegate>

@property (nonatomic, strong) CJPayDouPayProcessVerifyManager *verifyManager;
@property (nonatomic, strong) CJPayDouPayProcessVerifyManagerQueen *verifyManagerQueen;

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *currentShowConfig;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *createResponse;
@property (nonatomic, copy) void(^completionBlock)(CJPayDouPayProcessResultModel * _Nonnull resultModel);

@property (nonatomic, strong) CJPayNavigationController *navigationController;
@property (nonatomic, strong) CJPayDouPayProcessModel *configModel;

@property (nonatomic, assign) CJPayDouPayResultPageStyle resultPageStyle; //标识是否需要展示支付结果页
@property (nonatomic, assign) BOOL isHasCallBack; //是否已经回调过，避免重复回调
@property (nonatomic, assign) BOOL isFeGuide;

@property (nonatomic, strong) NSMutableDictionary *payDisabledFundID2ReasonMap;

@property (nonatomic, assign) BOOL isCreditPayActiveSuccess;
@property (nonatomic, assign) BOOL isGuidePagePush;

@property (nonatomic, copy) NSDictionary *extParams; //透传参数

@property (nonatomic, strong) CJPayDefaultChannelShowConfig *bindCardShowConfig;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *signCardShowConfig;
@property (nonatomic, copy) NSDictionary *bindCardExtParams;

// 安全感loading耗时埋点
@property (nonatomic, assign) CFAbsoluteTime startloadingTime;
@property (nonatomic, assign) CFAbsoluteTime stoploadingTime;
@property (nonatomic, assign) NSTimeInterval enterTimestamp;

@end


@implementation CJPayDouPayProcessController

- (void)douPayProcessWithModel:(CJPayDouPayProcessModel *)model completion:(void (^)(CJPayDouPayProcessResultModel * _Nonnull resultModel))completion {
    [CJPayLoadingManager defaultService].loadingStyleInfo = model.createResponse.loadingStyleInfo;
    [CJPayLoadingManager defaultService].bindCardLoadingStyleInfo = model.createResponse.bindCardLoadingStyleInfo;
    self.configModel = model;
    self.createResponse = model.createResponse;
    self.currentShowConfig = model.showConfig;
    self.completionBlock = completion;
    self.extParams = model.extParams;
    self.resultPageStyle = model.resultPageStyle;
    self.verifyManager.trackInfo = [model.extParams cj_dictionaryValueForKey:@"track_info"];
    self.verifyManager.lynxBindCardBizScence = model.lynxBindCardBizScence;
    self.verifyManager.notStopLoading = model.isHasLaterProcess;
    self.verifyManager.pwdPageStyle = model.pwdPageStyle;
    self.verifyManager.bizParams = model.bizParams;
    self.verifyManager.isPaymentForOuterApp = model.isFromOuterApp;
    [self p_trackPerformance];
    
    if (self.configModel.isFrontPasswordVerify) {
        [self p_pay];
        [self p_trackNormalPayWithSource:@"O项目密码前置支付"];
        return;
    }
    
    switch (self.currentShowConfig.type) {
        case BDPayChannelTypeAddBankCard:
            [self p_bindCardAndPay];
            [self p_trackBindCardAndPayWithSource:@"提单页绑卡并支付"];
            break;
        case BDPayChannelTypeBankCard:
            [self p_tryUnLockBankCardAndPay];
            break;
        case BDPayChannelTypeBalance:
        case BDPayChannelTypeFundPay:
            [self p_pay];
            [self p_trackNormalPayWithSource:@"提单页普通支付"];
            break;
        case BDPayChannelTypeCreditPay:
            [self p_activeCreditAndPayWithTrackSourceStr:@"提单页月付支付"];
            break;
        case BDPayChannelTypeAfterUsePay:
            [self p_payAfterUse];
            break;
        case BDPayChannelTypeIncomePay:
            [self p_preIncomePay];
            break;
        default: {
            CJPayLogAssert(NO, @"不能处理的数据类型%d", self.currentShowConfig.type);
            break;
        }
    }
}

- (void)p_tryUnLockBankCardAndPay {
    NSDictionary *exts = self.createResponse.lynxShowInfo.exts;
    NSString *lockedBankCardList = [exts cj_stringValueForKey:@"lockedCardList"];
    NSString *bankCardId = self.currentShowConfig.bankCardId;
    if (Check_ValidString(bankCardId) && [lockedBankCardList containsString:bankCardId]) {
        [self p_bankCardUnlock];
    } else {
        [self p_pay];
        [self p_trackNormalPayWithSource:@"提单页普通支付"];
    }
}

- (void)p_bankCardUnlock {
    CJPayLynxShowInfo *lynxShowInfo = self.createResponse.lynxShowInfo;

    [self.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_main_process" params:@{
        @"process_name" : @"银行卡解锁并支付",
        @"process_source" : @"提单页触发",
        @"ext_params" : @{
            @"need_jump" : lynxShowInfo.needJump ? @"1" : @"0"
        }
    }];
    
    if (!lynxShowInfo.needJump) {
        [self p_requestUnlockBankCard];
        return;
    }
    CJPayPayCancelLynxRetainViewController *popUpVC = [[CJPayPayCancelLynxRetainViewController alloc] initWithRetainInfo:lynxShowInfo.exts schema:lynxShowInfo.url];
    @CJWeakify(self)
    popUpVC.eventBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull data) {
        @CJStrongify(self)
        if ([event isEqualToString:@"on_confirm"]) {
            [self p_requestUnlockBankCard];
            return;
        }
        NSString *msg = CJPayLocalizedStr(@"银行卡解锁取消");
        CJPayDouPayResultCode resultCode = CJPayDouPayResultCodeCancel;
        BOOL openFail = [data cj_boolValueForKey:@"open_fail"];
        if (openFail) {
            msg = CJPayLocalizedStr(@"解锁银行卡弹窗打开失败");
            resultCode = CJPayDouPayResultCodeFail;
            [CJTracker event:@"wallet_rd_open_cjlynxcard_fail" params:@{}];
        }
        [self p_callbackWithResultCode:resultCode errorMsg:msg];
    };
    [self push:popUpVC animated:YES];
}

- (void)p_requestUnlockBankCard {
    [CJPayLoadingManager.defaultService startLoading:CJPayLoadingTypeDouyinStyleLoading];
    @CJWeakify(self)
    [CJPayUnlockBankCardRequest startRequestWithBizParam:@{
        @"app_id": CJString(self.createResponse.merchant.appId),
        @"merchant_id": CJString(self.createResponse.merchant.merchantId),
        @"bank_card_id": CJString(self.currentShowConfig.bankCardId),
    } completion:^(NSError *error, CJPayBaseResponse * _Nonnull unlockResponse) {
        @CJStrongify(self)
        [CJPayLoadingManager.defaultService stopLoading];
        
        [self.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_main_process" params:@{
            @"process_name" : @"银行卡解锁并支付",
            @"process_source" : @"解锁请求",
            @"ext_params" : @{
                @"need_jump" : self.createResponse.lynxShowInfo.needJump ? @"1" : @"0",
                @"unlock_result" : (!error && unlockResponse.isSuccess) ? @"1" : @"0"
            }
        }];
        
        if (!error && unlockResponse.isSuccess) {
            [self p_showAndTrackUnlockToast:CJPayLocalizedStr(@"银行卡解锁成功")];
            [self p_pay];
            [self p_trackNormalPayWithSource:@"银行卡解锁成功支付"];
            return;
        }
        [self p_showAndTrackUnlockToast:CJPayLocalizedStr(@"银行卡解锁失败，请更换支付方式")];
        [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:CJPayLocalizedStr(@"银行卡解锁失败")];
    }];
}

- (void)p_showAndTrackUnlockToast:(NSString *)toastMsg {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CJToast toastText:toastMsg inWindow:self.topVC.cj_window];
    });
    [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_cashier_unlock_toast_imp" params:@{
        @"toast_label": CJString(toastMsg)
    }];
}

// 新样式验密页需额外解析支付方式配置
- (void)p_updateDefaultPayConfig {
    if (![self p_isPasswordV2Style]) { // 非6位密码页，不做额外处理
        return;
    }
    CJPayDefaultChannelShowConfig *curSelectConfig = self.currentShowConfig;
    CJPayInfo *payInfo = self.createOrderResponse.payInfo;
    curSelectConfig.payAmount = Check_ValidString(payInfo.standardShowAmount) ? CJString(payInfo.standardShowAmount) : CJString(payInfo.realTradeAmount);
    if (!Check_ValidString(curSelectConfig.payVoucherMsg)) {
        curSelectConfig.payVoucherMsg = CJString(payInfo.standardRecDesc);
    }
    if (!Check_ValidString(curSelectConfig.title)) {
        curSelectConfig.title = CJString(payInfo.payName);
    }
    
    if (curSelectConfig.type == BDPayChannelTypeCreditPay && !curSelectConfig.payTypeData) {
        if ([curSelectConfig.payChannel isKindOfClass:CJPaySubPayTypeInfoModel.class]) {
            curSelectConfig.payTypeData = ((CJPaySubPayTypeInfoModel *)curSelectConfig.payChannel).payTypeData;
        } else {
            curSelectConfig.payTypeData = [CJPaySubPayTypeData new];
        }
        [curSelectConfig.payTypeData updateDefaultCreditModel:[self.createOrderResponse.payInfo buildCreditPayMethodModel]];
        curSelectConfig.decisionId = self.createResponse.payInfo.decisionId;
    }
}

- (void)p_bindCardAndPay {
    self.verifyManager.extParams = [self p_isPasswordListStyle] ? self.bindCardExtParams : self.extParams;
    [self.verifyManager onBindCardAndPayAction];
}
 
- (void)p_pay {
    [self p_updateDefaultPayConfig];
    self.verifyManager.extParams = self.extParams;
    [self.verifyManager begin];
    [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_cashier_confirm_pswd_type_sdk"
                                                             params:@{}];
}

- (void)p_trackNormalPayWithSource:(NSString *)source {
    [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_main_process" params:@{
        @"process_name" : @"普通支付",
        @"process_source" : CJString(source)
    }];
}

- (void)p_trackBindCardAndPayWithSource:(NSString *)source {
    [self.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_main_process" params:@{
        @"process_name" : @"绑卡并支付",
        @"process_source" : CJString(source)
    }];
}

- (void)p_activeCreditAndPayWithTrackSourceStr:(NSString *)source {
    if (self.isCreditPayActiveSuccess) { //激活成功取消后，防止再次拉起激活流程（聚合首页选择月付激活，激活成功后取消，再次选择月付支付，后端没有刷新月付状态，所以客户端需要记录这个状态）
        [self p_pay];
        [self p_trackNormalPayWithSource:@"月付本次激活成功支付"];
        return;
    }
    
    @CJWeakify(self)
    [CJPayCreditPayUtil creditPayActiveWithPayInfo:self.createResponse.payInfo completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg, NSString * _Nonnull payToken) {
        @CJStrongify(self)
        [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_main_process" params:@{
            @"process_name" : self.createResponse.payInfo.isNeedJumpTargetUrl ?  @"月付解锁并支付" : @"月付激活并支付",
            @"process_source": CJString(source),
            @"ext_params" : @{
                @"credit_result" : @(type),
                @"credit_msg" : CJString(msg)
            }
        }];
        
        self.verifyManager.token = payToken;
        switch (type) {
            case CJPayCreditPayServiceResultTypeActivated:
                [self p_pay];
                [self p_trackNormalPayWithSource:@"月付已激活支付"];
                break;
            case CJPayCreditPayServiceResultTypeSuccess:
                self.isCreditPayActiveSuccess = YES;
                [self p_pay];
                [self p_trackNormalPayWithSource:@"月付激活成功支付"];
                break;
            case CJPayCreditPayServiceResultTypeNotEnoughQuota:
                self.isCreditPayActiveSuccess = YES;
                [self p_tryCallBackCreditPayFailWithErrorMsg:CJPayLocalizedStr(@"抖音月付激活成功，额度不足，请更换支付方式") disableStr:CJPayLocalizedStr(@"额度不足")];
                break;
            case CJPayCreditPayServiceResultTypeCancel:
                if (![self p_isInCJPay]) {
                    [self p_callbackWithResultCode:CJPayDouPayResultCodeCancel errorMsg:msg];
                }
                break;
            case CJPayCreditPayServiceResultTypeNoUrl:
            case CJPayCreditPayServiceResultTypeNoNetwork:
            case CJPayCreditPayServiceResultTypeFail:
                [self p_tryCallBackCreditPayFailWithErrorMsg:msg disableStr:CJPayLocalizedStr(@"激活失败")];
                break;
            case CJPayCreditPayServiceResultTypeTimeOut:
                [self p_tryCallBackCreditPayFailWithErrorMsg:msg disableStr:CJPayLocalizedStr(@"激活超时")];
                break;
            default:
                [self p_tryCallBackCreditPayFailWithErrorMsg:msg disableStr:CJPayLocalizedStr(@"激活失败")];
                break;
        }
    }];
}

- (void)p_tryCallBackCreditPayFailWithErrorMsg:(NSString *)errorMsg disableStr:(NSString *)disableStr {
    if ([self p_isInCJPay]) {
        return;
    }
    [self p_callbackWithResultCode:CJPayDouPayResultCodeCreditActivateFail errorMsg:errorMsg extParams:@{
        kDouPayResultCreditPayDisableStrKey : CJString(disableStr)
    }];
}

- (void)p_payAfterUse {
    if (self.createOrderResponse.userInfo.hasSignedCards) {
        [self p_pay];
        [self p_trackNormalPayWithSource:@"先用后付支付"];
    } else {
        [self p_bindCardAndPay];
        [self p_trackBindCardAndPayWithSource:@"先用后付流程"];
    }
}

- (void)p_preIncomePay {
    @CJWeakify(self)
    [CJPayAuthUtil authWithUserInfo:self.createResponse.userInfo fromVC:[self topVC] trackDelegate:self completion:^(CJPayAuthResultType resultType, NSString * _Nonnull msg, NSString * _Nonnull token, BOOL isBindCardSuccess) {
        @CJStrongify(self)
        switch (resultType) {
            case CJPayAuthResultTypeSuccess:
                self.verifyManager.token = token;
                [self p_pay];
                [self p_trackNormalPayWithSource:@"业务收入开户成功支付"];
                break;
            case CJPayAuthResultTypeAuthed:
                [self p_pay];
                [self p_trackNormalPayWithSource:@"业务收入已开户支付"];
                break;
            case CJPayAuthResultTypeFail:
                [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:msg];
                break;
            case CJPayAuthResultTypeCancel:
                if (![self p_isInCJPay]) {
                    [self p_callbackWithResultCode:CJPayDouPayResultCodeCancel errorMsg:msg];
                }
                break;
            default:
                if (![self p_isInCJPay]) {
                    [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:@"业务收入开户异常"];
                }
                CJPayLogInfo(@"用户开户异常");
                break;
        }
    }];
}

- (void)p_trackPerformance {
    // 上报提单页相关耗时、提单页解析接口数据耗时、jsb 调用耗时
    // self.createOrderResponse.userInfo.pwdCheckWay
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval currentTimestamp = [date timeIntervalSince1970] * 1000;
    self.enterTimestamp = currentTimestamp;

    if (![CJPaySettingsManager shared].currentSettings.isHitEventUploadSampled) {
        // 没有下发采样率数据，不上报
        CJPayLogInfo(@"未下发采样率数据，不上报买点");
        return;
    }

    NSDictionary *map = @{
        @"0" : @"密码",
        @"1" : @"指纹",
        @"2" : @"面容",
        @"3" : @"免密"
    };
    NSString *checkType = [map cj_stringValueForKey:self.createOrderResponse.userInfo.pwdCheckWay];
    NSMutableDictionary *timestampInfo = [[self.extParams cj_dictionaryValueForKey:@"timestamp_info"] mutableCopy];
    if (timestampInfo && timestampInfo.count) {
        NSTimeInterval createOrder = [timestampInfo cj_doubleValueForKey:@"create_order"];
        NSTimeInterval createOrderResponse = [timestampInfo cj_doubleValueForKey:@"create_order_response"];
        NSTimeInterval launchTTpay = [timestampInfo cj_doubleValueForKey:@"launch_ttpay"];
        
        if (createOrder > 100000 && createOrderResponse > 100000) {
            // 过滤无效数据
            [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_custom_scenes_time" params:@{
                @"scenes_name" : @"电商",
                @"check_type" : CJString(checkType),
                @"sub_section" : @"提交订单",
                @"time" : @(createOrderResponse - createOrder)
            }];
        }
        
        if (createOrderResponse > 100000 && launchTTpay > 100000) {
            // 过滤无效数据
            [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_custom_scenes_time" params:@{
                @"scenes_name" : @"电商",
                @"check_type" : CJString(checkType),
                @"sub_section" : @"解析提交订单接口数据",
                @"time" : @(launchTTpay - createOrderResponse)
            }];
        }
        
        if (launchTTpay > 100000) {
            [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_custom_scenes_time" params:@{
                @"scenes_name" : @"电商",
                @"check_type" : CJString(checkType),
                @"sub_section" : @"ttpay 调用耗时",
                @"time" : @(currentTimestamp - launchTTpay)
            }];
        }

    } else {
        timestampInfo = [NSMutableDictionary new];
    }
    
    UIFont *systemFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    NSNumber *fontNumber = [systemFont.fontDescriptor objectForKey:@"NSFontSizeAttribute"];
    if (fontNumber) {
        [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_custom_scenes_time" params:@{
            @"scenes_name" : @"iOS 系统设置的字体大小",
            @"time" : fontNumber
        }];
    }
    // 添加接收到 jsb 调用的时间戳，增加字段 ttpay_enter_cjpay
    [timestampInfo cj_setObject:@(currentTimestamp) forKey:@"ttpay_enter_cjpay"];
    NSMutableDictionary *updatedExtParams = [[NSMutableDictionary alloc] initWithDictionary:self.extParams];
    [updatedExtParams cj_setObject:timestampInfo forKey:@"timestamp_info"];
    // 更新 extParams
    self.extParams = [updatedExtParams copy];
}

#pragma mark - CJPayTrackProtocol
- (void)event:(NSString *)event params:(NSDictionary *)params {
    [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:event params:params];
}

#pragma mark - CJPayHomeVCProtocol
- (CJPayBDCreateOrderResponse *)createOrderResponse {
    return self.createResponse;
}

- (nullable CJPayDefaultChannelShowConfig *)curSelectConfig {
    if ([self p_isPasswordListStyle] && self.verifyManager.isBindCardAndPay && self.bindCardShowConfig) {
        return self.bindCardShowConfig;
    }
    
    if ([self p_isPasswordListStyle] && self.signCardShowConfig) {
        return self.signCardShowConfig;
    }
    
    return self.currentShowConfig;
}

- (void)endVerifyWithResultResponse:(nullable CJPayBDOrderResultResponse *)resultResponse {
    CJ_CALL_BLOCK(self.configModel.queryFinishBlock);
    
    CJPayTimerManager *preShowTimer = [CJPayLoadingManager defaultService].preShowTimerManger;
    CJPayTimerManager *payingShowTimer = [CJPayLoadingManager defaultService].payingShowTimerManger;
    if ([preShowTimer isTimerValid]) {
        [preShowTimer appendTimeoutBlock:^{
            [self endVerifyWithResultResponse:resultResponse];
        }];
        return;
    }
    
    if ([payingShowTimer isTimerValid]) {
        [payingShowTimer appendTimeoutBlock:^{
            [self p_endVerifyWithResultResponse:resultResponse];
        }];
        return;
    }
    
    [self p_endVerifyWithResultResponse:resultResponse];
}

- (void)p_endVerifyWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    self.stoploadingTime = CFAbsoluteTimeGetCurrent();
    [self p_trackConsumeTime];
    if (self.verifyManager.isNotSufficient) {
        [self p_removeNotSufficientPopUpViewController];
    }
    
    if (![resultResponse isSuccess]) {
        [CJToast toastText:CJPayNoNetworkMessage inWindow:[self topVC].cj_window];
        [[CJPayLoadingManager defaultService] stopLoading];
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:CJPayShowPasswordKeyBoardNotification object:@(0)];
    
    // 尝试展示支付后引导和结果页
    [self p_showGuidePageWithResponse:resultResponse];
}

- (void)p_trackConsumeTime {
    CFTimeInterval consumeTime = self.stoploadingTime - self.startloadingTime;
    CJPayLoadingStyleInfo *loadingStyleInfo = [CJPayLoadingManager defaultService].loadingStyleInfo;
    NSMutableDictionary *dict = [[loadingStyleInfo toDictionary] mutableCopy];
    [dict cj_setObject:@(consumeTime) forKey:@"consume_time"];
    [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_security_loading_from_gif_two_to_end_consume_time" params:dict];
}

- (void)p_removeNotSufficientPopUpViewController {
    UIViewController *topVC = [UIViewController cj_topViewController];
    NSMutableArray *viewControllers = [topVC.navigationController.viewControllers mutableCopy];
    if (viewControllers.count == 0) {
        [topVC.navigationController dismissViewControllerAnimated:NO completion:nil];
    } else {
        topVC.navigationController.viewControllers = [viewControllers copy];
    }
}

// 负责展示支付后引导
- (void)p_showGuidePageWithResponse:(CJPayBDOrderResultResponse *)resultResponse {
    @CJWeakify(self)
    void(^guideCompletionBlock)(void) = ^(){
        @CJStrongify(self)
        [self p_tryShowResultPageWithResponse:resultResponse];
    };

    // 免密相关引导
    if ([CJPaySkippwdGuideUtil shouldShowGuidePageWithResultResponse:resultResponse]) {
        [self p_hitNativeGuide];
        [CJPaySkippwdGuideUtil showGuidePageVCWithVerifyManager:self.verifyManager pushAnimated:YES completionBlock:^{
            CJ_CALL_BLOCK(guideCompletionBlock);
        }];
        return;
    }
    
    // 刷脸支付后重置密码
    if ([resultResponse.resultPageGuideInfoModel.guideType isEqual:@"reset_pwd"]) {
        [self p_hitNativeGuide];
        CJPayGuideResetPwdPopUpViewController* vc = [CJPayGuideResetPwdPopUpViewController new];
        vc.guideInfoModel = resultResponse.resultPageGuideInfoModel;
        vc.verifyManager = self.verifyManager;
        vc.completeBlock = guideCompletionBlock;
        vc.trackerBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull params) {
            @CJStrongify(self)
            [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:event params:params];
        };
        vc.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet :UIModalPresentationOverFullScreen;
        [self push:vc animated:YES];
        return;
    }

    CJ_DECLARE_ID_PROTOCOL(CJPayBioPaymentPlugin);
    // 生物识别开通引导
    if ([objectWithCJPayBioPaymentPlugin shouldShowGuideWithResultResponse:resultResponse]) {
        [self p_hitNativeGuide];
        [objectWithCJPayBioPaymentPlugin showGuidePageVCWithVerifyManager:self.verifyManager completionBlock:^{
            CJ_CALL_BLOCK(guideCompletionBlock);
        }];
        return;
    }
    
    // 到系统设置开启生物权限引导
    if ([objectWithCJPayBioPaymentPlugin shouldShowBioSystemSettingGuideWithResultResponse:resultResponse]) {
        [self p_hitNativeGuide];
        [objectWithCJPayBioPaymentPlugin showBioSystemSettingVCWithVerifyManager:self.verifyManager completionBlock:^{
            CJ_CALL_BLOCK(guideCompletionBlock);
        }];
        return;
    }
    
    // lynx引导，包括先用后付、指纹面容、极速付等
    if (Check_ValidString(resultResponse.feGuideInfoModel.url)) {
        [self stopLoading];
        if (self.configModel.isHasLaterProcess) {
            @CJWeakify(self)
            [self p_closeDouPayProcessWithClosePayDesk:NO
                                             isAnimate:NO
                                            completion:^{
                @CJStrongify(self)
                [self p_showFEGuidePageWithResponse:resultResponse
                                         completion:guideCompletionBlock];
            }];
        } else {
            [self p_showFEGuidePageWithResponse:resultResponse
                                     completion:guideCompletionBlock];
        }
        return;
    }
    
    // 不展示引导，则尝试展示结果页
    [self p_tryShowResultPageWithResponse:resultResponse];
}

- (void)p_hitNativeGuide {
    [self stopLoading];
    self.isGuidePagePush = YES;
}

- (void)p_showFEGuidePageWithResponse:(CJPayBDOrderResultResponse *)response completion:(void (^)(void))completion {
//    NSString *schema = @"aweme://lynx_popup/?surl=https%3A%2F%2Fvoffline.byted.org%2Fdownload%2Ftos%2Fschedule%2F%2Finspirecloud-cn-bytedance-internal%2Fbaas%2Fttkfzg%2Ffefdb2c84f0e5dfd_1629175656113.js";
    NSString *schema = response.feGuideInfoModel.url;
    
    // ecommerce的source参数带给财经前端
    NSDictionary *trackInfoDic = [self p_getTrackInfo];
    NSDictionary *extPayAfterUseDic = @{@"source": CJString([trackInfoDic cj_stringValueForKey:@"source"])};
    NSString *extPayAfterUseDicJsonStr = [[CJPayCommonUtil dictionaryToJson:extPayAfterUseDic] cj_URLEncode];
    if (Check_ValidString(extPayAfterUseDicJsonStr)) {
        schema = [CJPayCommonUtil appendParamsToUrl:schema
                                          params:@{@"ext_pay_after_use": extPayAfterUseDicJsonStr}];
    }
    // 存入 uid，开通生物验证方式时需要
    NSString *CJPayCJOrderResultCacheStringKey = @"CJPayGuideInfo";
    NSDictionary *dict = @{@"uid": CJString(response.userInfo.uid)};
    NSString *dataJsonStr = [dict btd_jsonStringEncoded];
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_setParams:dataJsonStr key:CJPayCJOrderResultCacheStringKey];
        [CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_setParams:self.verifyManager.lastPWD key:@"lastPWD"];
    }
    
    [CJPayDeskUtil openLynxPageBySchema:schema routeDelegate:self completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
        CJ_CALL_BLOCK(completion);
    }];
    
    [CJTracker event:@"wallet_rd_open_lynx_guide"
              params:@{@"schema": CJString(schema)}];
}

- (NSDictionary *)p_getTrackInfo {
    return [self.extParams cj_dictionaryValueForKey:@"track_info"];
}

- (void)p_tryShowResultPageWithResponse:(CJPayBDOrderResultResponse *)response {
    if (![self.verifyManager isKindOfClass:[CJPayDouPayProcessVerifyManager class]]) {
        CJPayLogAssert(NO, @"verifyManager类型异常 %@", NSStringFromClass([self.verifyManager class]));
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromRequestError];
        return;
    }

    CJPayOrderStatus orderStatus = response.tradeInfo.tradeStatus;
    
    if (self.resultPageStyle == CJPayDouPayResultPageStyleOnlyHiddenSuccess && orderStatus == CJPayOrderStatusSuccess) {
        if (self.configModel.isHasLaterProcess) { //外部关闭的场景下只关闭抖音支付流程,且不关闭loading
            @CJWeakify(self)
            [self p_closeDouPayProcessWithClosePayDesk:NO isAnimate:YES completion:^{
                @CJStrongify(self)
                [self p_callBackWithCloseActionSource:CJPayHomeVCCloseActionSourceFromQuery data:nil];
            }];
        } else {
            [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
        }
        return;
    }
    
    [self stopLoading];
    BOOL isLoadingNeedShowPayResult = [CJPayLoadingManager defaultService].loadingStyleInfo.isNeedShowPayResult;
    CGFloat closeDelayTime = orderStatus == CJPayOrderStatusSuccess && isLoadingNeedShowPayResult ? 0.6 : 0;
    if ([response closeAfterTime] == 0 || self.resultPageStyle == CJPayDouPayResultPageStyleHiddenAll) {
        // 不需要结果页面
        if (response.feGuideInfoModel) {
            self.isFeGuide = YES;
        }
        if (response.tradeInfo.tradeStatus == CJPayOrderStatusProcess && [response.processingGuidePopupInfo isValid]) {
            [self p_showProcessPopupInfoWithPopupInfo:response.processingGuidePopupInfo];
        } else {
            [self closeActionAfterTime:closeDelayTime closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
        }
        return;
    }
    
    if (orderStatus == CJPayOrderStatusSuccess && [response.resultConfig.showStyle isEqualToString:@"1"] && response.resultPageInfo) { //展示全屏结果页
        CJPayResultPageModel *model = [[CJPayResultPageModel alloc] init];
        model.resultPageInfo = response.resultPageInfo;
        model.amount = response.tradeInfo.payAmount;
        model.orderResponse = [model toDictionary] ?: @{};
        CJPayFullResultPageViewController *resultPage = [[CJPayFullResultPageViewController alloc] initWithCJResultModel:model trackerParams:@{}];
        @weakify(self);
        resultPage.closeCompletion = ^{
            @strongify(self);
            [self p_callbackWithResultCode:CJPayDouPayResultCodeOrderSuccess errorMsg:@"支付成功"];
        };
        
        if (![[self topVC].navigationController isKindOfClass:[CJPayNavigationController class]]) {
            [self p_callbackWithResultCode:CJPayDouPayResultCodeOrderSuccess errorMsg:@"支付成功"];
            return;
        }
        
        UIViewController *topVC = [self topVC] ?: [UIViewController cj_topViewController];
        if ([topVC.navigationController isKindOfClass:[CJPayNavigationController class]] && topVC.navigationController == self.navigationController) {
            [self.navigationController pushViewControllerSingleTop:resultPage animated:YES completion:nil];
        } else {
            [self push:resultPage animated:YES];
        }
    } else {
        CJPayBDResultPageViewController *resultPage = [CJPayBDResultPageViewController new];
        resultPage.resultResponse = response;
        @CJWeakify(self)
        resultPage.cjBackBlock = ^{
            @CJStrongify(self)
            [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
        };
        resultPage.verifyManager = self.verifyManager;
        resultPage.animationType = HalfVCEntranceTypeNone;
        resultPage.isShowNewStyle = [CJPayLoadingManager defaultService].loadingStyleInfo.isNeedShowPayResult;
        resultPage.isPaymentForOuterApp = self.configModel.isFromOuterApp;
        
        UIViewController *topVC = [self topVC] ?: [UIViewController cj_topViewController];
        if (topVC.navigationController && [topVC.navigationController isKindOfClass:[CJPayNavigationController class]] && topVC.navigationController == self.navigationController) { // 有可能找不到
            [(CJPayNavigationController *)topVC.navigationController pushViewControllerSingleTop:resultPage
                                                                                        animated:NO
                                                                                      completion:nil];
        } else {
            [self push:resultPage animated:YES];
        }
    }
}

- (void)p_showProcessPopupInfoWithPopupInfo:(CJPayProcessingGuidePopupInfo *)popupInfo {
    CJPayRetainInfoModel *retainInfoModel = [CJPayRetainInfoModel new];
    retainInfoModel.title = popupInfo.title;
    retainInfoModel.voucherContent = popupInfo.desc;
    retainInfoModel.topButtonText = popupInfo.btnText;
    @CJWeakify(self)
    retainInfoModel.closeCompletionBlock = ^{
        @CJStrongify(self)
        [self.verifyManager.verifyManagerQueen trackCashierWithEventName:@"wallet_cashier_paying_pop_click" params:@{
            @"button_name":@"关闭",
        }];
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
    };
    
    retainInfoModel.topButtonBlock = ^{
        @CJStrongify(self)
        [self.verifyManager.verifyManagerQueen trackCashierWithEventName:@"wallet_cashier_paying_pop_click" params:@{
            @"button_name": CJString(popupInfo.btnText),
        }];
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
    };
    CJPayPayCancelRetainViewController *popupVC = [[CJPayPayCancelRetainViewController alloc] initWithRetainInfoModel:retainInfoModel];
    popupVC.isDescTextAlignmentLeft = YES;
    popupVC.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet :UIModalPresentationOverFullScreen;
    
    [self.verifyManager.verifyManagerQueen trackCashierWithEventName:@"wallet_cashier_paying_pop_imp" params:nil];
    
    [self p_closeDouPayProcessWithClosePayDesk:YES isAnimate:YES completion:^{
        @CJStrongify(self)
        [self push:popupVC animated:YES];
    }];
}


- (CJPayVerifyType)firstVerifyType {
    if (self.configModel.isFrontPasswordVerify && !self.verifyManager.isNotSufficient) {
        return CJPayVerifyTypePassword;
    }
    
    if (self.createOrderResponse.needResignCard) {
        return CJPayVerifyTypeSignCard;
    }
    return [self.verifyManager getVerifyTypeWithPwdCheckWay:self.createOrderResponse.userInfo.pwdCheckWay];
}

- (void)push:(nonnull UIViewController *)vc animated:(BOOL)animated {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if (!self.navigationController || topVC.navigationController != self.navigationController) {
        [self p_presentVC:vc animated:animated];
    } else {
        CJPayNavigationController *navi = self.navigationController;
        if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            [self p_handlePushHalfViewController:(CJPayHalfPageBaseViewController *)vc];
        }
        if ([topVC isKindOfClass:CJPayPopUpBaseViewController.class]) {
            if ([vc isKindOfClass:CJPayPopUpBaseViewController.class]) {
                [(CJPayPopUpBaseViewController *)vc showMask:NO];
            }
            [navi pushViewControllerSingleTop:vc animated:animated completion:nil];
            return;
        }
        if (self.isGuidePagePush) {
            [navi pushViewControllerSingleTop:vc animated:animated completion:nil];
        } else {
            [navi pushViewController:vc animated:animated];
        }
    }
}

// 新起导航栈present页面
- (void)p_presentVC:(UIViewController *)vc animated:(BOOL)animated {
    UIViewController *topVC = [UIViewController cj_topViewController];
    BOOL newNavUseMask = self.configModel.cashierType == CJPayCashierTypeFullPage;
    [[CJPayLoadingManager defaultService] stopLoading]; // 关闭电商拉起的Loading
    
    if ([vc isKindOfClass:[CJPayHalfPageBaseViewController class]]) {
        CJPayHalfPageBaseViewController *halfVC = (CJPayHalfPageBaseViewController *)vc;
        halfVC = [self p_handlePresentHalfViewController:halfVC];
        self.navigationController = [halfVC presentWithNavigationControllerFrom:topVC useMask:newNavUseMask completion:nil];
    } else if ([vc isKindOfClass:CJPayBaseViewController.class]){
        if ([vc isKindOfClass:CJPayPopUpBaseViewController.class]) {
            newNavUseMask = YES;
        }
        CJPayBaseViewController *cjpayVC = (CJPayBaseViewController *)vc;
        self.navigationController = [cjpayVC presentWithNavigationControllerFrom:topVC useMask:newNavUseMask completion:nil];
    } else {
        CJPayNavigationController *nav = [CJPayNavigationController instanceForRootVC:vc];
        nav.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet :UIModalPresentationOverFullScreen;
        nav.view.backgroundColor = UIColor.clearColor;
        self.navigationController = nav;
        [topVC presentViewController:nav animated:animated completion:nil];
    }
    
    HalfVCEntranceType animateType = HalfVCEntranceTypeFromBottom;
    if (self.configModel.cashierType == CJPayCashierTypeHalfPage) {
        animateType = HalfVCEntranceTypeFromRight;
    }
    self.navigationController.dismissAnimatedType = animateType == HalfVCEntranceTypeFromRight ? CJPayDismissAnimatedTypeFromRight : CJPayDismissAnimatedTypeFromBottom;
    self.navigationController.useNewHalfPageTransAnimation = [self.createOrderResponse.payInfo isDynamicLayout]; // 动态化布局时，半屏<->半屏的转场采用新动画样式
}

//present半屏页面时需根据前置页面类型（payDeskType）决定转场动画
- (CJPayHalfPageBaseViewController *)p_handlePresentHalfViewController:(CJPayHalfPageBaseViewController *)halfVC {
    // 如果要present的半屏页面不希望被修改转场参数，则直接返回
    if (halfVC.forceOriginPresentAnimation) {
        return halfVC;
    }
    
    [halfVC showMask:NO];
    if (self.configModel.cashierType == CJPayCashierTypeHalfPage) {
        halfVC.animationType = HalfVCEntranceTypeFromRight;
    } else {
        halfVC.animationType = HalfVCEntranceTypeFromBottom;
        [halfVC useCloseBackBtn];
    }
    return halfVC;
}

//push半屏页面时需根据topVC页面类型决定转场动画
- (CJPayHalfPageBaseViewController *)p_handlePushHalfViewController:(CJPayHalfPageBaseViewController *)halfVC
{
    [halfVC showMask:NO];
    if ([self p_topVCIsHalfVC]) {
        halfVC.animationType = HalfVCEntranceTypeFromRight;
    } else {
        halfVC.animationType = HalfVCEntranceTypeFromBottom;
        [halfVC useCloseBackBtn];
    }
    return halfVC;
}

- (BOOL)p_topVCIsHalfVC {
    UIViewController *lastVC = [UIViewController cj_topViewController].navigationController.viewControllers.lastObject;
    if ([lastVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        return YES;
    }
    return NO;
}

- (BOOL)receiveDataBus:(CJPayHomeVCEvent)eventType obj:(nonnull id)object {
    switch (eventType) {
        case CJPayHomeVCEventWakeItemFail:
            //当前标准化流程是否有页面：有：不做处理； 无：回调结果
            [self p_openVerifyExceptionWithItem:object];
            break;
        case CJPayHomeVCEventCancelVerify:
            [self p_cancelVerifyWithType:[object integerValue]];
            break;
        case CJPayHomeVCEventNotifySufficient:
        case CJPayHomeVCEventCombinePayLimit:
            [self p_defaultToastWithConfirmResponse:object];
            break;
        case CJPayHomeVCEventPayMethodDisabled:
            [self p_handlePayMethodDisabled:object];
            break;
        case CJPayHomeVCEventDiscountNotAvailable:
            [self p_handleDiscountNotAvailable:object];
            break;
        case CJPayHomeVCEventSignCardFailed:
            [self p_signCardAndPayFailedWithMessage:object];
            break;
        case CJPayHomeVCEventBindCardSuccessPayFail:
            [self p_bindCardSuccessAndPayFail];
            break;
        case CJPayHomeVCEventConfirmRequestError:
            [self p_confirmError];
            break;
        case CJPayHomeVCEventBindCardFailed:
            [self p_bindCardFailedWithActionSource:[object integerValue]];
            break;
        case CJPayHomeVCEventBindCardNoPwdCancel: {
            @CJWeakify(self)
            [self p_closeDouPayProcessWithClosePayDesk:NO isAnimate:YES completion:^{
                @CJStrongify(self)
                [self p_callbackWithResultCode:CJPayDouPayResultCodeCancel errorMsg:@"退出补设密流程"];
            }];
            break;
        }
        case CJPayHomeVCEventBindCardPay: {
            if ([object isKindOfClass:NSDictionary.class]) {
                NSDictionary *params = (NSDictionary *)object;
                if (Check_ValidDictionary(params)) {
                    self.bindCardExtParams = params;
                }
            }
            [self p_bindCardAndPay];
            [self p_trackBindCardAndPayWithSource:@"O项目密码切卡页绑卡并支付"];
            break;
        }
        default:
            break;
    }
    return YES;
}

- (void)p_bindCardFailedWithActionSource:(CJPayHomeVCCloseActionSource)source {
    if ([self p_isInCJPay]) { //有财经页面，不给外部回调
        return;
    }
    @CJWeakify(self)
    [self p_closeDouPayProcessWithClosePayDesk:NO isAnimate:YES completion:^{
        @CJStrongify(self)
        [self p_callBackWithCloseActionSource:source data:@"绑卡失败"];
    }];
}

- (void)p_defaultToastWithConfirmResponse:(id)response {
    UIViewController *topVC = [self topVC];
    if (![response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        [CJToast toastText:CJPayNoNetworkMessage inWindow:topVC.cj_window];
        return;
    }
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
    [CJToast toastText:confirmResponse.msg inWindow:topVC.cj_window];
    [self p_confirmError];
}

- (void)p_confirmError {
    if ([self p_isInCJPay]) {
        return;
    }
    [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:[NSString stringWithFormat:@"确认支付接口失败"]];
}

- (void)p_bindCardSuccessAndPayFail {
    // 新验密页->选卡页进行绑卡，绑卡成功但支付失败时，电商关闭支付流程进入继续支付页，聚合回到首页
    if ([self p_isPasswordV2Style]) {
        @CJWeakify(self)
        [self p_closeDouPayProcessWithClosePayDesk:NO isAnimate:YES completion:^{
            @CJStrongify(self)
            [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:@"绑卡成功支付失败"];
        }];
        return;
    }
    
    if ([self p_isPasswordV3Style]) {
        [self.navigationController popToRootViewControllerAnimated:NO];
        if (self.configModel.refreshCreateOrderBlock) {
            @CJWeakify(self)
            self.configModel.refreshCreateOrderBlock(^(CJPayBDCreateOrderResponse * _Nullable createResponse) {
                @CJStrongify(self)
                if (![createResponse isSuccess]) {
                    [CJToast toastText:Check_ValidString(createResponse.msg) ? CJString(createResponse.msg) : CJPayNoNetworkMessage inWindow:self.topVC.cj_window];
                } else {
                    self.createResponse = createResponse;
                    UIViewController *topVC = [UIViewController cj_topViewController];
                    if ([topVC isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class]) {
                        CJPayHalfVerifyPasswordV3ViewController *passwordV3VC = (CJPayHalfVerifyPasswordV3ViewController *)topVC;
                        [passwordV3VC updateChoosedPayMethodWhenBindCardPay];
                    }
                }
            });
        }
    }
    
    if ([self p_isInCJPay]) {
        return;
    }
    
    [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:@"绑卡成功支付失败"];
}

- (BOOL)p_isPasswordListStyle { //密码页是否是6位密码样式 | 密码前置样式（仅O项目使用）
    return [self p_isPasswordV2Style] || [self p_isPasswordV3Style];
}

- (BOOL)p_isPasswordV2Style {
    return Check_ValidArray(self.createOrderResponse.payInfo.subPayTypeDisplayInfoList);
}

- (BOOL)p_isPasswordV3Style {
    return Check_ValidArray(self.createOrderResponse.payTypeInfo.subPayTypeGroupInfoList);
}

- (void)p_openVerifyExceptionWithItem:(CJPayVerifyType)verifyType {
    if ([self p_isInCJPay]) {
        return;
    }
    [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:[NSString stringWithFormat:@"打开验证页面失败"]];
}

- (BOOL)p_isInCJPay {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if (topVC.navigationController == self.navigationController && self.navigationController.viewControllers.count > 0) {
        return YES;
    }
    return NO;
}

- (void)p_cancelVerifyWithType:(CJPayVerifyType)verifyType {
    if (![self p_isInCJPay]) {
        @CJWeakify(self)
        [self p_closeDouPayProcessWithClosePayDesk:NO isAnimate:YES completion:^{
            @CJStrongify(self)
            [self p_callbackWithResultCode:CJPayDouPayResultCodeCancel errorMsg:@"取消验证"];
        }];
        return;
    }
    
    if (verifyType == CJPayVerifyTypeSignCard) { //清空记录的补签约config，恢复默认支付方式
        self.signCardShowConfig = nil;
    }
    
    if (verifyType == CJPayVerifyTypeBioPayment && [self p_topVCIsPasswordV3Style]) { // V3样式的密码切换面容取消时，需要关闭loading样式
        CJPayHalfVerifyPasswordV3ViewController *passwordV3VC = (CJPayHalfVerifyPasswordV3ViewController *)[UIViewController cj_topViewController];
        [passwordV3VC showLoadingStatus:NO];
    }
    [CJKeyboard recoverFirstResponder];
}

- (void)p_signCardAndPayFailedWithMessage:(NSString *)errorMessage {
    if (![self p_isInCJPay]) { //没有CJPay的页面的时候，回调给业务方失败
        NSString *errorMsg = [NSString stringWithFormat:@"补签约并支付失败：%@",CJString(errorMessage)];
        @CJWeakify(self)
        [self p_closeDouPayProcessWithClosePayDesk:NO isAnimate:YES completion:^{
            @CJStrongify(self)
            [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:errorMsg];
        }];
    } else {
        [CJToast toastText:errorMessage inWindow:[self topVC].cj_window];
    }
}

- (void)p_handleDiscountNotAvailable:(id)response {
    if(response && [response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
        [self p_gotoHalfPayMethodDisabledVCWithResponse:confirmResponse];
    }
}

- (void)p_handlePayMethodDisabled:(id)response {
    if (![response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        return;
    }
    
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
    
    CJPayDefaultChannelShowConfig *curSelectConfig = [self curSelectConfig];
    
    NSString *cjIdentify = curSelectConfig.cjIdentify;
    if (Check_ValidString(confirmResponse.bankCardId)) {
        cjIdentify = confirmResponse.bankCardId;
    }
    NSString *reasonType = confirmResponse.hintInfo.againReasonType;
    if ([reasonType isEqualToString:@"income_fail"]) {
        cjIdentify = @"income";
    } else if ([reasonType isEqualToString:@"income_balance_fail"]) { //业务收入转零钱成功，零钱扣款失败
        if (self.configModel.refreshCreateOrderBlock) {
            @CJWeakify(self)
            self.configModel.refreshCreateOrderBlock(^(CJPayBDCreateOrderResponse * _Nullable createResponse) {
                @CJStrongify(self)
                if ([createResponse isSuccess]) {
                    self.createResponse = createResponse;
                }
            });
        }
        cjIdentify = @"income";
    } else if ([reasonType isEqualToString:@"combine_balance_limit"]) { //组合支付零钱受限
        cjIdentify = @"balance";
    }
    if (Check_ValidString(cjIdentify) && ![self.payDisabledFundID2ReasonMap.allKeys containsObject:cjIdentify]) {
        [self.payDisabledFundID2ReasonMap cj_setObject:confirmResponse.hintInfo.statusMsg forKey:cjIdentify];
    }
    
    CJPayHintInfoStyle showStyle = confirmResponse.hintInfo.style;
    if (showStyle == CJPayHintInfoStyleNewHalf || showStyle == CJPayHintInfoStyleOldHalf || showStyle == CJPayHintInfoStyleVoucherHalf || showStyle == CJPayHintInfoStyleVoucherHalfV2) {
        [self p_gotoHalfPayMethodDisabledVCWithResponse:confirmResponse];
    } else {
        CJPayLogError(@"二次支付style数据异常：style:%@", CJString(confirmResponse.hintInfo.styleStr));
    }
}

- (void)p_gotoHalfPayMethodDisabledVCWithResponse:(CJPayOrderConfirmResponse *)confirmResponse {
    CJPayPayAgainHalfViewController *payMethodDisabledVC = [CJPayPayAgainHalfViewController new];
    payMethodDisabledVC.createOrderResponse = self.createResponse;
    payMethodDisabledVC.confirmResponse = confirmResponse;
    payMethodDisabledVC.verifyManager = self.verifyManager;
    payMethodDisabledVC.payDisabledFundID2ReasonMap = self.payDisabledFundID2ReasonMap;
    payMethodDisabledVC.delegate = self;
    payMethodDisabledVC.extParams = self.extParams;

    @CJWeakify(self);
    payMethodDisabledVC.dismissCompletionBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull recommendConfig) {
        @CJStrongify(self);
        [self p_callBackWithCloseActionSource:CJPayHomeVCCloseActionSourceFromInsufficientBalance data:recommendConfig];
    };
    
    UIViewController *topVC = [self topVC];
    if ([topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        [self p_handlePushHalfViewController:payMethodDisabledVC];
        BOOL needAnimated = YES;
        if ([topVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            CJPayHalfPageBaseViewController *halfTopVC = (CJPayHalfPageBaseViewController *)topVC;
            if ([halfTopVC containerHeight] == [payMethodDisabledVC containerHeight]) {
                needAnimated = NO;
            }
        }
        [self p_pushSingleTop:payMethodDisabledVC animated:needAnimated];
    } else {
        [self push:payMethodDisabledVC animated:NO];
    }
}

- (void)p_pushSingleTop:(UIViewController *)vc animated:(BOOL)animated {
    if (!self.navigationController || [UIViewController cj_topViewController].navigationController != self.navigationController) {
        [self p_presentVC:vc animated:animated];
    } else {
        [self.navigationController pushViewControllerSingleTop:vc animated:animated completion:nil];
    }
}

- (nonnull UIViewController *)topVC {
    return [UIViewController cj_topViewController];
}

- (NSDictionary *)getPerformanceInfo {
    int noPasswordPay = self.verifyManager.lastVerifyType == CJPayVerifyTypeSkipPwd ? 1 : 0;
    int newBindCard = self.currentShowConfig.type == BDPayChannelTypeAddBankCard ? 1 : 0;
    
    NSMutableDictionary *sdkPerformance = [NSMutableDictionary new];
    
    NSDictionary *performanceCommonParams = @{
        @"no_password_pay": @(noPasswordPay),
        @"new_bind_card": @(newBindCard)
    };
    
    NSMutableDictionary *performaceStages = [NSMutableDictionary new];
    [performaceStages cj_setObject:@(self.enterTimestamp) forKey:@"C_ORDER_TTPAY_START"];
    [performaceStages addEntriesFromDictionary:[self.verifyManager getPerformanceInfo]];
    
    [sdkPerformance cj_setObject:performaceStages forKey:@"performace_stages"];
    [sdkPerformance cj_setObject:performanceCommonParams forKey:@"performance_common_params"];
    
    return [sdkPerformance copy];
}

#pragma mark - Getter

- (CJPayDouPayProcessVerifyManager *)verifyManager {
    if (!_verifyManager) {
        _verifyManager = [CJPayDouPayProcessVerifyManager managerWith:self];
        _verifyManager.changePayMethodDelegate = self;
        _verifyManager.isStandardDouPayProcess = YES;
    }
    return _verifyManager;
}

- (CJPayDouPayProcessVerifyManagerQueen *)verifyManagerQueen {
    if (!_verifyManagerQueen) {
        _verifyManagerQueen = [CJPayDouPayProcessVerifyManagerQueen new];
        [_verifyManagerQueen bindManager:self.verifyManager];
    }
    return _verifyManagerQueen;
}

- (NSMutableDictionary *)payDisabledFundID2ReasonMap {
    if (!_payDisabledFundID2ReasonMap) {
        _payDisabledFundID2ReasonMap = [NSMutableDictionary dictionary];
    }
    return _payDisabledFundID2ReasonMap;
}

#pragma mark - CJPayHomeVCProtocol

- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
    @CJWeakify(self)
//    if (self.cashierScene == CJPayCashierScenePreStandard && source == CJPayHomeVCCloseActionSourceFromQuery) { //非电商场景出现结果页的直接回调，要提前给Lynx回调便于隐藏首页
        //在lynx引导情况下，需要多等0.1s再回调，不然会有转场冲突
    if (source == CJPayHomeVCCloseActionSourceFromQuery && self.configModel.isCallBackAdvance) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((self.isFeGuide ? 0.1 : 0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @CJStrongify(self);
            [self p_callBackWithCloseActionSource:source data:nil];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_closeDouPayProcessWithClosePayDesk:YES isAnimate:YES completion:nil];
            });
        });
       
        return;
    }
   
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        [self p_closeDouPayProcessWithClosePayDesk:YES isAnimate:YES completion:^{
            [self p_callBackWithCloseActionSource:source data:nil];
        }];
    });
    
}

- (void)p_callBackWithCloseActionSource:(CJPayHomeVCCloseActionSource)source data:(id)data {
    switch (source) {
        case CJPayHomeVCCloseActionSourceFromCloseAction:
            [self p_callbackWithResultCode:CJPayDouPayResultCodeClose errorMsg:@"关闭收银台"];
            break;
        case CJPayHomeVCCloseActionSourceFromBack:
            [self p_callbackWithResultCode:CJPayDouPayResultCodeCancel errorMsg: @"流程退出"];
            break;
        case CJPayHomeVCCloseActionSourceFromBindAndPayFail:
            [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:@"绑卡并支付失败"];
            break;
        case CJPayHomeVCCloseActionSourceFromInsufficientBalance:
            [self p_callbackWithResultCode:CJPayDouPayResultCodeInsufficientBalance errorMsg:[self p_payDisableReasonStrWithData:data]];
            break;
        case CJPayHomeVCCloseActionSourceFromRequestError:
            [self p_callbackWithResultCode:CJPayDouPayResultCodeFail errorMsg:@"接口错误"];
            break;
//        case CJPayHomeVCCloseActionSourceFromClosePayDeskShowBizError:
//            [self p_closePayDeskAndShowErrorTips];
//            break;
        default: {
            CJPayDouPayResultCode resultCode = CJPayDouPayResultCodeOrderUnknown;
            CJPayBDOrderResultResponse *response = self.verifyManager.resResponse;
            NSString *errorDesc = @"未知错误";
            if (!response.tradeInfo) {
                [self p_callbackWithResultCode:CJPayDouPayResultCodeOrderUnknown errorMsg:errorDesc];
                return;
            }
            switch (response.tradeInfo.tradeStatus) {
                case CJPayOrderStatusProcess:
                    resultCode = CJPayDouPayResultCodeOrderProcess;
                    errorDesc = @"支付处理中";
                    break;
                case CJPayOrderStatusFail:
                    resultCode = CJPayDouPayResultCodeOrderFail;
                    errorDesc = @"支付失败";
                    break;
                case CJPayOrderStatusTimeout:
                    resultCode = CJPayDouPayResultCodeOrderTimeout;
                    errorDesc = @"支付超时";
                    break;
                case CJPayOrderStatusSuccess:
                    resultCode = CJPayDouPayResultCodeOrderSuccess;
                    errorDesc = @"支付成功";
                    break;
                default:
                    break;
            }
            
            [self p_callbackWithResultCode:resultCode errorMsg:errorDesc extParams:@{
                kDouPayResultTradeStatusStrKey : CJString(response.tradeInfo.tradeStatusString),
                kDouPayResultBDProcessInfoStrKey : CJString([self.verifyManager.confirmResponse.processInfoDic cj_toStr])
            }];
            break;
        }
    }
}

// 构造不可用支付方式回调数据
- (NSString *)p_payDisableReasonStrWithData:(id)data {
    __block NSMutableArray *list = [NSMutableArray array];
    [self.payDisabledFundID2ReasonMap enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        NSDictionary *cardInfo = @{
            @"card_id": CJString(key),
            @"msg": CJString(obj)
        };
        [list addObject:cardInfo];
    }];
    
    NSString *recommendCardId = @"";
    if ([data isKindOfClass:CJPayDefaultChannelShowConfig.class]) {
        recommendCardId = ((CJPayDefaultChannelShowConfig *)data).cjIdentify;
    }
    
    NSDictionary *dict = @{
        @"current_card_list" : list ?: @[],
        @"recommend_card_id" : CJString(recommendCardId)
    };
    return  [dict cj_toStr];
}

// 关闭标准化流程
- (void)p_closeDouPayProcessWithClosePayDesk:(BOOL)isClosePayDesk isAnimate:(BOOL)isAnimate completion:(void (^)(void))completion {
    if (isClosePayDesk) { //关闭收银台的时候动画强制设为向下
        self.navigationController.dismissAnimatedType = CJPayDismissAnimatedTypeFromBottom;
    }
    if ([self.configModel.homeVC isKindOfClass:UIViewController.class] && isClosePayDesk) {
        UIViewController *homeVC = (UIViewController *)self.configModel.homeVC;
        if (homeVC.navigationController.presentingViewController) {
            [homeVC.navigationController.presentingViewController dismissViewControllerAnimated:isAnimate completion:completion];
        } else if (homeVC.navigationController) {
            [homeVC.navigationController dismissViewControllerAnimated:isAnimate completion:completion];
        } else {
            [homeVC dismissViewControllerAnimated:isAnimate completion:completion];
        }
    } else {
        if (self.navigationController.presentingViewController) {
            [self.navigationController.presentingViewController dismissViewControllerAnimated:isAnimate completion:completion]; //抖音支付标准化流程内部自己关闭
        } else if (self.navigationController) {
            [self.navigationController dismissViewControllerAnimated:isAnimate completion:completion];
        } else {
            CJ_CALL_BLOCK(completion);
        }
    }
}

- (void)p_callbackWithResultCode:(CJPayDouPayResultCode)resultCode errorMsg:(NSString *)msg {
    [self p_callbackWithResultCode:resultCode errorMsg:msg extParams:nil];
}

- (void)p_callbackWithResultCode:(CJPayDouPayResultCode)resultCode errorMsg:(NSString *)errorMsg extParams:(NSDictionary *)extParams {
    CJPayDouPayProcessResultModel *resultModel = [CJPayDouPayProcessResultModel new];
    resultModel.resultCode = resultCode;
    resultModel.errorDesc = errorMsg;
    resultModel.extParams = extParams;
    CJ_CALL_BLOCK(self.completionBlock, resultModel);
}

#pragma mark - CJPayChooseDyPayMethodDelegate
- (void)signPayWithPayContext:(CJPayFrontCashierContext *)payContext loadingView:(UIView *)loadingView {
    [self.verifyManager exitBindCardStatus];
    self.signCardShowConfig = payContext.defaultConfig;
    self.verifyManager.signCardStartLoadingBlock = ^{
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
    };
    self.verifyManager.signCardStopLoadingBlock = ^{
        [[CJPayLoadingManager defaultService] stopLoading];
    };
    [self.verifyManager wakeSpecificType:CJPayVerifyTypeSignCard orderRes:self.createOrderResponse event:nil];
}

- (void)changePayMethod:(CJPayFrontCashierContext *)payContext loadingView:(UIView *)loadingView {
    CJPayChannelType channelType = payContext.defaultConfig.type;
    if (channelType == BDPayChannelTypeAddBankCard) {
        // 选中绑卡时单独存储payContext，与其他支付方式区分开
        self.bindCardShowConfig = payContext.defaultConfig;
        self.bindCardExtParams = payContext.extParams;
        @CJWeakify(loadingView)
        self.verifyManager.bindCardStartLoadingBlock = ^{
            @CJStrongify(loadingView)
            if ([loadingView respondsToSelector:@selector(startLoading)]) {
                [loadingView performSelector:@selector(startLoading)];
            };
        };
        
        self.verifyManager.bindCardStopLoadingBlock = ^{
            @CJStrongify(loadingView)
            if ([loadingView respondsToSelector:@selector(stopLoading)]) {
                [loadingView performSelector:@selector(stopLoading)];
            };
        };
        
        [self p_bindCardAndPay];
        [self p_trackBindCardAndPayWithSource:@"6位密码切卡页绑卡并支付"];
        return;
    }
    
    if ([payContext.defaultConfig isNeedReSigning]) { //六位密码支持补签约
        self.signCardShowConfig = payContext.defaultConfig;
        return;
    }
    self.signCardShowConfig = nil;
    self.bindCardShowConfig = nil;
    [self.verifyManager exitBindCardStatus];
    
    // 若有更改过支付方式，则进行记录
    BOOL hasChangePayMethod = ![self.currentShowConfig isEqual:payContext.defaultConfig] || payContext.hasChangePayMethod;
    if (hasChangePayMethod && !self.verifyManager.hasChangeSelectConfigInVerify) {
        self.verifyManager.hasChangeSelectConfigInVerify = YES;
    }
    // 修改收银台首页记录的当前支付方式
    [self p_updatePayMethodWithContext:payContext];
}

- (NSDictionary *)payContextExtParams {
    return self.configModel.extParams ?: [NSDictionary new];
}

- (void)p_updatePayMethodWithContext:(CJPayFrontCashierContext *)context {
    self.createResponse = context.orderResponse;
    self.currentShowConfig = context.defaultConfig;
    self.extParams = context.extParams;
}

- (void)setCurrentShowConfig:(CJPayDefaultChannelShowConfig *)currentShowConfig {
    _currentShowConfig = currentShowConfig;
    [self p_updateCreateResponsePayInfoWithShowConfig:currentShowConfig];
}

- (void)setCreateResponse:(CJPayBDCreateOrderResponse *)createResponse {
    _createResponse = createResponse;
    [self p_updateCreateResponsePayInfoWithShowConfig:self.currentShowConfig];
}

- (void)p_updateCreateResponsePayInfoWithShowConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    if (!self.configModel.isFrontPasswordVerify) {
        return;
    }
    CJPayInfo *payInfo = self.createResponse.payInfo ?: [CJPayInfo new];
    payInfo.retainInfo = self.createResponse.retainInfo;
    payInfo.retainInfoV2 = self.createResponse.retainInfoV2;
    payInfo.voucherNoList = @[];
    self.createResponse.payInfo = payInfo;
}


#pragma mark - CJPayDeskRouteDelegate

- (void)routeToVC:(nonnull UIViewController *)vc animated:(BOOL)animated
{
    [self push:vc animated:animated];
}

#pragma mark - CJPayPayAgainDelegate

- (void)payWithContext:(CJPayFrontCashierContext *)context loadingView:(UIView *)loadingView {
    self.verifyManager.isNotSufficient = YES;
    [self p_updatePayMethodWithContext:context];
    CJPayChannelType channelType = context.defaultConfig.type;
    
    if (channelType == BDPayChannelTypeBankCard || channelType == BDPayChannelTypeBalance || channelType == BDPayChannelTypeFundPay) {
        @CJWeakify(self);
        @CJWeakify(loadingView)
        self.verifyManager.signCardStartLoadingBlock = ^{
            @CJStrongify(self)
            @CJStrongify(loadingView)
            if ([loadingView respondsToSelector:@selector(startLoading)]) {
                [loadingView performSelector:@selector(startLoading)];
            } else {
                @CJStartLoading(self)
            }
        };
        
        self.verifyManager.signCardStopLoadingBlock = ^{
            @CJStrongify(self)
            @CJStrongify(loadingView)
            if ([loadingView respondsToSelector:@selector(stopLoading)]) {
                [loadingView performSelector:@selector(stopLoading)];
            } else {
                @CJStopLoading(self)
            }
        };
        [self p_pay];
        [self p_trackNormalPayWithSource:@"二次支付普通支付"];
        return;
    }
    
    if (channelType == BDPayChannelTypeCreditPay) {
        [self p_activeCreditAndPayWithTrackSourceStr:@"二次支付月付支付"];
        return;
    }
    
    if (channelType == BDPayChannelTypeAddBankCard) {
        @CJWeakify(loadingView)
        self.verifyManager.bindCardStartLoadingBlock = ^{
            @CJStrongify(loadingView)
            if ([loadingView respondsToSelector:@selector(startLoading)]) {
                [loadingView performSelector:@selector(startLoading)];
            };
        };
        
        self.verifyManager.bindCardStopLoadingBlock = ^{
            @CJStrongify(loadingView)
            if ([loadingView respondsToSelector:@selector(stopLoading)]) {
                [loadingView performSelector:@selector(stopLoading)];
            };
        };
        
        [self p_bindCardAndPay];
        [self p_trackBindCardAndPayWithSource:@"二次支付绑卡并支付"];
        return;
    }
    
    CJPayLogAssert(NO, @"二次支付无法处理：%lu", (unsigned long)channelType);
    [self p_pay];
    [self p_trackNormalPayWithSource:@"二次支付兜底普通支付"];
}

#pragma mark - CJPayBaseLoadingDelegate

- (void)startLoading {
    [self p_tryShowV3LoadingStatus:YES];
    if ([CJPayLoadingManager defaultService].isDouyinStyleLoading) {
        // 免密验证时，沿用当前正在进行的loading而不需要新开
        if ([CJPayLoadingManager defaultService].isLoading && [self.verifyManager.response.userInfo.pwdCheckWay isEqualToString:@"3"]) {
            return;
        }
        [self p_securityLoading];
        return;
    }
    UIViewController *topVC = [UIViewController cj_topViewController];
    NSString *loadingTitle = [self p_loadingTitleWithChannelType:self.currentShowConfig.type userInfo:self.verifyManager.response.userInfo];
    if (self.navigationController && topVC.navigationController == self.navigationController) {
        if ([topVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            [self p_startLoadingWithHalfPageVC:topVC isSecurityLoading:NO];
        }  else {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading title:loadingTitle];
        }
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading title:loadingTitle];
    }
}

- (void)p_tryShowV3LoadingStatus:(BOOL)isLoading {
    if (![self p_topVCIsPasswordV3Style]) {
        return;
    }
    CJPayHalfVerifyPasswordV3ViewController *passwordV3VC = (CJPayHalfVerifyPasswordV3ViewController *)[UIViewController cj_topViewController];
    [passwordV3VC showLoadingStatus:isLoading];
    passwordV3VC.navigationBar.backBtn.hidden = isLoading;
}

- (NSString *)p_loadingTitleWithChannelType:(CJPayChannelType)channelType userInfo:(CJPayUserInfo *)userInfo {
    NSString *pwdCheckWay = self.verifyManager.response.userInfo.pwdCheckWay;
    
    BOOL isSkipPwdPay = [pwdCheckWay isEqualToString:@"3"];
    if (isSkipPwdPay && channelType != BDPayChannelTypeAddBankCard) {
        return [self p_getLoadingText];
    }
    
    BOOL isCreditToken = [pwdCheckWay isEqualToString:@"6"];
    if (isCreditToken && channelType == BDPayChannelTypeCreditPay) {
        return CJPayLocalizedStr(@"抖音月付支付中");
    }

    return @"抖音支付";
}

- (BOOL)p_topVCIsPasswordV3Style {
    UIViewController *topVC = [UIViewController cj_topViewController];
    return [topVC isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class];
}

- (void)p_startLoadingWithHalfPageVC:(UIViewController *)vc isSecurityLoading:(BOOL)isSecurityLoading {
    if ([self p_topVCIsPasswordV3Style]) {
        CJPayHalfVerifyPasswordV3ViewController *vc = (CJPayHalfVerifyPasswordV3ViewController *)[UIViewController cj_topViewController];
        BOOL isPasswordV3VerifyHeight = vc.passwordContentView.isPasswordVerifyStyle;
        if (!isPasswordV3VerifyHeight || ([self.createOrderResponse.deskConfig isFastEnterBindCard] && self.bindCardShowConfig.type == BDPayChannelTypeAddBankCard)) {
            if (isSecurityLoading) {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading isNeedValidateTimer:YES];
            } else {
                NSString *loadingTitle = [self p_loadingTitleWithChannelType:self.currentShowConfig.type userInfo:self.verifyManager.response.userInfo];
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading title:loadingTitle];
            }
        } else {
            if (isSecurityLoading) {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading isNeedValidateTimer:YES];
            } else {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading];
            }
        }
        return;
    }
    if (isSecurityLoading) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading isNeedValidateTimer:YES];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading];
    }
}

- (NSString *)p_getLoadingText {
    NSString *loadingText = CJPayLocalizedStr(@"免密支付中");
    NSUInteger voucherType = [self.createOrderResponse.payInfo.voucherType integerValue];
    BOOL hasRandomDiscount = self.createOrderResponse.payInfo.hasRandomDiscount;
    // 如果有营销且没有随机立减则显示具体金额
    if (voucherType != CJPayVoucherTypeNone && voucherType != CJPayVoucherTypeNonePayAfterUse && !hasRandomDiscount) {
        loadingText = CJConcatStr(CJPayLocalizedStr(@"免密支付"), @" ¥", CJString(self.createOrderResponse.payInfo.realTradeAmount));
    }
    return loadingText;
}

- (void)p_securityLoading {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if (topVC.navigationController == self.navigationController && [topVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [self p_startLoadingWithHalfPageVC:topVC isSecurityLoading:YES];
    } else {
        if (self.verifyManager.isBindCardAndPay) {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleBindCardLoading isNeedValidateTimer:YES];
        } else {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading isNeedValidateTimer:YES];
        }
    }
    self.startloadingTime = CFAbsoluteTimeGetCurrent();
}

- (void)stopLoading {
    [self p_tryShowV3LoadingStatus:NO];
    [[CJPayLoadingManager defaultService] stopLoading];
}

@end
