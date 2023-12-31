//
//  CJPayDyPayController.m
//  Pods
//
//  Created by xutianxi on 2023/02/28.
//

#import "CJPayDyPayController.h"

#import "CJPayHalfPageBaseViewController.h"
#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayLoadingManager.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayWebViewUtil.h"
#import "CJPayNavigationController.h"
#import "UIViewController+CJTransition.h"
#import "CJPayEnumUtil.h"
#import "CJPaySettings.h"
#import "CJPayLoadingButton.h"
#import "CJPayKVContext.h"
#import "CJPayStayAlertForOrderModel.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayUniversalPayDeskService.h"
#import "CJPayPayCancelRetainViewController.h"
#import "CJPayTouchIdManager.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayRequestParam.h"
#import "CJPaySafeUtil.h"
#import "CJPayBioManager.h"
#import "CJPayCashdeskEnableBioPayRequest.h"
#import "CJPayCreditPayUtil.h"
#import <ByteDanceKit/NSURL+BTDAdditions.h>
#import "CJPayAlertUtil.h"
#import "CJPayTimerManager.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayDeskUtil.h"
#import "CJPayDyPayVerifyManagerQueen.h"
#import "CJPayDyPayVerifyManager.h"
#import "CJPayFullResultPageViewController.h"
#import "CJPayResultPageModel.h"
#import "CJPaySDKDefine.h"
#import "CJPayDyPayCreateOrderRequest.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayHalfVerifyPasswordV3ViewController.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayChooseDyPayMethodManager.h"
#import "CJPayBDResultPageViewController.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayFreqSuggestStyleInfo.h"
#import "CJPayPasswordContentViewV3.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayTradeInfo.h"

@interface CJPayDyPayController()<CJPayHomeVCProtocol, CJPayChooseDyPayMethodDelegate>

@property (nonatomic, copy) void (^completion)(CJPayBDOrderResultResponse *resResponse, CJPayOrderStatus orderStatus);

@property (nonatomic, strong) CJPayNavigationController *navigationController;

@property (nonatomic, assign, readonly) BOOL isNotSufficientNewStyle;

@property (nonatomic, assign) BOOL isCreditPayActiveSuccess;

@property (nonatomic, assign) CJPayCreditPayServiceResultType creditPayActivationResultType;
// 安全感loading耗时埋点
@property (nonatomic, assign) CFAbsoluteTime startloadingTime;
@property (nonatomic, assign) CFAbsoluteTime stoploadingTime;
@property (nonatomic, assign) NSTimeInterval enterTimestamp;

@property (nonatomic, strong) CJPayFrontCashierContext *bindcardPayContext; //支付中选择绑卡时，单独存储绑卡支付方式
@property (nonatomic, strong) CJPayFrontCashierContext *signCardPayContext; //支付中选择补签约卡时，单独存储补签约支付方式

// 唤端追光使用参数
@property (nonatomic, copy) NSString *outerAppName; // 拉起收银台支付的 App name
@property (nonatomic, copy) NSString *outerAppID; // 拉起收银台支付的 App id
@property (nonatomic, assign, readonly) BOOL isCloseFromRetain; //是否是点击挽留弹框上的放弃关闭收银台的

@end

@implementation CJPayDyPayController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _verifyManager = [CJPayDyPayVerifyManager managerWith:self];
        _isCreditPayActiveSuccess = NO;
    }
    return self;
}

- (void)startPaymentWithParams:(NSDictionary *)params
           createOrderResponse:(CJPayBDCreateOrderResponse *)response
               completionBlock:(void(^)(CJPayBDOrderResultResponse *resResponse, CJPayOrderStatus orderStatus))completionBlock {
    [CJPayLoadingManager defaultService].loadingStyleInfo = response.loadingStyleInfo;
    
    self.verifyManager = [CJPayDyPayVerifyManager managerWith:self];
    self.verifyManager.bizParams = params;
    self.verifyManager.verifyManagerQueen = self.verifyManagerQueen;
    self.verifyManager.isPayOuterMerchant = self.isPayOuterMerchant;
    
    CJPayFrontCashierContext *context = [CJPayFrontCashierContext new];
    context.defaultConfig = [response.payTypeInfo getDefaultDyPayConfig];
    context.latestOrderResponseBlock = ^CJPayBDCreateOrderResponse * _Nonnull {
        return response;
    };
        
    self.payContext = context;
    if (context.defaultConfig.type == BDPayChannelTypeAddBankCard) {
        self.bindcardPayContext = context;
    }
    self.completion = [completionBlock copy];
    self.verifyManager.changePayMethodDelegate = self;
    
    self.verifyManager.trackInfo =[self.payContext.extParams cj_dictionaryValueForKey:@"track_info"];
    self.verifyManager.payContext = self.payContext;
    [self.verifyManager begin];
}

- (CJPayDyPayVerifyManagerQueen *)verifyManagerQueen {
    if (!_verifyManagerQueen) {
        _verifyManagerQueen = [CJPayDyPayVerifyManagerQueen new];
        [_verifyManagerQueen bindManager:self.verifyManager];
    }
    return _verifyManagerQueen;
}

// 设置当前的月付分期数
- (NSString *)creditPayInstallment {
    CJPayDefaultChannelShowConfig *config = [self curSelectConfig];
    if (config.type == BDPayChannelTypeCreditPay) {
        __block BOOL hasChoose = NO;
        for (CJPayBytePayCreditPayMethodModel *model in config.payTypeData.creditPayMethods) {
            if (model.choose) {
                hasChoose = YES;
                return model.installment;
            }
        }
        if (hasChoose == NO) {
            CJPayBytePayCreditPayMethodModel *model = [config.payTypeData.creditPayMethods cj_objectAtIndex:0];
            model.choose = YES;
            return @"1";
        }
    }
    
    return @"1";
}

- (void)p_bindCardAndPay
{
    self.verifyManager.bindcardConfig = self.bindcardPayContext.defaultConfig;
    self.verifyManager.payContext = self.bindcardPayContext;
    [self.verifyManager onBindCardAndPayAction];
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
    [self p_pay];
}

// 激活抖音月付并支付
- (void)p_activateCreditAndPay {
    if (self.curSelectConfig.type != BDPayChannelTypeCreditPay) {
        return;
    }
    
    @CJWeakify(self)
    [CJPayCreditPayUtil activateCreditPayWithStatus:(self.curSelectConfig.isCreditActivate || self.isCreditPayActiveSuccess) activateUrl:self.curSelectConfig.creditActivateUrl completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg, NSInteger creditLimit, CJPayCreditPayActivationLoadingStyle style, NSString * _Nonnull token) {
        @CJStrongify(self)
        switch (type) {
            case CJPayCreditPayServiceResultTypeActivated:
                [self p_pay];
                break;
            case CJPayCreditPayServiceResultTypeNoUrl:
            case CJPayCreditPayServiceResultTypeNoNetwork:
            case CJPayCreditPayServiceResultTypeFail:
                [CJToast toastText:CJString(msg) inWindow:[UIViewController cj_topViewController].cj_window];
                break;
            case CJPayCreditPayServiceResultTypeSuccess:{
                // 抖音月付激活成功
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [CJToast toastText:CJString(msg) inWindow:[UIViewController cj_topViewController].cj_window];
                });
                self.isCreditPayActiveSuccess = YES;
                [self p_pay];
                break;
            }
            case CJPayCreditPayServiceResultTypeCancel:
                break;
            case CJPayCreditPayServiceResultTypeTimeOut:
            default:
                [CJToast toastText:CJString(msg) inWindow:[UIViewController cj_topViewController].cj_window];
        }
    }];
}

- (void)p_activateCreditFailedWithAmountNotSufficient {
    @CJWeakify(self)
    [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(@"抖音月付额度不足，请选择其他支付方式") content:nil buttonDesc:CJPayLocalizedStr(@"知道了") actionBlock:^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.completion, self.verifyManager.resResponse, CJPayOrderStatusFail);
    } useVC:[UIViewController cj_topViewController]];
}

- (void)p_userCancelRiskVerify:(id)verifyType {
    if ([verifyType isKindOfClass:NSNumber.class]) {
        NSNumber *typeNum = (NSNumber *)verifyType;
        if ([typeNum intValue] == CJPayVerifyTypeBioPayment) {
            [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeDouyinStyleHalfLoading isForce:YES];
            
            UIViewController *vc = [UIViewController cj_topViewController];
            if ([vc isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class]) {
                CJPayHalfVerifyPasswordV3ViewController *passwordV3VC = (CJPayHalfVerifyPasswordV3ViewController *)vc;
                [passwordV3VC showLoadingStatus:NO];
            }
            
            return;
        }
    }
}

- (void)p_signCardAndPayFailedWithMessage:(NSString *)errorMessage {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if (![topVC.navigationController isKindOfClass:[CJPayNavigationController class]]) { //没有CJPay的页面的时候，回调给业务方失败
        CJ_CALL_BLOCK(self.completion, self.verifyManager.resResponse, CJPayOrderStatusFail);
    } else {
        [CJToast toastText:errorMessage inWindow:[self topVC].cj_window];
    }
}

- (void)p_callbackResultWithSource:(CJPayHomeVCCloseActionSource)source {
    if (!self.completion) {
        CJPayLogAssert(NO, @"completion can't be nil.");
        return;
    }
    
    switch (source) {
        case CJPayHomeVCCloseActionSourceFromCloseAction:
            self.completion(self.verifyManager.resResponse, CJPayOrderStatusCancel);
            break;
        case CJPayHomeVCCloseActionSourceFromBack:
            self.completion(self.verifyManager.resResponse, CJPayOrderStatusCancel);
            break;
        case CJPayHomeVCCloseActionSourceFromBindAndPayFail:
            self.completion(self.verifyManager.resResponse, CJPayOrderStatusFail);
            break;
        case CJPayHomeVCCloseActionSourceFromInsufficientBalance:{
            self.completion(self.verifyManager.resResponse, CJPayOrderStatusFail);
        }
            break;
        case CJPayHomeVCCloseActionSourceFromRequestError:
            self.completion(self.verifyManager.resResponse, CJPayOrderStatusFail);
            break;
        default:
            [self p_callbackQueryResultWithResponse:self.verifyManager.resResponse];
            break;
    }
}

- (void)p_callbackQueryResultWithResponse:(CJPayBDOrderResultResponse *)response {
    NSString *errorDesc = @"未知错误";
    if (!response.tradeInfo) {
        CJ_CALL_BLOCK(self.completion, self.verifyManager.resResponse, CJPayOrderStatusNull);
        return;
    }
    
    if (response.tradeInfo.tradeStatus == CJPayOrderStatusProcess &&
        [response.processingGuidePopupInfo isValid]) {
        // 电商业务支付中状态特殊处理，显示弹框后再回调给业务方
        
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
            
            CJ_CALL_BLOCK(self.completion, self.verifyManager.resResponse, CJPayOrderStatusProcess);
        };
        
        retainInfoModel.topButtonBlock = ^{
            @CJStrongify(self)
            
            [self.verifyManager.verifyManagerQueen trackCashierWithEventName:@"wallet_cashier_paying_pop_click" params:@{
                @"button_name": CJString(response.processingGuidePopupInfo.btnText),
            }];
            
            CJ_CALL_BLOCK(self.completion, self.verifyManager.resResponse, CJPayOrderStatusProcess);
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
            errorDesc = @"支付处理中";
            break;
        case CJPayOrderStatusFail:
            errorDesc = @"支付失败";
            break;
        case CJPayOrderStatusTimeout:
            errorDesc = @"支付超时";
            break;
        case CJPayOrderStatusSuccess:
            errorDesc = @"支付成功";
            break;
        default:
            break;
    }
    CJ_CALL_BLOCK(self.completion, self.verifyManager.resResponse, response.tradeInfo.tradeStatus);
}

// 绑卡成功但支付失败
- (void)p_payFailWithData:(id)data {
    if ([data isKindOfClass:CJPayOrderConfirmResponse.class]) {
        NSString *msg = ((CJPayOrderConfirmResponse *)data).msg;
        if (Check_ValidString(msg)) {
            [CJToast toastText:CJString(msg) inWindow:[self topVC].cj_window];
        }
    }

    if (self.bindcardPayContext && self.verifyManager.isBindCardAndPay) {
        [self p_refreshCreateOrderWithParams:self.verifyManager.bizParams isHiddenToast:NO];
    } else {
        UIViewController *firstVC = [self.navigationController.viewControllers firstObject];
        if ([firstVC isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class]) {
            [self.navigationController popToViewController:firstVC animated:NO];
            CJPayHalfVerifyPasswordV3ViewController *passwordV3VC = (CJPayHalfVerifyPasswordV3ViewController *)firstVC;
            [passwordV3VC gotoChooseCardList];
        }
//        if ([firstVC isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class]) {
//            CJPayHalfVerifyPasswordV3ViewController *passwordV3VC = (CJPayHalfVerifyPasswordV3ViewController *)firstVC;
//            [passwordV3VC gotoChooseCardList];
//        } else if ([firstVC isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class]) {
//        }
    }
}

// 重新下追光单
- (void)p_refreshCreateOrderWithParams:(NSDictionary *)params isHiddenToast:(BOOL)isHiddenToast {
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
    double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
    [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime)}];
    [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_cashier_SDK_pull_start" params:trackData];
    
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
    @CJWeakify(self)
    [CJPayDyPayCreateOrderRequest startWithMerchantId:[params cj_stringValueForKey:@"partnerid" defaultValue:@""]
                                            bizParams:params
                                           completion:^(NSError * _Nonnull error, CJPayBDCreateOrderResponse * _Nonnull response) {
        @CJStrongify(self)
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
        double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
        [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime),
                                              @"error_msg":CJString(response.msg),
                                              @"error_code":CJString(response.code)}];
        [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_cashier_SDK_pull_result" params:trackData];
        CJPayFrontCashierContext *context = [CJPayFrontCashierContext new];
        context.defaultConfig = [response.payTypeInfo getDefaultDyPayConfig];
        context.latestOrderResponseBlock = ^CJPayBDCreateOrderResponse * _Nonnull {
            return response;
        };
        
        self.payContext = context;
        
        UIViewController *vc = [UIViewController cj_topViewController];
        if ([vc isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class]) {
            CJPayHalfVerifyPasswordV3ViewController *passwordV3VC = (CJPayHalfVerifyPasswordV3ViewController *)vc;
            [passwordV3VC updateChoosedPayMethodWhenBindCardPay];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeTopLoading];
        });
    }];
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
    
    if (loadingView) {
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
    }
    
    if (channelType == BDPayChannelTypeAddBankCard) {
        // 选中绑卡时单独存储payContext，与其他支付方式区分开
        self.bindcardPayContext = payContext;
        [self p_bindCardAndPay];
        return;
    }
    self.bindcardPayContext = nil;
    [self.verifyManager exitBindCardStatus];
    
    if ([payContext.defaultConfig isNeedReSigning]) {
        self.signCardPayContext = payContext; //只做记录，不立即发起补签约流程
        return;
    }
    self.signCardPayContext = nil;
    
    // 若有更改过支付方式，则进行记录
    if (![self.payContext.defaultConfig isEqual:payContext.defaultConfig] && !self.verifyManager.hasChangeSelectConfigInVerify) {
        self.verifyManager.hasChangeSelectConfigInVerify = YES;
    }
    // 修改收银台首页记录的当前支付方式
    self.payContext = payContext;
    self.verifyManager.payContext = payContext;
    
}

- (void)signPayWithPayContext:(CJPayFrontCashierContext *)payContext loadingView:(UIView *)loadingView {
    self.signCardPayContext = payContext;
    [self.verifyManager exitBindCardStatus];
    @CJWeakify(self)
    self.verifyManager.signCardStartLoadingBlock = ^{
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
    };
    self.verifyManager.signCardStopLoadingBlock = ^{
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] stopLoading];
    };
    [self.verifyManager wakeSpecificType:CJPayVerifyTypeSignCard orderRes:self.createOrderResponse event:nil];
}

- (NSDictionary *)payContextExtParams {
    return self.payContext.extParams ?: [NSDictionary new];
}

#pragma mark - HomeVCProtocol
- (nullable CJPayBDCreateOrderResponse *)createOrderResponse {
    return self.payContext.orderResponse;
}

- (nullable CJPayDefaultChannelShowConfig *)curSelectConfig {
    if ([self p_isPasswordV3Style] && self.verifyManager.isBindCardAndPay && self.bindcardPayContext) {
        return self.bindcardPayContext.defaultConfig;
    }
    if ([self p_isPasswordV3Style] && self.signCardPayContext.defaultConfig) {
        return self.signCardPayContext.defaultConfig;
    }
    return self.payContext.defaultConfig;
}

- (BOOL)p_isPasswordV3Style {
    return self.createOrderResponse.payTypeInfo.subPayTypeSumInfo != nil;
}

- (UIViewController *)topVC {
    return [UIViewController cj_topViewController];
}

- (CJPayVerifyType)firstVerifyType {
    CJPayVerifyType type = [self.verifyManager getVerifyTypeWithPwdCheckWay:self.verifyManager.response.userInfo.pwdCheckWay];
    if (self.verifyManager.response.needResignCard || [self.curSelectConfig isNeedReSigning]) {
//        type = CJPayVerifyTypeSignCard;
        type = CJPayVerifyTypePassword;
    }
    
    if (type == CJPayVerifyTypeBioPayment || type == CJPayVerifyTypeSkipPwd) {
        type = CJPayVerifyTypePassword;
    }
    
    return type;
}

- (void)p_cancelVerifyWithType:(CJPayVerifyType)verifyType {
    if ([self topVC].navigationController != self.navigationController) {
        @CJWeakify(self)
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
        case CJPayHomeVCEventBindCardPay:
            [self p_bindCardAndPay];
            break;
        case CJPayHomeVCEventDismissAllAboveVCs:
            [self closeActionAfterTime:0 closeActionSource:[object integerValue]];
            break;
        case CJPayHomeVCEventCancelVerify:
            [self p_cancelVerifyWithType:[object integerValue]];
            break;
        case CJPayHomeVCEventGotoCardList:
            // 需要处理一下
            [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromCloseAction];
            break;
        case CJPayHomeVCEventClosePayDesk:
            [self closeActionAfterTime:0 closeActionSource:[object integerValue]];
            break;
        case CJPayHomeVCEventNotifySufficient:
            [self p_payFailWithData:object];
            break;
        case CJPayHomeVCEventBindCardSuccessPayFail:
            [self p_payFailWithData:object];
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
        case CJPayHomeVCEventCombinePayLimit:
            [self p_combinePayLimitWithModel:object];
            break;
        default:
            break;
    }
    return YES;
}

- (void)p_combinePayLimitWithModel:(id)object {
    if (![object isKindOfClass:CJPayOrderConfirmResponse.class]) {
        return;
    }
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)object;
    [CJToast toastText:CJString(confirmResponse.msg) inWindow:[UIViewController cj_topViewController].cj_window];
}

- (void)push:(UIViewController *)vc animated:(BOOL)animated {
    UIViewController *topVC = [UIViewController cj_topViewController];
    if ((topVC.navigationController != self.navigationController || !self.navigationController) && [vc isKindOfClass:CJPayHalfPageBaseViewController.class] ) {
        // 需要新起导航栈
        CJPayHalfPageBaseViewController *halfVC = (CJPayHalfPageBaseViewController *)vc;
        halfVC.animationType = HalfVCEntranceTypeFromBottom;
        [halfVC useCloseBackBtn];
        self.navigationController = [halfVC presentWithNavigationControllerFrom:[UIViewController cj_topViewController] useMask:YES completion:nil];
        self.navigationController.useNewHalfPageTransAnimation = [self.createOrderResponse.payInfo isDynamicLayout]; // 动态化布局时，半屏<->半屏的转场采用新动画样式
    } else {
        [self.navigationController pushViewController:vc animated:animated];
    }
}

// 多少秒后关闭收银台，time小于等于0 立即关闭
- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
    @CJWeakify(self)
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
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            CJ_CALL_BLOCK(completion);
        }];
        
    } else if (self.navigationController.presentingViewController) {
        [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
            CJ_CALL_BLOCK(completion);
        }];
    } else {
        CJ_CALL_BLOCK(completion);
    }
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
            [self p_tryShowResultPageAndGuidePageWithResponse:resultResponse];
        }];
        return;
    }
        
    if (Check_ValidString(resultResponse.skipPwdOpenMsg)) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CJToast toastText:resultResponse.skipPwdOpenMsg inWindow:[self topVC].cj_window];
        });
    }
    // 尝试展示支付后引导和结果页
    [self p_tryShowResultPageAndGuidePageWithResponse:resultResponse];
}

- (void)p_trackConsumeTime {
    CFTimeInterval consumeTime = self.stoploadingTime - self.startloadingTime;
    CJPayLoadingStyleInfo *loadingStyleInfo = [CJPayLoadingManager defaultService].loadingStyleInfo;
    NSMutableDictionary *dict = [[loadingStyleInfo toDictionary] mutableCopy];
    [dict cj_setObject:@(consumeTime) forKey:@"consume_time"];
    [self.verifyManager.verifyManagerQueen trackVerifyWithEventName:@"wallet_security_loading_from_gif_two_to_end_consume_time" params:dict];
}

- (void)p_tryShowResultPageAndGuidePageWithResponse:(CJPayBDOrderResultResponse *)response {
    if (![self.verifyManager isKindOfClass:[CJPayDyPayVerifyManager class]]) {
        [self.verifyManager sendEventTOVC:CJPayHomeVCEventClosePayDesk obj:@(CJPayHomeVCCloseActionSourceFromQuery)];
        return;
    }
    
    if ([response closeAfterTime] == 0) {
        [self closeActionAfterTime:[response closeAfterTime] closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
    } else if (response.tradeInfo.tradeStatus != CJPayOrderStatusSuccess) {
        CJPayBDResultPageViewController *resultPage = [CJPayBDResultPageViewController new];
        resultPage.resultResponse = response;
        resultPage.animationType = HalfVCEntranceTypeFromBottom;
        resultPage.isPaymentForOuterApp = YES;
        @weakify(self);
        resultPage.closeActionCompletionBlock = ^(BOOL isCancel) {
            @strongify(self);
            CJ_CALL_BLOCK(self.completion, response, CJPayOrderStatusProcess);
        };
        resultPage.verifyManager = self.verifyManager;
        UINavigationController *navi = [self topVC].navigationController;
        if (navi && [navi isKindOfClass:[CJPayNavigationController class]]) {
            [((CJPayNavigationController *)navi) pushViewControllerSingleTop:resultPage animated:YES completion:nil];
        }
        
    } else {
        CJPayResultPageModel *model = [[CJPayResultPageModel alloc] init];
        model.resultPageInfo = response.resultPageInfo;
        model.amount = response.tradeInfo.payAmount;
        model.orderResponse = [model toDictionary]?:@{};
        
        NSMutableDictionary *mutableDic = [[CJPayCommonTrackUtil getBDPayCommonParamsWithResponse:self.verifyManager.response
                                                                                       showConfig:self.verifyManager.homePageVC.curSelectConfig] mutableCopy];
        NSString *outerId = [self.verifyManager.bizParams cj_stringValueForKey:@"app_id" defaultValue:@""];
        if (!Check_ValidString(outerId)) {
            outerId = [self.verifyManager.bizParams cj_stringValueForKey:@"merchant_app_id" defaultValue:@""];
        }
        
        [mutableDic addEntriesFromDictionary:@{
            @"identity_type" : CJString(self.verifyManager.response.userInfo.authStatus),
            @"activity_label" : CJString(self.verifyManager.response.payInfo.voucherMsg),
            @"result" : self.verifyManager.response.tradeInfo.tradeStatus == CJPayOrderStatusSuccess ? @"1" : @"0",
            @"outer_aid" : CJString(outerId),
        }];
        
        CJPayFullResultPageViewController *resultPage = [[CJPayFullResultPageViewController alloc] initWithCJResultModel:model trackerParams:mutableDic];
        @weakify(self);
        resultPage.closeCompletion = ^{
            @strongify(self);
            CJ_CALL_BLOCK(self.completion, response, CJPayOrderStatusNull);
        };
        
        if (![[self topVC].navigationController isKindOfClass:[CJPayNavigationController class]]) {
            CJ_CALL_BLOCK(self.completion, response, CJPayOrderStatusNull);
            return;
        }
        CJPayNavigationController *navi = (CJPayNavigationController *)([self topVC].navigationController);
        if (navi && [navi isKindOfClass:[CJPayNavigationController class]]) { // 有可能找不到
            [navi pushViewControllerSingleTop:resultPage animated:YES completion:^{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5*NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    CJ_DECLARE_ID_PROTOCOL(CJPayBioPaymentPlugin);
                    // 生物识别开通引导
                    if ([objectWithCJPayBioPaymentPlugin shouldShowGuideWithResultResponse:response]) {
                        [objectWithCJPayBioPaymentPlugin showGuidePageVCWithVerifyManager:self.verifyManager completionBlock:^{
                            [self.navigationController popViewControllerAnimated:YES];
                        }];
                    }
                });
            }];
        } else {
            CJ_CALL_BLOCK(self.completion, response, CJPayOrderStatusNull);
        }
    }
}

#pragma mark - CJPayBaseLoadingDelegate
- (void)startLoading {
    UIViewController *vc = [UIViewController cj_topViewController];
    BOOL vcIsPassVerifyHeight = NO;
    BOOL topVCIsPasswordV3Style = [vc isKindOfClass:CJPayHalfVerifyPasswordV3ViewController.class];
    if (topVCIsPasswordV3Style) {
        CJPayHalfVerifyPasswordV3ViewController *passwordV3VC = (CJPayHalfVerifyPasswordV3ViewController *)vc;
        [passwordV3VC showLoadingStatus:YES];
        vcIsPassVerifyHeight = passwordV3VC.passwordContentView.isPasswordVerifyStyle;
    }
    
    if ((!vcIsPassVerifyHeight && topVCIsPasswordV3Style) || ([self.createOrderResponse.deskConfig isFastEnterBindCard] && self.bindcardPayContext.defaultConfig.type == BDPayChannelTypeAddBankCard)) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleHalfLoading isNeedValidateTimer:YES];
    }
    self.startloadingTime = CFAbsoluteTimeGetCurrent();
}

- (void)stopLoading {
    [[CJPayLoadingManager defaultService] stopLoading];
}

#pragma mark - Private Methods

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
    [self startLoading];
    [CJPayCashdeskEnableBioPayRequest startWithModel:requestModel
                           withExtraParams:pwdDic
                                completion:^(NSError * _Nonnull error, CJPayCashdeskEnableBioPayResponse * _Nonnull response, BOOL result) {
        @CJStrongify(self)
        [self stopLoading];
        if (result) {
            NSString *msg = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"指纹支付已开通" : @"面容支付已开通";
            [CJToast toastText:msg code:@"" duration:1 inWindow:[self topVC].cj_window];
        } else {
            NSString *msg = [CJPayTouchIdManager currentSupportBiopaymentType] == CJPayBioPaymentTypeFinger ? @"指纹支付开通失败" : @"面容支付开通失败";
            [CJToast toastText:msg code:@"" duration:1 inWindow:[self topVC].cj_window];
        }
        CJ_CALL_BLOCK(completion);
    }];
}
@end
