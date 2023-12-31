//
//  CJPayECController.m
//  Pods
//
//  Created by wangxiaohong on 2020/11/15.
//

#import "CJPayECController.h"

#import "CJPayECVerifyManager.h"
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
#import "CJPayPayAgainPopUpViewController.h"
#import "CJPayKVContext.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPayECErrorTipsViewController.h"
#import "CJPayPayCancelRetainViewController.h"
#import "CJPayTouchIdManager.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayRequestParam.h"
#import "CJPaySafeUtil.h"
#import "CJPayBioManager.h"
#import "CJPayCashdeskEnableBioPayRequest.h"
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
#import "CJPaySkipPwdConfirmHalfPageViewController.h"
#import "CJPayLynxShowInfo.h"
#import "CJPayPayCancelLynxRetainViewController.h"
#import "CJPayUnlockBankCardRequest.h"

// 前置lynx页面类型
typedef NS_ENUM(NSInteger, CJPayComeFromDeskType) {
    CJPayComeFromDeskTypeFullPage = 0,   // 前置lynx页面为全屏
    CJPayComeFromDeskTypeHalfPage = 1,   // 前置lynx页面为半屏
};


@interface CJPayECController()<CJPayHomeVCProtocol, CJPayPayAgainDelegate, CJPayChooseDyPayMethodDelegate>

//@property (nonatomic, strong) CJPayFrontCashierContext *payContext;
@property (nonatomic, copy, nullable) void (^completion)(CJPayManagerResultType, NSString *);

@property (nonatomic, strong) CJPayNavigationController *navigationController;

@property (nonatomic, strong) NSMutableDictionary *payDisabledFundID2ReasonMap;

@property (nonatomic, assign, readonly) BOOL isNotSufficientNewStyle;

@property (nonatomic, assign) BOOL isCreditPayActiveSuccess;

@property (nonatomic, assign) CJPayCreditPayServiceResultType creditPayActivationResultType;
// 安全感loading耗时埋点
@property (nonatomic, assign) CFAbsoluteTime startloadingTime;
@property (nonatomic, assign) CFAbsoluteTime stoploadingTime;
@property (nonatomic, assign) NSTimeInterval enterTimestamp;

@property (nonatomic, strong) CJPayFrontCashierContext *bindcardPayContext; //支付中选择绑卡时，单独存储绑卡支付方式
@property (nonatomic, strong) CJPayFrontCashierContext *signCardPayContext; //支付中选择补签约卡时，单独存储补签约支付方式

@property (nonatomic, assign) CJPayComeFromDeskType comeFromDeskType; //前置页面类型，用于决定非电商场景SDK半屏的转场动画
@property (nonatomic, assign) CJPayCashierScene cashierScene; //标识前置收银台使用场景

@property (nonatomic, assign) BOOL isShowResultPage; //标识是否需要展示支付结果页
@property (nonatomic, assign) BOOL isHasCallBack; //是否已经回调过，避免重复回调
@property (nonatomic, assign) BOOL isPreStandFeGuide;
@end

@implementation CJPayECController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _verifyManager = [CJPayECVerifyManager managerWith:self];
        _isCreditPayActiveSuccess = NO;
        _isPreStandFeGuide = NO;
    }
    return self;
}

/**
 "sdk_performance":{
   "performance_common_params": {
     "no_password_pay": 1,
     "new_bind_card": 0
   },
   "performace_stages": {
      "C_ORDER_TTPAY_START": 1669791504485,
      "C_ORDER_TTPAY_CONFIRM_PAY_START": 1669791504485,
      "C_ORDER_TTPAY_CHECK_PAY_START": 1669791504485,
      "C_ORDER_TTPAY_END": 1669791504485,
   },
 }
 */
- (NSDictionary *)getPerformanceInfo {
    int noPasswordPay = self.verifyManager.lastVerifyType == CJPayVerifyTypeSkipPwd ? 1 : 0;
    int newBindCard = self.payContext.defaultConfig.type == BDPayChannelTypeAddBankCard ? 1 : 0;
    
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
//    return @{@"sdk_performance" : sdkPerformance};
}

- (void)startPaymentWithParams:(NSDictionary *)params completion:(void (^)(CJPayManagerResultType type, NSString *errorMsg))completion
{
    [self p_setCashierScene:params]; //标识是否是电商场景
    
    NSString *channelData = [params cj_stringValueForKey:@"channel_data"];
    CJPayBDCreateOrderResponse *response = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:@{@"response": [channelData cj_toDic] ?: @{}} error:nil];
    
    CJPayFrontCashierContext *context = [CJPayFrontCashierContext new];
    context.defaultConfig = [CJPayDefaultChannelShowConfig new];
    context.extParams = params;
    context.latestOrderResponseBlock = ^CJPayBDCreateOrderResponse * _Nonnull {
        return response;
    };
    
    [self p_handleParams:params response:response]; // 根据业务入参来解析部分配置
    
    self.payContext = context;
    self.completion = [completion copy];
    self.verifyManager.changePayMethodDelegate = self;
    
    // 银行卡解锁
    NSDictionary *exts = response.lynxShowInfo.exts;
    NSString *lockedBankCardList = [exts cj_stringValueForKey:@"lockedCardList"];
    NSString *bankCardId = response.payInfo.bankCardId;
    if (Check_ValidString(bankCardId) && [lockedBankCardList containsString:response.payInfo.bankCardId]) {
        [self p_bankCardUnlockWithResponse:response];
    } else {
        [self p_startPaymentWithResponse:response];
    }
}

- (void)p_bankCardUnlockWithResponse:(CJPayBDCreateOrderResponse *)response {
    CJPayLynxShowInfo *lynxShowInfo = response.lynxShowInfo;
    if (!lynxShowInfo.needJump) {
        [self p_requestUnlockBankCardWithResponse:response];
        return;
    }
    CJPayPayCancelLynxRetainViewController *popUpVC = [[CJPayPayCancelLynxRetainViewController alloc] initWithRetainInfo:lynxShowInfo.exts schema:lynxShowInfo.url];
    @CJWeakify(self)
    popUpVC.eventBlock = ^(NSString * _Nonnull event, NSDictionary * _Nonnull data) {
        @CJStrongify(self)
        if ([event isEqualToString:@"on_confirm"]) {
            [self p_requestUnlockBankCardWithResponse:response];
            return;
        }
        CJPayManagerResultType resultType = CJPayManagerResultCancel;
        NSString *msg = CJPayLocalizedStr(@"银行卡解锁取消");
        BOOL openFail = [data cj_boolValueForKey:@"open_fail"];
        if (openFail) {
            resultType = CJPayManagerResultError;
            msg = CJPayLocalizedStr(@"解锁银行卡弹窗打开失败");
            [CJTracker event:@"wallet_rd_open_cjlynxcard_fail" params:@{}];
        }
        CJ_CALL_BLOCK(self.completion, resultType, msg);
    };
    [self push:popUpVC animated:YES];
}

- (void)p_requestUnlockBankCardWithResponse:(CJPayBDCreateOrderResponse *)response {
    [CJPayLoadingManager.defaultService startLoading:CJPayLoadingTypeDouyinStyleLoading];
    @CJWeakify(self)
    [CJPayUnlockBankCardRequest startRequestWithBizParam:@{
        @"app_id": CJString(response.merchant.appId),
        @"merchant_id": CJString(response.merchant.merchantId),
        @"bank_card_id": CJString(response.payInfo.bankCardId),
    } completion:^(NSError *error, CJPayBaseResponse * _Nonnull unlockResponse) {
        @CJStrongify(self)
        [CJPayLoadingManager.defaultService stopLoading];
        if (!error && unlockResponse.isSuccess) {
            [self p_showAndTrackUnlockToast:CJPayLocalizedStr(@"银行卡解锁成功")];
            [self p_startPaymentWithResponse:response];
            return;
        }
        [self p_showAndTrackUnlockToast:CJPayLocalizedStr(@"银行卡解锁失败，请更换支付方式")];
        CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, @"银行卡解锁失败");
    }];
}

- (void)p_showAndTrackUnlockToast:(NSString *)toastMsg {
    [CJToast toastText:toastMsg inWindow:self.topVC.cj_window];
    [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_cashier_unlock_toast_imp" params:@{
        @"toast_label": CJString(toastMsg)
    }];
}

- (void)p_startPaymentWithResponse:(CJPayBDCreateOrderResponse *)response {
    CJPayChannelType channelType = [CJPayBDTypeInfo getChannelTypeBy:response.payInfo.businessScene];
    self.payContext.defaultConfig.type = channelType;
    self.verifyManager.trackInfo =[self.payContext.extParams cj_dictionaryValueForKey:@"track_info"];
    [self p_trackPerformance];
    
    switch (channelType) {
        case BDPayChannelTypeAddBankCard:
            [self p_bindCardAndPay];
            break;
        case BDPayChannelTypeBankCard:
            [self p_payWithBankCardId:response.payInfo.bankCardId];
            break;
        case BDPayChannelTypeBalance:{
            self.payContext.defaultConfig = [response getPreTradeBalanceChannelShowConfig];
            [self p_updateDefaultPayConfig];
            [self p_pay];
        }
            break;
        case BDPayChannelTypeCreditPay:
            [self p_activateCreditAndPay];
            break;
        case BDPayChannelTypeAfterUsePay:
            [self p_payAfterUse];
            break;
        case BDPayChannelTypeIncomePay:
            [self p_preIncomePay];
            break;
        case BDPayChannelTypeCombinePay:
            self.payContext.defaultConfig = [self.payContext.orderResponse getCardModelBy:response.payInfo.bankCardId];
            self.payContext.defaultConfig.type = channelType;
            [self p_combinePay];
            break;
        case BDPayChannelTypeFundPay:
            [self p_updateDefaultPayConfig];
            [self p_pay];
            break;
        default:
        {
            NSString *errorDesc = [NSString stringWithFormat:@"未找到支付方式:%@", CJString(response.payInfo.businessScene)];
            CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, errorDesc);
            break;
        }
    }
}

// 解析收银台调用场景
- (void)p_setCashierScene:(NSDictionary *)params {
    BOOL isPreStandardPay = [[params cj_stringValueForKey:@"cashier_scene"] isEqualToString:@"standard"];
    BOOL isCashierSourceLynx = [[params cj_stringValueForKey:@"cashier_source_temp"] isEqualToString:@"lynx"];
    self.cashierScene = isPreStandardPay && isCashierSourceLynx ? CJPayCashierScenePreStandard : CJPayCashierSceneEcommerce; //根据入参区分是电商场景还是本地生活场景
}

//从params解析收银台配置
- (void)p_handleParams:(NSDictionary *)params response:(CJPayBDCreateOrderResponse *)response {
    self.isShowResultPage = [[params cj_stringValueForKey:@"need_result_page"] isEqualToString:@"1"]; //是否需要展示结果页
    
    [CJPayKVContext kv_setValue:[[CJPayStayAlertForOrderModel alloc] initWithTradeNo:response.intergratedTradeIdentify] forKey:CJPayStayAlertShownKey];
    CJPayStayAlertForOrderModel *model = [CJPayKVContext kv_valueForKey:CJPayStayAlertShownKey];
    model.hasShow = [[params cj_stringValueForKey:@"has_cashier_show_retain"] isEqualToString:@"1"]; //是否需要展示挽留
    
    self.comeFromDeskType = [[params cj_stringValueForKey:@"cashier_page_mode"] isEqualToString:@"halfpage"] ? CJPayComeFromDeskTypeHalfPage : CJPayComeFromDeskTypeFullPage; //前置页面类型
    
}

- (void)p_trackPerformance {
    // 上报提单页相关耗时、提单页解析接口数据耗时、jsb 调用耗时
    // self.createOrderResponse.userInfo.pwdCheckWay
    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval currentTimestamp = [date timeIntervalSince1970] * 1000;
    self.enterTimestamp = currentTimestamp;

    if (![CJPaySettingsManager shared].currentSettings.isHitEventUploadSampled) {
        // 没有下发采样率数据，不上报
        return;
    }

    NSDictionary *map = @{
        @"0" : @"密码",
        @"1" : @"指纹",
        @"2" : @"面容",
        @"3" : @"免密"
    };
    NSString *checkType = [map cj_stringValueForKey:self.createOrderResponse.userInfo.pwdCheckWay];
    NSMutableDictionary *timestampInfo = [[self.payContext.extParams cj_dictionaryValueForKey:@"timestamp_info"] mutableCopy];
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
    NSMutableDictionary *updatedExtParams = [[NSMutableDictionary alloc] initWithDictionary:self.payContext.extParams];
    [updatedExtParams cj_setObject:timestampInfo forKey:@"timestamp_info"];
    // 更新 extParams
    self.payContext.extParams = [updatedExtParams copy];
}

- (void)p_bindCardAndPay
{
    self.verifyManager.payContext = self.payContext;
    if (self.createOrderResponse.payInfo.subPayTypeDisplayInfoList) {
        self.verifyManager.payContext = self.bindcardPayContext;
    }
    [self.verifyManager onBindCardAndPayAction];
}

- (void)p_payWithBankCardId:(NSString *)bankCardId
{
    if (!Check_ValidString(bankCardId)) {
        CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, @"银行卡号为空");
        return;
    }
    
    CJPayDefaultChannelShowConfig *selectedConfig = [self.payContext.orderResponse getCardModelBy:bankCardId];
    
    if (selectedConfig) {
        self.payContext.defaultConfig = selectedConfig;
        [self p_updateDefaultPayConfig];
        [self p_pay];
    } else {
        CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, @"找不到对应的银行卡");
        CJPayLogInfo(@"未找到id为 %@ 的卡", CJString(bankCardId));
    }
}

- (void)p_pay
{
    self.verifyManager.payContext = self.payContext;
    [self.verifyManager begin];
    [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_cashier_confirm_pswd_type_sdk" params:@{}];
}

- (void)p_creditPay {
    // 只上传支付方式，不解析更多配置
    CJPayDefaultChannelShowConfig *showConfig = [CJPayDefaultChannelShowConfig new];
    showConfig.type = BDPayChannelTypeCreditPay;
    showConfig.mobile = CJString(self.createOrderResponse.userInfo.mobile);
    self.payContext.defaultConfig = showConfig;
    [self p_updateDefaultPayConfig];
    [self p_pay];
}

- (void)p_creditAmountComparisonWithAmount:(NSInteger)amount successDesc:(NSString *)desc style:(CJPayCreditPayActivationLoadingStyle)style {
    CJPayBDCreateOrderResponse *response = self.payContext.latestOrderResponseBlock();
    
    // 实际付款金额大于信用额度，则额度不足
    if (response.payInfo.realTradeAmountRaw > amount) {
        if (style == CJPayCreditPayActivationLoadingStyleNew) {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"额度不足")];
            CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, desc);
        } else {
            [self p_activateCreditFailedWithAmountNotSufficient];
        }
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (style == CJPayCreditPayActivationLoadingStyleNew && Check_ValidString(self.verifyManager.token)) {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:CJPayLocalizedStr(@"抖音月付支付中")];
            } else if (style == CJPayCreditPayActivationLoadingStyleOld) {
                [CJToast toastText:desc inWindow:[UIViewController cj_topViewController].cj_window];
            }
        });
        [self p_creditPay];
    }
}

- (void)p_payAfterUse {
    if (self.payContext.orderResponse.userInfo.hasSignedCards) {
        [self p_pay];
    } else {
        [self p_bindCardAndPay];
    }
}

- (void)p_combinePay {
    if ([self.payContext.orderResponse.payInfo.primaryPayType isEqualToString:@"new_bank_card"]) {
        [self p_bindCardAndPay];
    } else {
        // 组合支付余额+老卡触发补签约，需要给cjIdentify设置老卡的bankcardid
        self.payContext.defaultConfig.cjIdentify = CJString(self.payContext.orderResponse.payInfo.bankCardId);
        [self p_pay];
    }
}

- (void)p_doCreditTargetAction {
    @CJWeakify(self);
    [CJPayCreditPayUtil doCreditTargetActionWithPayInfo:self.payContext.orderResponse.payInfo completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg, NSString * _Nonnull payToken) {
        @CJStrongify(self);
        self.creditPayActivationResultType = type;
        self.verifyManager.token = payToken;
        switch (type) {
            case CJPayCreditPayServiceResultTypeSuccess:
                [self p_creditPay];
                break;
            case CJPayCreditPayServiceResultTypeFail:
            case CJPayCreditPayServiceResultTypeNoUrl:
                CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, msg);
                break;
                
            default:
                CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, [NSString stringWithFormat:@"%@, default type", msg]);
                break;
        }
    }];
}

- (void)p_activateCreditAndPay {
    if (self.payContext.orderResponse.payInfo.isNeedJumpTargetUrl) {
        [self p_doCreditTargetAction];
        return;
    }
    
    if (self.isCreditPayActiveSuccess) {
        [self p_creditPay];
        return;
    }
    
    @CJWeakify(self)
    [CJPayCreditPayUtil activateCreditPayWithPayInfo:self.payContext.orderResponse.payInfo completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg, NSInteger creditLimit, CJPayCreditPayActivationLoadingStyle style,NSString * _Nonnull token) {
        @CJStrongify(self)
        self.creditPayActivationResultType = type;
        self.verifyManager.token = token;
        switch (type) {
            case CJPayCreditPayServiceResultTypeActivated:
                [self p_creditPay];
                break;
            case CJPayCreditPayServiceResultTypeNoUrl:
            case CJPayCreditPayServiceResultTypeNoNetwork:
            case CJPayCreditPayServiceResultTypeFail:
                if (style == CJPayCreditPayActivationLoadingStyleNew) {
                    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"抖音月付激活失败")];
                }
                [self closeNotSufficentVC];
                CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, msg);
                break;
            case CJPayCreditPayServiceResultTypeSuccess:
                self.isCreditPayActiveSuccess = YES;
                if (creditLimit != -1) { // 有额度
                    [self p_creditAmountComparisonWithAmount:creditLimit successDesc:msg style:style];
                } else {
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        if (style == CJPayCreditPayActivationLoadingStyleNew) {
                            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"额度不足")];
                            CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, msg);
                        } else {
                            [CJToast toastText:msg inWindow:[UIViewController cj_topViewController].cj_window];
                        }
                    });
                    [self p_creditPay];
                }
                break;
            case CJPayCreditPayServiceResultTypeCancel:
                [self closeNotSufficentVC];
                CJ_CALL_BLOCK(self.completion, CJPayManagerResultCancel, msg);
                break;
            case CJPayCreditPayServiceResultTypeTimeOut:
                if (style == CJPayCreditPayActivationLoadingStyleNew) {
                    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"抖音月付激活超时")];
                }
            default:
                [self closeNotSufficentVC];
                CJ_CALL_BLOCK(self.completion, CJPayManagerResultTimeout, msg);
                break;
        }
    }];
}

- (void)p_preIncomePay {
    
    if (!self.payContext.orderResponse.userInfo) {
        CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, @"无法获取开户状态");
        return;
    }
    
    if (!self.payContext.orderResponse.userInfo.isNewUser) {
        [self p_pay];
        return;
    }
    // 新用户实名开户
    if ([self.payContext.orderResponse.userInfo.authStatus isEqualToString:@"0"]) {
        // 未实名展示弹窗
        @CJWeakify(self)
        NSString *leftDesc = CJPayLocalizedStr(@"取消");
        NSString *rightDesc = CJPayLocalizedStr(@"去认证");
        [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"根据监管要求，使用钱包收入支付前需先完成抖音零钱开户认证") content:nil leftButtonDesc:leftDesc rightButtonDesc:rightDesc leftActionBlock:^{
            @CJStrongify(self)
            [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_cashier_identified_pop_click" params:@{
                @"button_name": leftDesc
            }];
            CJ_CALL_BLOCK(self.completion, CJPayManagerResultCancel, @"实名开户取消");
        } rightActioBlock:^{
            @CJStrongify(self)
            [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_cashier_identified_pop_click" params:@{
                @"button_name": rightDesc
            }];
            [self p_gotoAuth];
        } useVC:[self topVC]];
        
        [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_cashier_identified_pop_imp" params:@{}];
    }
    else {
        [self p_gotoAuth];
    }
}

- (void)p_gotoAuth {
    NSString *schema = self.payContext.orderResponse.userInfo.lynxAuthUrl;
    @CJWeakify(self)
    if (!Check_ValidString(schema)) {
        CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, @"Lynx开户schema为空");
        return;
    }
    // Lynx开户流程
    NSMutableDictionary *param = [NSMutableDictionary new];
    NSMutableDictionary *sdkInfo = [NSMutableDictionary new];
    [sdkInfo cj_setObject:schema forKey:@"schema"];
    [param cj_setObject:@(98) forKey:@"service"];
    [param cj_setObject:sdkInfo forKey:@"sdk_info"];
    
    CJ_DECLARE_ID_PROTOCOL(CJPayUniversalPayDeskService);
    if (objectWithCJPayUniversalPayDeskService) {
        [objectWithCJPayUniversalPayDeskService i_openUniversalPayDeskWithParams:param
                                                                    withDelegate:[[CJPayAPICallBack alloc] initWithCallBack:^(CJPayAPIBaseResponse * _Nonnull response) {
            @CJStrongify(self)
            // Lynx实名开户回调
            [self p_authCallBackWithResponse:response];
        }]];
    }
    else {
        CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, @"Lynx实名开户拉起失败");
    }
}

- (void)p_authCallBackWithResponse:(CJPayAPIBaseResponse *)response {
    if (response.data && [response.data isKindOfClass:[NSDictionary class]]) {
        NSDictionary *data = [response.data cj_dictionaryValueForKey:@"data"];
        if (data && [data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *msg = [data cj_dictionaryValueForKey:@"msg"];
            if (msg && [msg isKindOfClass:[NSDictionary class]]) {
                NSInteger code = [msg cj_integerValueForKey:@"code"];
                NSString *process = [msg cj_stringValueForKey:@"process"];
                if ([process isEqualToString:@"auth_open_account"]) {
                    if (code == 0) {
                        // 开户成功
                        [self p_pay];
                    }
                    else {
                        // 开户取消
                        CJ_CALL_BLOCK(self.completion, CJPayManagerResultCancel, @"实名开户取消");
                    }
                    return;
                }
            }
            
        }
    }
    
    CJ_CALL_BLOCK(self.completion, CJPayManagerResultError, @"未知错误");
}

- (void)p_activateCreditFailedWithAmountNotSufficient {
    @CJWeakify(self)
    [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(@"抖音月付额度不足，请选择其他支付方式") content:nil buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, CJPayLocalizedStr(@"抖音月付激活成功，额度不足，请更换支付方式"));
    } useVC:[UIViewController cj_topViewController]];
}

- (void)p_userCancelRiskVerify:(id)verifyType {
    if ([verifyType isKindOfClass:NSNumber.class]) {
        NSNumber *typeNum = (NSNumber *)verifyType;
        if ([typeNum intValue] == CJPayVerifyTypeBioPayment) {
            return;
        }
    }
    if (![self topVCIsCJPay]) {
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromCloseAction];
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


- (void)p_dimissFullPageVCAboveCurrent:(BOOL) isFromQuery {
    
    NSArray *endVerifyItemTypes = @[@(CJPayVerifyTypeFaceRecogRetry), @(CJPayVerifyTypeFaceRecog), @(CJPayVerifyTypeUploadIDCard)];
    if (!isFromQuery && [endVerifyItemTypes containsObject:@(self.verifyManager.lastHandleVerifyItem.verifyType)]) {
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromBack];
        return;
    }
    
    if (!isFromQuery && self.verifyManager.lastConfirmVerifyItem && [endVerifyItemTypes containsObject:@(self.verifyManager.lastConfirmVerifyItem.verifyType)]) {
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromBack];
        return;
    }
    
    UIViewController *firstVC = [UIViewController cj_topViewController].navigationController.viewControllers.firstObject;
    
    if (firstVC.navigationController != self.navigationController ||
        ![firstVC.navigationController isKindOfClass:[CJPayNavigationController class]]
        || [firstVC isKindOfClass:CJPayPopUpBaseViewController.class]) {
        return;
    }
    if ([firstVC isKindOfClass:[CJPayBaseViewController class]]) {
        [firstVC.navigationController popToViewController:firstVC animated:NO];
    } else {
        [firstVC.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)p_signCardAndPayFailedWithMessage:(NSString *)errorMessage {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if (![topVC.navigationController isKindOfClass:[CJPayNavigationController class]]) { //没有CJPay的页面的时候，回调给业务方失败
        NSString *errorMsg = [NSString stringWithFormat:@"补签约并支付失败：%@",CJString(errorMessage)];
        CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, errorMsg);
    } else {
        [CJToast toastText:errorMessage inWindow:[self topVC].cj_window];
    }
}

- (void)p_callbackResultWithSource:(CJPayHomeVCCloseActionSource)source {
    [self p_callbackResultWithSource:source data:nil];
}

- (void)p_callbackResultWithSource:(CJPayHomeVCCloseActionSource)source data:(id)data {
    if (!self.completion) {
        CJPayLogAssert(NO, @"completion can't be nil.");
        return;
    }
    
    switch (source) {
        case CJPayHomeVCCloseActionSourceFromCloseAction:
            self.completion(CJPayManagerResultCancel, @"关闭收银台");
            break;
        case CJPayHomeVCCloseActionSourceFromBack:
            self.completion(CJPayManagerResultCancel, @"流程退出");
            break;
        case CJPayHomeVCCloseActionSourceFromBindAndPayFail:
            self.completion(CJPayManagerResultFailed, @"绑卡并支付失败");
            break;
        case CJPayHomeVCCloseActionSourceFromInsufficientBalance:{
            self.completion(CJPayManagerResultInsufficientBalance, [self p_payDisableReasonStrWithData:data]);
        }
            break;
        case CJPayHomeVCCloseActionSourceFromRequestError:
            self.completion(CJPayManagerResultError, @"接口错误");
            break;
        case CJPayHomeVCCloseActionSourceFromClosePayDeskShowBizError:
            [self p_closePayDeskAndShowErrorTips];
            break;
        default:
            [self p_callbackQueryResultWithResponse:self.verifyManager.resResponse];
            break;
    }
}

// 构造不可用支付方式回调数据
- (NSString *)p_payDisableReasonStrWithData:(id)data {
    if (self.cashierScene == CJPayCashierSceneEcommerce) {
        return @"用户余额不足";
    }
    //非电商场景回调需包括不可用支付方式及原因
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

- (void)p_callbackQueryResultWithResponse:(CJPayBDOrderResultResponse *)response {
    CJPayManagerResultType type = CJPayManagerResultError;
    NSString *errorDesc = @"未知错误";
    if (!response.tradeInfo) {
        CJ_CALL_BLOCK(self.completion, type, errorDesc);
        return;
    }
    
    if (response.tradeInfo.tradeStatus == CJPayOrderStatusProcess &&
        [response.processingGuidePopupInfo isValid]) {
        // 电商业务支付中状态特殊处理，显示弹框后再回调给业务方
        
        type = CJPayManagerResultProcessing;
        errorDesc = @"支付处理中";
        
        CJPayRetainInfoModel *retainInfoModel = [CJPayRetainInfoModel new];
        retainInfoModel.title = response.processingGuidePopupInfo.title;
        retainInfoModel.voucherContent = response.processingGuidePopupInfo.desc;
        retainInfoModel.topButtonText = response.processingGuidePopupInfo.btnText;
        @CJWeakify(self)
        retainInfoModel.closeCompletionBlock = ^{
            @CJStrongify(self)
            [self.verifyManager.verifyManagerQueen trackCashierWithEventName:@"wallet_cashier_paying_pop_click" params:@{
                            @"button_name":@"关闭",
            }];
            
            CJ_CALL_BLOCK(self.completion, type, errorDesc);
        };
        
        retainInfoModel.topButtonBlock = ^{
            @CJStrongify(self)
            
            [self.verifyManager.verifyManagerQueen trackCashierWithEventName:@"wallet_cashier_paying_pop_click" params:@{
                @"button_name": CJString(response.processingGuidePopupInfo.btnText),
            }];
            
            CJ_CALL_BLOCK(self.completion, type, errorDesc);
        };
        CJPayPayCancelRetainViewController *popupVC = [[CJPayPayCancelRetainViewController alloc] initWithRetainInfoModel:retainInfoModel];
        popupVC.isDescTextAlignmentLeft = YES;
        popupVC.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet :UIModalPresentationOverFullScreen;
        
        [self.verifyManager.verifyManagerQueen trackCashierWithEventName:@"wallet_cashier_paying_pop_imp" params:nil];
        
        [self push:popupVC animated:YES];
        return;
    }
    
    switch (response.tradeInfo.tradeStatus) {
        case CJPayOrderStatusProcess:
            type = CJPayManagerResultProcessing;
            errorDesc = @"支付处理中";
            break;
        case CJPayOrderStatusFail:
            type = CJPayManagerResultFailed;
            errorDesc = @"支付失败";
            break;
        case CJPayOrderStatusTimeout:
            type = CJPayManagerResultTimeout;
            errorDesc = @"支付超时";
            break;
        case CJPayOrderStatusSuccess:
            type = CJPayManagerResultSuccess;
            errorDesc = @"支付成功";
            break;
        default:
            break;
    }
    CJ_CALL_BLOCK(self.completion, type, errorDesc);
}

// push新页面时加上兜底关闭回调
- (void)p_trySetBackBlockWithVC:(UIViewController *)vc {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.navigationController.viewControllers.count == 1 && !vc.cjBackBlock) {
            vc.cjBackBlock = ^{
                [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromBack];
            };
        }
    });
}

- (void)p_handlePayMethodDisabled:(id)response {
    if (![response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        return;
    }
    
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
    
    CJPayDefaultChannelShowConfig *curSelectConfig = [self curSelectConfig];
    
    NSString *cjIdentify;
    if (curSelectConfig.type == BDPayChannelTypeAddBankCard) {
        cjIdentify = confirmResponse.bankCardId;
    } else if (curSelectConfig.type == BDPayChannelTypeCombinePay && !curSelectConfig.cjIdentify) {
        cjIdentify = confirmResponse.bankCardId;
    } else {
        cjIdentify = curSelectConfig.cjIdentify;
    }
    
    if (Check_ValidString(cjIdentify) && ![self.payDisabledFundID2ReasonMap.allKeys containsObject:cjIdentify]) {
        [self.payDisabledFundID2ReasonMap cj_setObject:confirmResponse.hintInfo.statusMsg forKey:cjIdentify];
    }
    CJPayHintInfoStyle showStyle = confirmResponse.hintInfo.style;
    if (showStyle == CJPayHintInfoStyleNewHalf || showStyle == CJPayHintInfoStyleOldHalf || showStyle == CJPayHintInfoStyleVoucherHalf || showStyle == CJPayHintInfoStyleVoucherHalfV2) {
        [self p_gotoHalfPayMethodDisabledVCWithResponse:confirmResponse];
    } else if (showStyle == CJPayHintInfoStyleWindow) {
        [self p_gotoPopUpPayMethodDisabledVCWithResponse:confirmResponse];
    }
}


- (void)p_handleNotSufficient:(id)response {
    UIViewController *topVC = [self topVC];
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
    
    CJPayDefaultChannelShowConfig *curSelectConfig = [self curSelectConfig];
    
    NSString *cjIdentify;
    if (curSelectConfig.type == BDPayChannelTypeAddBankCard) {
        cjIdentify = confirmResponse.bankCardId;
    } else {
        cjIdentify = curSelectConfig.cjIdentify;
    }
    
    if (Check_ValidString(cjIdentify) && ![self.payDisabledFundID2ReasonMap.allKeys containsObject:cjIdentify]) {
        [self.payDisabledFundID2ReasonMap cj_setObject:confirmResponse.hintInfo.statusMsg forKey:cjIdentify];
    }
    
    // 前面是半屏的情况
    if ([topVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [self p_gotoHalfNotSufficientVCWithResponse:confirmResponse];
        return;
    }
    
    // 前面是免密或者全屏或者没有SDK页面的情况
    [self p_gotoPopUpNotSufficientVCWithResponse:confirmResponse];
}

- (void)p_gotoHalfNotSufficientVCWithResponse:(CJPayOrderConfirmResponse *)confirmResponse {
    UIViewController *topVC = [self topVC];
    CJPayECHalfNotSufficientViewController *notSufficientVC = [CJPayECHalfNotSufficientViewController new];
    notSufficientVC.height = [((CJPayHalfPageBaseViewController *)topVC) containerHeight];
    notSufficientVC.showTitle = confirmResponse.hintInfo.msg;
    
    @CJWeakify(self);
    notSufficientVC.closeActionCompletionBlock = ^(BOOL success) {
        @CJStrongify(self);
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromInsufficientBalance];
    };
    
    if ([topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        CJPayNavigationController *navi = (CJPayNavigationController *)topVC.navigationController;
        [self p_handlePushHalfViewController:notSufficientVC];
        BOOL needAnimated = YES;
        if ([topVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            CJPayHalfPageBaseViewController *halfTopVC = (CJPayHalfPageBaseViewController *)topVC;
            if ([halfTopVC containerHeight] == [notSufficientVC containerHeight]) {
                needAnimated = NO;
            }
        }
        [self p_pushSingleTop:notSufficientVC animated:needAnimated];
    } else {
        [topVC.navigationController pushViewController:notSufficientVC animated:YES];
    }
}

- (void)p_gotoHalfPayMethodDisabledVCWithResponse:(CJPayOrderConfirmResponse *)confirmResponse {
    CJPayPayAgainHalfViewController *payMethodDisabledVC = [CJPayPayAgainHalfViewController new];
    payMethodDisabledVC.createOrderResponse = self.payContext.orderResponse;
    payMethodDisabledVC.confirmResponse = confirmResponse;
    payMethodDisabledVC.verifyManager = self.verifyManager;
    payMethodDisabledVC.payDisabledFundID2ReasonMap = self.payDisabledFundID2ReasonMap;
    payMethodDisabledVC.delegate = self;
    payMethodDisabledVC.extParams = self.payContext.extParams;
        
    @CJWeakify(self);
    if (self.cashierScene == CJPayCashierScenePreStandard) {
        //非电商场景二次支付页面的返回不经过挽留逻辑，故需通过dismissCompletionBlock进行点击事件设置
        payMethodDisabledVC.dismissCompletionBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull recommendConfig) {
            @CJStrongify(self);
            [self p_callbackResultWithSource:CJPayHomeVCCloseActionSourceFromInsufficientBalance data:recommendConfig];
        };
    } else {
        payMethodDisabledVC.closeActionCompletionBlock = ^(BOOL success) {
            @CJStrongify(self);
            [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromInsufficientBalance];
        };
    }
    
    UIViewController *topVC = [self topVC];
    if ([topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
        CJPayNavigationController *navi = (CJPayNavigationController *)topVC.navigationController;
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

- (void)p_handleDiscountNotAvailable:(id)response {
    if(response && [response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
        [self p_gotoHalfPayMethodDisabledVCWithResponse:confirmResponse];
    }
}

- (void)p_gotoPopUpNotSufficientVCWithResponse:(CJPayOrderConfirmResponse *)confirmResponse {
    CJPayECPopUpNotSufficientViewController *notSufficientVC = [CJPayECPopUpNotSufficientViewController new];
    notSufficientVC.showTitle = confirmResponse.hintInfo.msg;

    @CJWeakify(self);
    notSufficientVC.closeActionCompletionBlock = ^(BOOL success) {
        @CJStrongify(self);
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromInsufficientBalance];
    };
    
    [self p_pushSingleTop:notSufficientVC animated:YES];
}

- (void)p_gotoPopUpPayMethodDisabledVCWithResponse:(CJPayOrderConfirmResponse *)confirmResponse {
    CJPayPayAgainPopUpViewController *payMethodDisabledVC = [CJPayPayAgainPopUpViewController new];
    payMethodDisabledVC.verifyManager = self.verifyManager;
    payMethodDisabledVC.confirmResponse = confirmResponse;
    payMethodDisabledVC.createResponse = self.payContext.orderResponse;
    payMethodDisabledVC.payDisabledFundID2ReasonMap = self.payDisabledFundID2ReasonMap;
    payMethodDisabledVC.delegate = self;
    payMethodDisabledVC.extParams = self.payContext.extParams;
    
    @CJWeakify(self);
    if (self.cashierScene == CJPayCashierScenePreStandard) {
        payMethodDisabledVC.dismissCompletionBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull recommendConfig) {
            @CJStrongify(self);
            [self p_callbackResultWithSource:CJPayHomeVCCloseActionSourceFromInsufficientBalance data:recommendConfig];
        };
    } else {
        payMethodDisabledVC.closeActionCompletionBlock = ^(BOOL success) {
            @CJStrongify(self);
            [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromInsufficientBalance];
        };
    }
    [self p_pushSingleTop:payMethodDisabledVC animated:YES];
}

- (void)p_pushSingleTop:(UIViewController *)vc animated:(BOOL)animated {
    if (!self.navigationController || [UIViewController cj_topViewController].navigationController != self.navigationController) {
        [self p_presentVC:vc animated:animated];
    } else {
        [self.navigationController pushViewControllerSingleTop:vc animated:animated completion:nil];
    }
}

- (void)p_closePayDeskAndShowErrorTips {
    CJPayECErrorTipsViewController *vc = [CJPayECErrorTipsViewController new];
    vc.iconTips = self.verifyManager.confirmResponse.iconTips;
    @CJWeakify(self);
    vc.closeCompletionBlock = ^{
        @CJStrongify(self);
        CJ_CALL_BLOCK(self.completion, CJPayManagerResultFailed, @"支付触发业务错误");
    };
    [self push:vc animated:YES];
}

#pragma mark - CJPayPayAgainDelegate

- (void)payWithContext:(CJPayFrontCashierContext *)context loadingView:(nonnull UIView *)loadingView {
    self.verifyManager.isNotSufficient = YES;
    self.payContext = context;
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
                
        return;
    }
    
    if (channelType == BDPayChannelTypeCreditPay) {
        [self p_activateCreditAndPay];
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
        
        return;
    }
}

- (void)showState:(CJPayStateType)stateType {
    UIViewController *vc = [UIViewController cj_topViewController];
    if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [((CJPayHalfPageBaseViewController *)vc) showState:stateType];
    }
}

#pragma mark - CJPayChooseDyPayMethodDelegate
// 验证过程中更改支付方式
- (void)changePayMethod:(CJPayFrontCashierContext *)payContext loadingView:(UIView *)loadingView {

    CJPayChannelType channelType = payContext.defaultConfig.type;
    
    if (channelType == BDPayChannelTypeAddBankCard) {
        // 选中绑卡时单独存储payContext，与其他支付方式区分开
        self.bindcardPayContext = payContext;
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
        return;
    }
    
    if ([payContext.defaultConfig isNeedReSigning]) { //六位密码支持补签约
        @CJWeakify(self)
        self.verifyManager.signCardStartLoadingBlock = ^{
            @CJStrongify(self)
            [self startLoading];
        };
        self.verifyManager.signCardStopLoadingBlock = ^{
            @CJStrongify(self)
            [self stopLoading];
        };
        self.signCardPayContext = payContext;
        [self.verifyManager wakeSpecificType:CJPayVerifyTypeSignCard orderRes:payContext.orderResponse event:nil];
        return;
    }
    
    [self.verifyManager exitBindCardStatus];
    
    // 若有更改过支付方式，则进行记录
    if (![self.payContext.defaultConfig isEqual:payContext.defaultConfig] && !self.verifyManager.hasChangeSelectConfigInVerify) {
        self.verifyManager.hasChangeSelectConfigInVerify = YES;
    }
    // 修改收银台首页记录的当前支付方式
    self.payContext = payContext;
    self.verifyManager.payContext = payContext;
    
}

- (NSDictionary *)payContextExtParams {
    return self.payContext.extParams ?: [NSDictionary new];
}

- (NSDictionary *)getPayDisabledReasonMap {
    return [self.payDisabledFundID2ReasonMap copy];
}

// 新样式验密页需额外解析支付方式配置
- (void)p_updateDefaultPayConfig {
    if (!self.createOrderResponse.payInfo.subPayTypeDisplayInfoList) {
        return;
    }
    CJPayDefaultChannelShowConfig *curSelectConfig = self.payContext.defaultConfig;
    CJPayInfo *payInfo = self.createOrderResponse.payInfo;
    curSelectConfig.payAmount = Check_ValidString(payInfo.standardShowAmount) ? CJString(payInfo.standardShowAmount) : CJString(payInfo.realTradeAmount);
    if (!Check_ValidString(curSelectConfig.payVoucherMsg)) {
        curSelectConfig.payVoucherMsg = CJString(payInfo.standardRecDesc);
    }
    if (!Check_ValidString(curSelectConfig.title)) {
        curSelectConfig.title = CJString(payInfo.payName);
    }
    
    if (curSelectConfig.type == BDPayChannelTypeCreditPay && !curSelectConfig.payTypeData) {
        curSelectConfig.payTypeData = [CJPaySubPayTypeData new];
        [curSelectConfig.payTypeData updateDefaultCreditModel:[self.createOrderResponse.payInfo buildCreditPayMethodModel]];
    }
}

#pragma mark - HomeVCProtocol
- (nullable CJPayBDCreateOrderResponse *)createOrderResponse {
    return self.payContext.orderResponse;
}

- (nullable CJPayDefaultChannelShowConfig *)curSelectConfig {
    if (self.createOrderResponse.payInfo.subPayTypeDisplayInfoList && self.verifyManager.isBindCardAndPay && self.bindcardPayContext) {
        return self.bindcardPayContext.defaultConfig;
    }
    if (self.createOrderResponse.payInfo.subPayTypeDisplayInfoList && self.signCardPayContext.defaultConfig) {
        return self.signCardPayContext.defaultConfig;
    }
    return self.payContext.defaultConfig;
}

- (UIViewController *)topVC {
    return [UIViewController cj_topViewController];
}

- (CJPayVerifyType)firstVerifyType {
    if (self.createOrderResponse.needResignCard) {
        return CJPayVerifyTypeSignCard;
    } else if ([self.createOrderResponse.userInfo.pwdCheckWay isEqualToString:@"1"] || [self.createOrderResponse.userInfo.pwdCheckWay isEqualToString:@"2"]) {
        return CJPayVerifyTypeBioPayment;
    } else if ([self.createOrderResponse.userInfo.pwdCheckWay isEqualToString:@"3"]) {
        return CJPayVerifyTypeSkipPwd;
    } else if ([self.createOrderResponse.userInfo.pwdCheckWay isEqualToString:@"5"]) {
        return CJPayVerifyTypeSkip;
    } else if ([self.createOrderResponse.userInfo.pwdCheckWay isEqualToString:@"6"] && Check_ValidString(self.verifyManager.token)) {
        return CJPayVerifyTypeToken;
    }
    return CJPayVerifyTypePassword;
}

- (void)p_cancelVerifyWithType:(CJPayVerifyType)verifyType {
    if ([self isNewVCBackWillExistPayProcess]) {
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromBack];
        return;
    }
    
    if (verifyType == CJPayVerifyTypeSignCard) { //清空补签约config，恢复默认支付方式
        self.signCardPayContext = nil;
    }
}

// 数据总线，verifyManager 像 HomePageVC通信
- (BOOL)receiveDataBus:(CJPayHomeVCEvent)eventType obj:(id)object {
    switch (eventType) {
        case CJPayHomeVCEventDismissAllAboveVCs:
            [self p_dimissFullPageVCAboveCurrent: [object boolValue]];
            break;
        case CJPayHomeVCEventCancelVerify:
            [self p_cancelVerifyWithType:[object integerValue]];
            break;
        case CJPayHomeVCEventBindCardNoPwdCancel:
        case CJPayHomeVCEventGotoCardList:
            [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromCloseAction];
            break;
        case CJPayHomeVCEventClosePayDesk:
            [self closeActionAfterTime:0 closeActionSource:[object integerValue]];
            break;
        case CJPayHomeVCEventNotifySufficient:
            [self p_handleNotSufficient:object];
            break;
        case CJPayHomeVCEventPayMethodDisabled:
            [self p_handlePayMethodDisabled:object];
            break;
        case CJPayHomeVCEventUserCancelRiskVerify:
            [self p_userCancelRiskVerify:object];
            break;
        case CJPayHomeVCEventShowState:
            [self showState:[object integerValue]];
            break;
        case CJPayHomeVCEventSignAndPayFailed:
            [self p_signCardAndPayFailedWithMessage:object];
            break;
        case CJPayHomeVCEventDiscountNotAvailable:
            [self p_handleDiscountNotAvailable:object];
            break;
        case CJPayHomeVCEventWakeItemFail: {
            if (![self topVCIsCJPay]) {
                [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromRequestError];
            }
            break;
        }
        default:
            break;
    }
    return YES;
}

- (void)p_trackPushParams:(NSDictionary *)params {
    NSMutableDictionary *mutableParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [mutableParams addEntriesFromDictionary:@{
        @"cjpay_topVC": CJString([[UIViewController cj_topViewController] cj_trackerName]),
        @"cjpay_navi": CJString([self.navigationController cj_trackerName]),
        @"cjpay_navi_presentingVC" : CJString([self.navigationController.presentingViewController cj_trackerName]),
        @"cjpay_navi_presentedVC" : CJString([self.navigationController.presentedViewController cj_trackerName])
    }];

    if (self.verifyManager.verifyManagerQueen) {
        [self.verifyManager.verifyManagerQueen trackCashierWithEventName:@"wallet_rd_ecommerce_push" params:mutableParams];
    } else {
        [CJTracker event:@"wallet_rd_ecommerce_push" params:mutableParams];
    }
}

- (void)push:(UIViewController *)vc animated:(BOOL)animated {
    [self p_trySetBackBlockWithVC:vc];
    UIViewController *topVC = [UIViewController cj_topViewController];
    // 需要新起导航栈
    if (topVC.navigationController != self.navigationController || !self.navigationController) {
        [self p_presentVC:vc animated:animated];
    } else {
        // 使用现有navi来push新页面
        [self p_trackPushParams:@{
            @"pushed_vc": CJString([vc cj_trackerName]),
            @"ec_rd_type": CJString([self.navigationController cj_trackerName]),
        }];
        
        CJPayNavigationController *navi = self.navigationController;
        if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            [self p_handlePushHalfViewController:(CJPayHalfPageBaseViewController *)vc];
        }
        if ([topVC isKindOfClass:CJPayPopUpBaseViewController.class]) {
            if ([vc isKindOfClass:CJPayPopUpBaseViewController.class]) {
                [(CJPayPopUpBaseViewController *)vc showMask:NO];
            }
            if ([topVC isKindOfClass:CJPayPayAgainPopUpViewController.class]) {
                [navi pushViewController:vc animated:animated];
            } else {
                [navi pushViewControllerSingleTop:vc animated:animated completion:nil];
            }
            return;
        }
        [navi pushViewController:vc animated:animated];
    }
}

// 新起导航栈present页面
- (void)p_presentVC:(UIViewController *)vc animated:(BOOL)animated {
    
    UIViewController *topVC = [UIViewController cj_topViewController];
    [self p_trackPushParams:@{
        @"pushed_vc": CJString([vc cj_trackerName]),
        @"ec_rd_type": @"top_navi_old",
        @"is_exception": (topVC.navigationController != self.navigationController && self.navigationController) ? @"1" : @"0",
        @"top_navi": CJString([topVC.navigationController cj_trackerName]),
    }];
    
    BOOL newNavUseMask = YES;
    // 本地生活场景需定制present转场蒙层
    if (self.cashierScene == CJPayCashierScenePreStandard) {
        newNavUseMask = self.comeFromDeskType == CJPayComeFromDeskTypeFullPage;
        if (self.comeFromDeskType == CJPayComeFromDeskTypeHalfPage && [vc isKindOfClass:CJPaySkipPwdConfirmHalfPageViewController.class]) {
            newNavUseMask = YES;
        }
    }
    
    if ([CJPaySettingsManager shared].currentSettings == nil || [CJPaySettingsManager shared].currentSettings.loadingConfig.isEcommerceDouyinLoadingAutoClose ) {
        [[CJPayLoadingManager defaultService] stopLoading]; // 关闭电商拉起的Loading
    }
    
    if ([vc isKindOfClass:[CJPayHalfPageBaseViewController class]]) {
        CJPayHalfPageBaseViewController *halfVC = (CJPayHalfPageBaseViewController *)vc;
        //电商/非电商场景对半屏页面的处理不同
        if (self.cashierScene == CJPayCashierSceneEcommerce) {
            halfVC = [self p_handlePushHalfViewController:halfVC];
        } else {
            halfVC = [self p_handlePresentHalfViewController:halfVC];
        }
        self.navigationController = [halfVC presentWithNavigationControllerFrom:topVC useMask:newNavUseMask completion:nil];
    } else if ([vc isKindOfClass:CJPayBaseViewController.class]){
        
        if ([vc isKindOfClass:CJPayPopUpBaseViewController.class]) {
            newNavUseMask = YES;
        }
        CJPayBaseViewController *cjpayVC = (CJPayBaseViewController *)vc;
        self.navigationController = [cjpayVC presentWithNavigationControllerFrom:topVC useMask:newNavUseMask completion:nil];
    } else {
        //监控present非CJPay页面
        [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_rd_present_notcjpay" params:@{
            @"pushed_vc": CJString([vc cj_trackerName]),
            @"is_exception": (topVC.navigationController != self.navigationController && self.navigationController) ? @"1" : @"0",
            @"top_navi": CJString([topVC.navigationController cj_trackerName]),
            @"top_vc": CJString([topVC cj_trackerName]),
            @"cashdesk": @"ecommerce"
        }];
        
        CJPayNavigationController *nav = [CJPayNavigationController instanceForRootVC:vc];
        nav.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet :UIModalPresentationOverFullScreen;
        nav.view.backgroundColor = UIColor.clearColor;
        self.navigationController = nav;
        [topVC presentViewController:nav animated:animated completion:nil];
    }
    self.navigationController.useNewHalfPageTransAnimation = [self.createOrderResponse.payInfo isDynamicLayout]; // 动态化布局时，半屏<->半屏的转场采用新动画样式
}

// 多少秒后关闭收银台，time小于等于0 立即关闭
- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
    @CJWeakify(self)

    if (self.cashierScene == CJPayCashierScenePreStandard && source == CJPayHomeVCCloseActionSourceFromQuery) { //非电商场景出现结果页的直接回调，要提前给Lynx回调便于隐藏首页
        //在极速付引导情况下，需要多等0.1s再回调，不然会有转场冲突
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((self.isPreStandFeGuide ? 0.1 : 0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @CJStrongify(self);
            [self p_callbackResultWithSource:source];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_dismissAllVCWithCloseActionSource:source completion:nil];
            });
        });
       
        return;
    }
   
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        [self p_dismissAllVCWithCloseActionSource:source completion:^{
            [self p_callbackResultWithSource:source];
        }];
    });
}

// 关闭收银台页面、退出支付流程
- (void)p_dismissAllVCWithCloseActionSource:(CJPayHomeVCCloseActionSource)source completion:(void (^)(void))completion {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if (self.navigationController && topVC.navigationController == self.navigationController) {
        @CJWeakify(self)
        HalfVCEntranceType animateType = HalfVCEntranceTypeFromBottom;
        // 非电商场景，back退场动画需定制
        if (self.cashierScene == CJPayCashierScenePreStandard && source == CJPayHomeVCCloseActionSourceFromBack) {
           animateType = self.comeFromDeskType == CJPayComeFromDeskTypeHalfPage ? HalfVCEntranceTypeFromRight : HalfVCEntranceTypeFromBottom;
        }
        
        self.navigationController.dismissAnimatedType = animateType == HalfVCEntranceTypeFromRight ? CJPayDismissAnimatedTypeFromRight : CJPayDismissAnimatedTypeFromBottom;
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(completion);
        }];
        
    } else if (self.navigationController.presentingViewController) {
        @CJWeakify(self)
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            @CJStrongify(self)
            CJ_CALL_BLOCK(completion);
        }];
    } else {
        CJ_CALL_BLOCK(completion);
    }
}

- (void)closeNotSufficentVC {//不进行回调，关闭二次支付页
    UIViewController *topVC = [UIViewController cj_topViewController];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.navigationController && topVC.navigationController == self.navigationController) {
            [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else if (self.navigationController.presentingViewController) {
            [self.navigationController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        }
    });
}

- (void)endVerifyWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
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
    
    @CJWeakify(self)
    // 如果勾选了支付中引导开通生物识别，则需在查单成功后额外发请求开通生物能力
    if (self.createOrderResponse.preBioGuideInfo != nil && self.verifyManager.isNeedOpenBioPay) {
        [self p_sendRequestToEnableBioPaymentWithCompletion:^{
            @CJStrongify(self)
            [self p_showGuidePageWithResponse:resultResponse];
        }];
        return;
    }
    // 如果勾选了支付中免密引导，则在查单Res里返回开通结果
    if (Check_ValidString(resultResponse.skipPwdOpenMsg)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CJToast toastText:resultResponse.skipPwdOpenMsg inWindow:[self topVC].cj_window];
        });
    }
    
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

- (void)p_tryShowResultPageWithResponse:(CJPayBDOrderResultResponse *)response isAfterGuide:(BOOL)isAfterGuide {
    if (![self.verifyManager isKindOfClass:[CJPayECVerifyManager class]]) {
        [self.verifyManager sendEventTOVC:CJPayHomeVCEventClosePayDesk obj:@(CJPayHomeVCCloseActionSourceFromQuery)];
        return;
    }
    
    CJPayECVerifyManager *ecommerceVerifyManager = (CJPayECVerifyManager *)self.verifyManager;
    BOOL isSkipPwdPay = self.verifyManager.lastWakeVerifyItem.verifyType == CJPayVerifyTypeSkipPwd;
    BOOL isBioPay = self.verifyManager.lastWakeVerifyItem.verifyType == CJPayVerifyTypeBioPayment;
    CJPayChannelType channelType = [CJPayBDTypeInfo getChannelTypeBy:self.verifyManager.response.payInfo.businessScene];
    
    CJPayOrderStatus orderStatus = response.tradeInfo.tradeStatus;
    BOOL isLoadingNeedShowPayResult = [CJPayLoadingManager defaultService].loadingStyleInfo.isNeedShowPayResult;
    BOOL isNeedShowResultPage = NO;
    //针对电商/非电商场景，支付结果页的展示条件也不相同
    if (self.cashierScene == CJPayCashierSceneEcommerce) {
        //电商场景复用结果页来展示安全感loading的成功态
        isNeedShowResultPage = (!isAfterGuide && orderStatus == CJPayOrderStatusSuccess && isLoadingNeedShowPayResult && !isSkipPwdPay && !isBioPay && channelType != BDPayChannelTypeAddBankCard) || self.isShowResultPage;
    } else {
        isNeedShowResultPage = [response closeAfterTime] != 0 && self.isShowResultPage;
    }
    
    if (isNeedShowResultPage) {
        // 需要结果页面
        CJPayBDResultPageViewController *resultPage = [CJPayBDResultPageViewController new];
        resultPage.resultResponse = response;
        @CJWeakify(self)
        resultPage.cjBackBlock = ^{
            @CJStrongify(self)
            [self closeActionAfterTime:0
                     closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
        };
        resultPage.verifyManager = self.verifyManager;
        resultPage.animationType = HalfVCEntranceTypeNone;
        resultPage.isShowNewStyle = [CJPayLoadingManager defaultService].loadingStyleInfo.isNeedShowPayResult;
        
        UIViewController *topVC = [self.verifyManager.homePageVC topVC] ?: [UIViewController cj_topViewController];
        if (topVC.navigationController && [topVC.navigationController isKindOfClass:[CJPayNavigationController class]] && topVC.navigationController == self.navigationController) { // 有可能找不到
            [(CJPayNavigationController *)topVC.navigationController pushViewControllerSingleTop:resultPage
                                                                                        animated:NO
                                                                                      completion:nil];
        } else {
            [self push:resultPage animated:YES];
        }
    } else {
        // 不需要结果页面
        // 安全感loading支付成功有结束动画，需延时关闭收银台
        CGFloat closeDelayTime = orderStatus == CJPayOrderStatusSuccess && isLoadingNeedShowPayResult ? 0.6 : 0;
        if (self.cashierScene == CJPayCashierScenePreStandard && response.feGuideInfoModel) {
            self.isPreStandFeGuide = YES;
        }
        [self closeActionAfterTime:closeDelayTime closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
    }
}

// 负责展示支付后引导
- (void)p_showGuidePageWithResponse:(CJPayBDOrderResultResponse *)resultResponse {
    @CJWeakify(self)
    void(^guideCompletionBlock)(void) = ^(){
        @CJStrongify(self)
        [self p_tryShowResultPageWithResponse:resultResponse isAfterGuide:YES];
    };

    // 免密相关引导
    if ([CJPaySkippwdGuideUtil shouldShowGuidePageWithResultResponse:resultResponse]) {
        [CJPaySkippwdGuideUtil showGuidePageVCWithVerifyManager:self.verifyManager pushAnimated:YES completionBlock:^{
            CJ_CALL_BLOCK(guideCompletionBlock);
        }];
        return;
    }
    
    // 刷脸支付后重置密码
    if ([resultResponse.resultPageGuideInfoModel.guideType isEqual:@"reset_pwd"]) {
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
        [objectWithCJPayBioPaymentPlugin showGuidePageVCWithVerifyManager:self.verifyManager completionBlock:^{
            CJ_CALL_BLOCK(guideCompletionBlock);
        }];
        return;
    }
    
    // 到系统设置开启生物权限引导
    if ([objectWithCJPayBioPaymentPlugin shouldShowBioSystemSettingGuideWithResultResponse:resultResponse]) {
        [objectWithCJPayBioPaymentPlugin showBioSystemSettingVCWithVerifyManager:self.verifyManager completionBlock:^{
            CJ_CALL_BLOCK(guideCompletionBlock);
        }];
        return;
    }
    
    // 先用后付引导
    if (Check_ValidString(resultResponse.feGuideInfoModel.url)) {
        [self p_showFEGuidePageWithResponse:resultResponse
                                 completion:guideCompletionBlock];
        return;
    }
    
    // 不展示引导，则尝试展示结果页
    [self p_tryShowResultPageWithResponse:resultResponse isAfterGuide:NO];
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
    if (self.cashierScene == CJPayCashierScenePreStandard) {
        self.isShowResultPage = NO;
    }
    
    // 存入 uid，开通生物验证方式时需要
    NSString *CJPayCJOrderResultCacheStringKey = @"CJPayGuideInfo";
    NSDictionary *dict = @{@"uid": CJString(response.userInfo.uid)};
    NSString *dataJsonStr = [dict btd_jsonStringEncoded];
    if (CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService)) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_setParams:dataJsonStr key:CJPayCJOrderResultCacheStringKey];
        [CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_setParams:self.verifyManager.lastPWD key:@"lastPWD"];
    }
    
    [CJPayDeskUtil openLynxPageBySchema:schema completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
        CJ_CALL_BLOCK(completion);
    }];
    
    [CJTracker event:@"wallet_rd_open_lynx_guide"
              params:@{@"schema": CJString(schema)}];
}

- (NSDictionary *)p_getTrackInfo {
    if ([self.verifyManager isKindOfClass:CJPayECVerifyManager.class]) {
        CJPayECVerifyManager *ecommerceVerifyManager = (CJPayECVerifyManager *)self.verifyManager;
        return [ecommerceVerifyManager.payContext.extParams cj_dictionaryValueForKey:@"track_info"];
    }
    return @{};
}

#pragma mark - CJPayBaseLoadingDelegate
- (void)startLoading {
    NSString *verifyWay = self.verifyManager.response.userInfo.pwdCheckWay;
    BOOL isCreditToken = [verifyWay isEqualToString:@"6"];
    CJPayChannelType channelType = [CJPayBDTypeInfo getChannelTypeBy:self.verifyManager.response.payInfo.businessScene];
    if (isCreditToken && channelType == BDPayChannelTypeCreditPay) {
        if (self.creditPayActivationResultType == CJPayCreditPayServiceResultTypeNoUrl || self.creditPayActivationResultType == CJPayCreditPayServiceResultTypeFail || self.creditPayActivationResultType == CJPayCreditPayServiceResultTypeNoNetwork) {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"抖音月付激活失败")];
        } else if (self.creditPayActivationResultType == CJPayCreditPayServiceResultTypeTimeOut) {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"抖音月付激活超时")];
        }
        return;
    }
    
    if ([CJPayLoadingManager defaultService].isDouyinStyleLoading) {
        // 免密验证时，沿用当前正在进行的loading而不需要新开
        if ([CJPayLoadingManager defaultService].isLoading && [verifyWay isEqualToString:@"3"]) {
            return;
        }
        // 二次支付免验密需收起收银台，使用全屏loading
        if (self.verifyManager.isNotSufficient &&
            [@[@(CJPayVerifyTypeSkipPwd), @(CJPayVerifyTypeSkip), @(CJPayVerifyTypeBioPayment)] containsObject:@(self.verifyManager.lastWakeVerifyItem.verifyType)]) {
            @CJWeakify(self)
            [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                @CJStrongify(self)
                [self p_securityLoading];
            }];
        } else {
            [self p_securityLoading];
        }
        return;
    }
    
    BOOL isSkipPwdPay = [self.verifyManager.response.userInfo.pwdCheckWay isEqualToString:@"3"];
    BOOL isBioPay = [self.verifyManager.response.userInfo.pwdCheckWay isEqualToString:@"1"] || [self.verifyManager.response.userInfo.pwdCheckWay isEqualToString:@"2"];
    UIViewController *topVC = [UIViewController cj_topViewController];
    
    if ([topVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading];
    } else if (self.navigationController && topVC.navigationController == self.navigationController){
        CJPayBrandPromoteModel *model = [CJPaySettingsManager shared].currentSettings.abSettingsModel.brandPromoteModel;
        if (model && model.showNewLoading) {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
        } else {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading title:@""];
        }
    } else if (isSkipPwdPay && channelType != BDPayChannelTypeAddBankCard) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading title:[self p_getLoadingText]];
    } else if ([CJPayLoadingManager defaultService].isDouyinStyleLoading && isBioPay) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading title:CJPayLocalizedStr(@"抖音支付中")];
    } else if (isCreditToken && channelType == BDPayChannelTypeCreditPay) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading title:CJPayLocalizedStr(@"抖音月付支付中")];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
    }
}

- (void)stopLoading {
    [[CJPayLoadingManager defaultService] stopLoading];
}

- (void)stopLoadingWithState:(CJPayLoadingQueryState)state {
    [[CJPayLoadingManager defaultService] stopLoadingWithState:state];
}

- (void)p_securityLoading {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if ([topVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading isNeedValidateTimer:YES];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading isNeedValidateTimer:YES];
    }
    self.startloadingTime = CFAbsoluteTimeGetCurrent();
}

#pragma mark - Private Methods
- (void)p_removeNotSufficientPopUpViewController {
    UIViewController *topVC = [UIViewController cj_topViewController];
    NSMutableArray *viewControllers = [topVC.navigationController.viewControllers mutableCopy];

    if ([viewControllers.firstObject isKindOfClass:CJPayPayAgainPopUpViewController.class]) {
        [viewControllers removeObjectAtIndex:0];
    }
    if (viewControllers.count == 0) {
        [topVC.navigationController dismissViewControllerAnimated:NO completion:nil];
    } else {
        topVC.navigationController.viewControllers = [viewControllers copy];
    }
}

- (void)p_sendRequestToEnableBioPaymentWithCompletion:(void (^)(void))completion {
    NSMutableDictionary *requestModel = [NSMutableDictionary new];
    [requestModel cj_setObject:self.createOrderResponse.merchant.appId forKey:@"app_id"];
    [requestModel cj_setObject:self.createOrderResponse.merchant.merchantId forKey:@"merchant_id"];
    [requestModel cj_setObject:self.createOrderResponse.userInfo.uid forKey:@"uid"];
    [requestModel cj_setObject:self.createOrderResponse.tradeInfo.tradeNo forKey:@"trade_no"];
    [requestModel cj_setObject:[self.createOrderResponse.processInfo dictionaryValue] forKey:@"process_info"];
    [requestModel cj_setObject:[CJPaySafeManager buildEngimaEngine:@""] forKey:@"engimaEngine"];
    NSDictionary *pwdDic = [CJPayBioManager buildPwdDicWithModel:requestModel lastPWD:self.verifyManager.lastPWD];
    @CJWeakify(self)
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading];
    [CJPayCashdeskEnableBioPayRequest startWithModel:requestModel
                           withExtraParams:pwdDic
                                completion:^(NSError * _Nonnull error, CJPayCashdeskEnableBioPayResponse * _Nonnull response, BOOL result) {
        @CJStrongify(self)
        if (result) {
            NSString *msg = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"指纹支付已开通" : @"面容支付已开通";
            [CJToast toastText:msg code:@"" duration:1 inWindow:[self topVC].cj_window];
        } else {
            NSString *msg = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"指纹支付开通失败" : @"面容支付开通失败";
            [CJToast toastText:msg code:@"" duration:1 inWindow:[self topVC].cj_window];
        }
        [[CJPayLoadingManager defaultService] stopLoading];
        CJ_CALL_BLOCK(completion);
    }];
}

//Lynx收银台场景，present半屏页面时需根据前置页面类型（payDeskType）决定转场动画
- (CJPayHalfPageBaseViewController *)p_handlePresentHalfViewController:(CJPayHalfPageBaseViewController *)halfVC {
    [halfVC showMask:NO];
    if (self.comeFromDeskType == CJPayComeFromDeskTypeHalfPage) {
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

- (BOOL)isNewVCBackWillExistPayProcess {
    // 没有页面或顶部是免密的弹窗，再推出风控相关页面要设置backblock
    UIViewController *topVC = [UIViewController cj_topViewController];
    if ([topVC.navigationController isKindOfClass:[CJPayNavigationController class]] && topVC.navigationController == self.navigationController) {
        NSInteger vcCount = topVC.navigationController.viewControllers.count;
        UIViewController *lastVC = topVC.navigationController.viewControllers.lastObject;
        return vcCount == 1 && [lastVC isKindOfClass:[CJPayPopUpBaseViewController class]];
    } else {
        return YES;
    }
}

- (BOOL)topVCIsCJPay {
    UIViewController *topVC = [UIViewController cj_topViewController];
    return [topVC.navigationController isKindOfClass:[CJPayNavigationController class]] && topVC.navigationController == self.navigationController;
}

- (BOOL)p_topVCIsHalfVC {
    UIViewController *lastVC = [UIViewController cj_topViewController].navigationController.viewControllers.lastObject;
    if ([lastVC isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        return YES;
    }
    return NO;
}

#pragma mark - Getter
- (NSMutableDictionary *)payDisabledFundID2ReasonMap {
    if (!_payDisabledFundID2ReasonMap) {
        _payDisabledFundID2ReasonMap = [NSMutableDictionary new];
    }
    return _payDisabledFundID2ReasonMap;
}

- (CJPayFrontCashierContext *)bindcardPayContext {
    if (!_bindcardPayContext) {
        _bindcardPayContext = self.payContext;
    }
    return _bindcardPayContext;
}
@end
