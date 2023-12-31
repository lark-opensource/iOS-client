//
//  CJPaySuperPayController.m
//
//
//  Created by bytedance on 2022/5/30.
//

#import "CJPaySuperPayController.h"
#import "CJPayUIMacro.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayOrderResultResponse.h"
#import "CJPaySuperPayVerifyManager.h"
#import "CJPaySuperPayVerifyManagerQueen.h"
#import "CJPaySDKMacro.h"
#import "CJPayPayAgainHalfViewController.h"
#import "CJPayHintInfo.h"
#import "CJPaySuperPayQueryRequest.h"
#import "CJPayTimerManager.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPaySuperPayResultView.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayEnumUtil.h"
#import "CJPayCreditPayUtil.h"
#import "CJPayDeductAgainRequest.h"
#import "CJPayPopUpBaseViewController.h"
#import "CJPaySDKDefine.h"
#import "CJPayHintInfo.h"
#import "CJPayDeskUtil.h"

@interface CJPaySuperPayController ()<CJPayHomeVCProtocol, CJPayPayAgainDelegate>

@property (nonatomic, strong) CJPayBDCreateOrderResponse *bdCreateResponse;
@property (nonatomic, copy) void(^completionBlock)(CJPayOrderStatus orderStatus, NSString *msg);
@property (nonatomic, strong) CJPaySuperPayVerifyManager *verifyManager;
@property (nonatomic, strong) CJPaySuperPayVerifyManagerQueen *verifyManagerQueen;
@property (nonatomic, strong) CJPayNavigationController *navigationController;

@property (nonatomic, strong) CJPayHintInfo *hintInfo;
@property (nonatomic, strong) CJPayPayAgainHalfViewController *payAgainVC;

@property (nonatomic, strong) CJPayTimerManager *timerManager;
@property (nonatomic, assign) BOOL isIgnoreResponse;
@property (nonatomic, assign) BOOL isRepeatByErrorResponse;
@property (nonatomic, copy) NSDictionary *dataDict;
@property (nonatomic, assign) CJPayCreditPayServiceResultType creditPayActivationResultType;

@property (nonatomic, strong) CJPayFrontCashierContext *payContext;
@property (nonatomic, copy) NSString *scene;

@property (nonatomic, strong) CJPaySuperPayQueryResponse *queryResponse;
@property (nonatomic, copy) NSString *toastLogo;
@end

@implementation CJPaySuperPayController

- (instancetype)init {
    self = [super init];
    if (self) {
        _isIgnoreResponse = NO;
        _isRepeatByErrorResponse = NO;
    }
    return self;
}

- (void)startQueryResultWithParams:(NSDictionary *)dict {
    self.isIgnoreResponse = NO;
    self.isRepeatByErrorResponse = NO;
    self.dataDict = [dict copy];
    self.tradeNo = [dict cj_stringValueForKey:@"out_trade_no"];
    self.scene = CJString([dict cj_stringValueForKey:@"scene"]);
    [self.timerManager startTimer:([CJPaySettingsManager shared].currentSettings.loadingConfig.superPayLoadingTimeOut ?: 6)];
    self.toastLogo = CJString([self.dataDict cj_stringValueForKey:@"toast_logo"]);
    if (![self.scene isEqualToString:@"sign_and_pay_query"]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeSuperPayLoading title:CJPayLocalizedStr(@"极速付款中") logo:self.toastLogo];
    }
    [self p_queryResult:[self p_buildQueryParams:self.dataDict]];
}

- (void)startVerifyWithChannelData:(NSString *)channelData completion:(void (^)(CJPayOrderStatus, NSString * _Nonnull))completion {
    
    self.bdCreateResponse = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:@{@"response": [channelData cj_toDic] ?: @{}} error:nil];
    if (!self.payContext) {//加验需要一些信息
        self.payContext = [CJPayFrontCashierContext new];
        self.payContext.defaultConfig = [CJPayDefaultChannelShowConfig new];
        self.payContext.defaultConfig.mobile = Check_ValidString(self.bdCreateResponse.userInfo.mobile) ? self.bdCreateResponse.userInfo.mobile : CJString([self.bdCreateResponse.tradeConfirmInfo cj_stringValueForKey:@"mobile"]);
    }
    
    self.completionBlock = completion;
    [self.verifyManager begin];
}

//极速付引导二次支付
- (void)payAgainWithResponse:(CJPaySuperPayQueryResponse *)response completion:(void (^)(void))completion {
    self.payAgainVC = [CJPayPayAgainHalfViewController new];
    self.payAgainVC.hintInfo = response.hintInfo;
    self.payAgainVC.verifyManager = self.verifyManager;
    self.payAgainVC.isSuperPay = YES;
    self.payAgainVC.delegate = self;
    @CJWeakify(self);
    self.payAgainVC.closeActionCompletionBlock = ^(BOOL success) {
        @CJStrongify(self);
        CJ_CALL_BLOCK(self.completion, CJPayResultTypeCancel, response);
    };
    [self push:self.payAgainVC animated:YES];
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

#pragma mark - private method
- (void)p_queryResult:(NSDictionary *)params {
    if (self.isIgnoreResponse) {
        [self p_handleQueryResult:NULL];
        return;
    }
    [CJPaySuperPayQueryRequest startWithRequestparams:params completion:^(NSError * _Nonnull error, CJPaySuperPayQueryResponse * _Nonnull response) {
        if (self.isIgnoreResponse) {
            [self p_handleQueryResult:NULL];
            return;
        }
        if ([self p_isEndQuery:response]) {
            [self.timerManager stopTimer];
            [self p_handleQueryResult:response];
        } else {
            if (![self.scene isEqualToString:@"sign_and_pay_query"]) {
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeSuperPayLoading title:response.loadingMsg?:CJPayLocalizedStr(@"极速付款中") logo:self.toastLogo];
            }
            @CJWeakify(self)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(([CJPaySettingsManager shared].currentSettings.loadingConfig.superPayLoadingQueryInterval ?: 500) * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
                [weak_self p_queryResult:params];
            });
        }
    }];
}

- (void)p_handleQueryResult:(CJPaySuperPayQueryResponse *)response {
    [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeSuperPayLoading];
    self.queryResponse = response;
    self.hintInfo = response.hintInfo;
    self.verifyManager.hintInfo = response.hintInfo;
    if (self.payAgainVC) {  //极速付开通并支付流程不走二次支付
        [self.payAgainVC  dismissViewControllerAnimated:YES completion:nil];
        self.payAgainVC = nil;
    }
    if (response.sdkInfo && [response.sdkInfo btd_jsonDictionary].count>0) {
        [self p_handleRiskVerify:response];
        return;
    }
    CJPaySuperPayResultType resultType = [self p_getResultType:response];
    [self p_trackerWithResponse:[self p_buildTrackParams:response]];
    @CJWeakify(self)
    switch (resultType)  {
        case CJPaySuperPayResultTypeSuccess: {
            if (self.queryResponse.showToast) {
                [self p_showSuccessToast:response.paymentInfo];
            }
            [self p_stopLoadingWithCompletion:^{
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.completion, CJPayResultTypeSuccess, response);
            }];
            
        }
            break;
        case CJPaySuperPayResultTypeFail: {
            if (Check_ValidString(response.payAgainInfo)) {
                [self payAgainWithResponse:response completion:nil];
            } else {
                [self p_showResultToast:response.loadingMsg?:@"极速付款失败" subTitle:response.loadingSubMsg?:@"将跳转并继续支付"];
                [self p_stopLoadingWithCompletion:^{
                    @CJStrongify(self)
                    CJ_CALL_BLOCK(self.completion, CJPayResultTypeFail, nil);
                }];
            }
            }
            break;
        case CJPaySuperPayResultTypeTimeOut: {
            [self p_showResultToast:response.loadingMsg?:@"极速付款超时" subTitle:response.loadingSubMsg?:@"将跳转并继续支付"];
            [self p_stopLoadingWithCompletion:^{
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.completion, CJPayResultTypeProcessing, nil);
            }];
            }
            break;
        case CJPaySuperPayResultTypeProcessing:
        default:
            CJ_CALL_BLOCK(self.completion, CJPayResultTypeProcessing, nil);
            break;
    }
}

- (BOOL)p_isEndQuery:(CJPaySuperPayQueryResponse * _Nonnull)response {
    if (!response) { //接口超时
        return YES;
    }
    
    if (![response isSuccess] || !Check_ValidString(response.payStatus)) {
        if (!self.isRepeatByErrorResponse) {
            self.isRepeatByErrorResponse = YES;
            return NO;
        } else {
            return YES;
        }
    }
    if (response.sdkInfo) { //加验停止查单
        return YES;
    }
    if ([response.payStatus isEqualToString:@"PROCESSING"]) {
        return NO;
    } else if ([response.payStatus isEqualToString:@"FAIL"]) {
        return YES;
    } else if ([response.payStatus isEqualToString:@"FINISHED"]) {
        return YES;
     } else {
        return NO;
    }
}

- (void)p_handleRiskVerify:(CJPaySuperPayQueryResponse *)response { //极速付加验走极速支付链路
    [[CJPayLoadingManager defaultService] stopLoading];
    @CJWeakify(self)
    [self startVerifyWithChannelData:response.sdkInfo completion:^(CJPayOrderStatus orderStatus, NSString * _Nonnull msg) {
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] stopLoading];
        if (self.navigationController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                [self p_processResultWithOrderStatus:orderStatus];
            }];
        } else {
            [self p_processResultWithOrderStatus:orderStatus];
        }
    }];
    return;
}

- (CJPaySuperPayResultType)p_getResultType:(CJPaySuperPayQueryResponse *)response {
    if (!response || !Check_ValidString(response.payStatus)) {
        return CJPaySuperPayResultTypeTimeOut;
    }
    if ([response.payStatus isEqualToString:@"PROCESSING"]) {
        return CJPaySuperPayResultTypeProcessing;
    } else if ([response.payStatus isEqualToString:@"FAIL"]) {
        return CJPaySuperPayResultTypeFail;
    } else if ([response.payStatus isEqualToString:@"FINISHED"]) {
        return CJPaySuperPayResultTypeSuccess;
    } else {
        return CJPaySuperPayResultTypeProcessing;
    }
}

- (void)p_showResultToast:(NSString *)msg subTitle:(NSString *)subMsg {
    UIView *resultView = [[CJPaySuperPayResultView alloc] initWithTitle:CJPayLocalizedStr(msg) subTitle:CJPayLocalizedStr(subMsg)];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeSuperPayLoading withView:resultView];
}

- (void)p_showSuccessToast:(CJPayPaymentInfoModel *)paymentInfo {
    UIView *resultView = [[CJPaySuperPayResultView alloc] initWithModel:paymentInfo];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeSuperPayLoading withView:resultView];
}

- (void)p_stopLoadingWithCompletion:(void(^__nullable)(void))completion {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(([CJPaySettingsManager shared].currentSettings.loadingConfig.superPayLoadingStayTime ?: 500) * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        [[CJPayLoadingManager defaultService] stopLoading];
        CJ_CALL_BLOCK(completion);
    });
}

- (void)p_processResultWithOrderStatus:(CJPayOrderStatus)orderStatus {
    if (orderStatus == CJPayOrderStatusSuccess) {
        if (self.queryResponse.showToast) {
            [self p_showSuccessToast:self.queryResponse.paymentInfo];
            @CJWeakify(self)
            [self p_stopLoadingWithCompletion:^{
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.completion, CJPayResultTypeSuccess, self.queryResponse);
            }];
        } else {
            CJ_CALL_BLOCK(self.completion, CJPayResultTypeSuccess, self.queryResponse);
        }
        
    } else if(orderStatus == CJPayOrderStatusCancel) {
        CJ_CALL_BLOCK(self.completion, CJPayResultTypeCancel, nil);
    } else {
        CJ_CALL_BLOCK(self.completion, CJPayResultTypeFail, nil);
    }
}

- (CJPayHalfPageBaseViewController *)p_hanldeHalfViewController:(CJPayHalfPageBaseViewController *)halfVC
{
    if ([self p_topVCIsHalfVC]) {
        [halfVC showMask:NO];
        halfVC.animationType = HalfVCEntranceTypeFromRight;
    } else {
        halfVC.animationType = HalfVCEntranceTypeFromBottom;
        [halfVC showMask:NO];
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

//二次支付绑卡lynx
- (void)p_LynxBindCard {
    [self.verifyManager onBindCardAndPayAction];//极速付仅lynx绑卡
}
//新客激活月付
- (void)p_activateCredit {
    @CJWeakify(self)
    [CJPayCreditPayUtil activateCreditPayWithStatus:self.payContext.defaultConfig.isCreditActivate activateUrl:self.payContext.defaultConfig.creditActivateUrl completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg, NSInteger creditLimit, CJPayCreditPayActivationLoadingStyle style, NSString * _Nonnull token) {
        @CJStrongify(self)
        self.creditPayActivationResultType = type;
        self.verifyManager.token = token;
        switch (type) {
            case CJPayCreditPayServiceResultTypeSuccess:
            case CJPayCreditPayServiceResultTypeActivated:
                [self p_creditSign];
                break;
            case CJPayCreditPayServiceResultTypeNoUrl:
            case CJPayCreditPayServiceResultTypeNoNetwork:
            case CJPayCreditPayServiceResultTypeFail:
                if (style == CJPayCreditPayActivationLoadingStyleNew) {
                    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"抖音月付激活失败")];
                    [self p_stopLoadingWithCompletion:^{
                        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCEventClosePayDesk];
                        CJ_CALL_BLOCK(self.completion, CJPayResultTypeFail, nil);
                    }];
                }
                break;
            case CJPayCreditPayServiceResultTypeCancel:
                [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCEventClosePayDesk];
                CJ_CALL_BLOCK(self.completion, CJPayResultTypeCancel, nil);
                break;
            case CJPayCreditPayServiceResultTypeTimeOut:
                if (style == CJPayCreditPayActivationLoadingStyleNew) {
                    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"抖音月付激活超时")];
                }
            default:
                [self p_stopLoadingWithCompletion:^{
                    [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCEventClosePayDesk];
                    CJ_CALL_BLOCK(self.completion, CJPayResultTypeFail, nil);
                }];
                break;
        }
    }];
}
//老客月付签约极速付
- (void)p_creditSign {
    NSString *signSchema = self.payContext.defaultConfig.creditSignUrl;
    @CJWeakify(self)
    [self p_creditSignSuperWithSignUrl:signSchema completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg) {
        @CJStrongify(self)
        switch (type) {
            case CJPayCreditPayServiceResultTypeSuccess:{
                NSDictionary *params = @{
                    @"channel_code" : @"CREDIT_PAY"
                };
                [self p_payAgainWithParams:params];
                break;
            }
            case CJPayCreditPayServiceResultTypeCancel:
                [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCEventClosePayDesk];
                CJ_CALL_BLOCK(self.completion, CJPayResultTypeCancel, nil);
                break;
            case CJPayCreditPayServiceResultTypeNoUrl:
            case CJPayCreditPayServiceResultTypeNoNetwork:
            case CJPayCreditPayServiceResultTypeFail:
            case CJPayCreditPayServiceResultTypeTimeOut:
            default:
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinFailLoading title:CJPayLocalizedStr(@"抖音月付授权失败")];
                [self p_stopLoadingWithCompletion:^{
                    [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCEventClosePayDesk];
                    CJ_CALL_BLOCK(self.completion, CJPayResultTypeFail, nil);
                }];
                break;
        }
    }];
}

- (void)p_payAgainWithParams:(NSDictionary *)params {
    NSDictionary *requestParams = [self p_buildRequestParams:params];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeSuperPayLoading title:CJPayLocalizedStr(@"极速付款中") logo:self.toastLogo];
    @CJWeakify(self)
    [CJPayDeductAgainRequest startWithRequestparams:requestParams completion:^(NSError * error, CJPayDeductAgainResponse * response) {\
        @CJStrongify(self)
        if (!response || !Check_ValidString(response.payStatus) || [response.payStatus isEqualToString:@"FAIL"]) {
            [self p_showResultToast:@"极速付款失败" subTitle:@"将跳转并继续支付"];
            [self p_stopLoadingWithCompletion:^{
                CJ_CALL_BLOCK(self.completion, CJPayResultTypeFail, nil);
                [self.payAgainVC dismissViewControllerAnimated:YES completion:nil];
            }];
        } else {
            self.isIgnoreResponse = NO;
            self.isRepeatByErrorResponse = NO;
            [self.timerManager startTimer:([CJPaySettingsManager shared].currentSettings.loadingConfig.superPayLoadingTimeOut ?: 6)];
            [self p_queryResult:[self p_buildQueryParams:self.dataDict]];
        }
    }];
}

- (NSDictionary *)p_buildRequestParams:(NSDictionary *)params {
    NSMutableDictionary *requestParams = [NSMutableDictionary new];
    NSMutableDictionary *bizContent = [NSMutableDictionary new];
    [bizContent addEntriesFromDictionary:params];
    [bizContent cj_setObject:CJString([self.dataDict cj_stringValueForKey:@"out_trade_no"]) forKey:@"out_trade_no"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContent] forKey:@"biz_content"];
    [requestParams cj_setObject:CJString(self.hintInfo.merchantInfo.merchantId) forKey:@"merchant_id"];
    [requestParams cj_setObject:CJString(self.hintInfo.merchantInfo.appId) forKey: @"app_id"];
    [requestParams cj_setObject:@"tp.quick_pay.deduct_again" forKey:@"method"];
    return requestParams;
}

- (void)p_creditSignSuperWithSignUrl:(NSString *)signUrl completion:(void (^)(CJPayCreditPayServiceResultType, NSString * _Nonnull))completion {
    NSString *schema = signUrl;
    if (!Check_ValidString(schema)) {
        CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeNoUrl, CJPayLocalizedStr(@"无法进入抖音月付授权流程，请您联系客服"));
        CJPayLogAssert(NO, @"没有下发抖音月付授权的 URL，请检查接口数据");
        return;
    }
    
    void(^callbackBlock)(CJPayAPIBaseResponse * _Nonnull) = ^(CJPayAPIBaseResponse * _Nonnull response) {
        if (!response.data && response.error) {
            CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeNoNetwork, CJPayLocalizedStr(CJPayNoNetworkMessage));
            return;
        }
        
        if (response.data != nil && [response.data isKindOfClass:[NSDictionary class]]) {
            NSDictionary *dic;
            if ([response.data btd_dictionaryValueForKey:@"data"]) {
                dic = [[response.data btd_dictionaryValueForKey:@"data"] btd_dictionaryValueForKey:@"msg"];
            } else {
                dic = (NSDictionary *)response.data;
            }
            NSString *process = [dic cj_stringValueForKey:@"process"];
            if ([process isEqualToString:@"super_pay_sign_credit"]) {
                NSInteger code = [dic cj_integerValueForKey:@"code"];
                if (code == 0) {
                    CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeSuccess, CJPayLocalizedStr(@"抖音月付授权成功"));
                } else if (code == 1) {
                    CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeCancel, CJPayLocalizedStr(@"取消抖音月付授权"));
                } else if (code == 2) {
                    CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeFail, CJPayLocalizedStr(@"抖音月付授权超时"));
                } else {
                    CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeTimeOut, CJPayLocalizedStr(@"抖音月付授权超时"));
                }
            } else {
                CJ_CALL_BLOCK(completion, CJPayCreditPayServiceResultTypeCancel, CJPayLocalizedStr(@"取消抖音月付授权"));
            }
        }
    };
    [CJPayDeskUtil openLynxPageBySchema:schema
                           completionBlock:callbackBlock];
}


#pragma mark - CJPayPayAgainDelegate
- (void)payWithContext:(CJPayFrontCashierContext *)context loadingView:(UIView *)loadingView {
    self.payContext = context;
    NSMutableDictionary *extParams = [NSMutableDictionary new];
    [extParams addEntriesFromDictionary:context.extParams];
    [extParams cj_setObject:([self.dataDict cj_dictionaryValueForKey:@"track_info"] ? : @{}) forKey:@"track_info"];
    self.payContext.extParams = extParams;
    self.verifyManager.payContext = self.payContext;
    CJPayChannelType channelType = context.defaultConfig.type;
    
    if (channelType == BDPayChannelTypeAddBankCard) {
        [self p_LynxBindCard];
        return;
    } else if(channelType == BDPayChannelTypeCreditPay){
        if (!context.defaultConfig.isCreditActivate) {
            [self p_activateCredit];
        } else {
            [self p_creditSign];
        }
    } else {
        CJ_CALL_BLOCK(self.completion, CJPayOrderStatusFail, nil);//目前不支持其他方式
    }
}

#pragma mark -  CJPayBaseLoadingProtocol

- (void)startLoading {
    if (![[UIViewController cj_topViewController] isKindOfClass: CJPaySuperPayController.class] &&
        [[UIViewController cj_topViewController] isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeSuperPayLoading title:CJPayLocalizedStr(@"极速付款中") logo:self.toastLogo];
    }
}

- (void)stopLoading {
    [[CJPayLoadingManager defaultService] stopLoading];
}

#pragma mark - Tracker
- (void)p_trackerWithResponse:(NSDictionary *)trackerParams {
    NSMutableDictionary *params = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"pswd_pay_type" : @"2",// 2 极速付
        @"check_type" : @"无",
        @"activity_info" : @"", // 空
        @"risk_type" : @"无",
        @"is_chaselight" : @"0",
        @"identity_type" : @"1",
        @"trade_no" : CJString(self.tradeNo),
        @"pre_method" : @"Pre_Pay_SuperPay"
    }];
    [params addEntriesFromDictionary:trackerParams];
    [params addEntriesFromDictionary:[self.dataDict cj_dictionaryValueForKey:@"track_info"]];
    [CJTracker event:@"wallet_cashier_result" params:params];
}

- (NSDictionary *)p_buildQueryParams:(NSDictionary *)params {
    NSMutableDictionary *queryParams = [[NSMutableDictionary alloc] initWithDictionary:params];
    if ([queryParams btd_dictionaryValueForKey:@"track_info"]) {
        [queryParams removeObjectForKey:@"track_info"];
    }
    if ([queryParams btd_dictionaryValueForKey:@"bind_card_info"]) {
        [queryParams removeObjectForKey:@"bind_card_info"];
    }
    return [queryParams copy];
}

- (NSDictionary *)p_buildTrackParams:(CJPaySuperPayQueryResponse *)response {
    NSString *errorMessage,*errorCode,*status;
    if (!response || [response.payStatus isEqualToString:@"PROCESSING"]) {
        errorMessage = @"极速付款超时";
        errorCode = @"-1";
        status = @"超时";
    } else {
        errorMessage = Check_ValidString(response.msg) ? CJString(response.msg) : CJString(response.loadingMsg);
        errorCode = CJString(response.code);
        status = [response.payStatus isEqualToString:@"FAIL"] ? @"失败" : @"成功";
    }
    NSMutableDictionary *trackParams = [[NSMutableDictionary alloc] initWithDictionary:@{
        @"result" : [response.payStatus isEqualToString:@"FINISHED"] ? @"1" : @"0",
        @"status" : CJString(status),
        @"error_code" : CJString(errorCode),
        @"error_message" : CJString(errorMessage),
    }];
    return [trackParams copy];
}

- (void)p_presentVC:(UIViewController *)vc animated:(BOOL)animated {
    
    UIViewController *topVC = [UIViewController cj_topViewController];
    BOOL newNavUseMask = YES;
    
    if ([vc isKindOfClass:[CJPayHalfPageBaseViewController class]]) {
        CJPayHalfPageBaseViewController *halfVC = (CJPayHalfPageBaseViewController *)vc;
        halfVC = [self p_handlePushHalfViewController:halfVC];
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
}

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

#pragma mark - CJVerifyModulePageFlowProtocol
- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
    UIViewController *topVC = [UIViewController cj_topViewController];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.navigationController && topVC.navigationController == self.navigationController) {
            [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
           
        } else if (self.navigationController.presentingViewController) {
            [self.navigationController.presentingViewController dismissViewControllerAnimated:NO completion:nil];
        }
    });
}

#pragma mark - CJPayHomeVCProtocol
- (CJPayBDCreateOrderResponse *)createOrderResponse {
    return self.bdCreateResponse;
}

- (CJPayDefaultChannelShowConfig *)curSelectConfig {
    return self.payContext.defaultConfig;
}

- (CJPayVerifyType)firstVerifyType {
    NSString *confirmCode = [self.bdCreateResponse.tradeConfirmInfo cj_stringValueForKey:@"code"];
    [CJTracker event:@"wallet_rd_present_notcjpay"
              params:@{@"isSuperPay":@(YES),
                       @"abVersion": @"new",
                       @"superPayVerifyCode": CJString(confirmCode)}];
    if (confirmCode && [[self codeVerifyItemDic] objectForKey:CJString(confirmCode)]) {
        return [[self codeVerifyItemDic] cj_integerValueForKey:CJString(confirmCode)];
    } else {
//        [CJToast toastText:@"没有找到追光的首次加验方式!!!" inWindow:self.cj_window];
        return CJPayVerifyTypePassword;
    }
}

- (NSDictionary *)codeVerifyItemDic {
    return  @{
        @"CD002005": @(CJPayVerifyTypePassword),
        @"CD002008": @(CJPayVerifyTypePassword),
        @"CD002006": @(CJPayVerifyTypeBioPayment),
        @"CD002007": @(CJPayVerifyTypeBioPayment),
        @"CD002001": @(CJPayVerifyTypeSMS),
        @"CD002104": @(CJPayVerifyTypeFaceRecog),
        @"CD001001": @(CJPayVerifyTypeIDCard),
        @"CD005010": @(CJPayVerifyTypeUploadIDCard),
        @"CD002003": @(CJPayVerifyTypeAddPhoneNum)
    };
}

- (BOOL)receiveDataBus:(CJPayHomeVCEvent)eventType obj:(id)object {
    switch (eventType) {
        case CJPayHomeVCEventUserCancelRiskVerify:
            CJ_CALL_BLOCK(self.completionBlock, CJPayOrderStatusCancel, @"风控加验取消");
            break;
        case CJPayHomeVCEventOccurUnHandleConfirmError:
            CJ_CALL_BLOCK(self.completionBlock, CJPayOrderStatusFail, @"confirm接口报错");
            break;
        case CJPayHomeVCEventSuperBindCardFinish:{
            if (object && [object isKindOfClass:NSDictionary.class]) {
                NSDictionary *params = (NSDictionary *)object;
                if (!Check_ValidString([params cj_stringValueForKey:@"channel_code"])) {
                    CJ_CALL_BLOCK(self.completion, CJPayResultTypeFail, nil);
                    [self.payAgainVC dismissViewControllerAnimated:YES completion:nil];
                } else {
                    [self p_payAgainWithParams:params];
                }
            } else {//参数错误，直接返回
                CJ_CALL_BLOCK(self.completion, CJPayResultTypeFail, nil);
                [self.payAgainVC dismissViewControllerAnimated:YES completion:nil];
            }
        }
            break;
        default:
            break;
    }
    return YES;
}

- (void)push:(UIViewController *)vc animated:(BOOL)animated {
    // 极速支付需要拦截风控页面的返回，回调给聚合收银台
    NSArray *riskHomeVCList = @[@"CJPayHalfVerifySMSViewController",
                                @"CJPayVerifySMSViewController",
                                @"CJPayBizWebViewController",
                                @"CJPayVerifyIDCardViewController",
                                @"CJPayVerifyPassPortViewController",
                                @"CJPayHalfVerifyPasswordNormalViewController",
                                @"CJPayBDBioConfirmViewController"];
    
    NSString *vcTypeStr = NSStringFromClass([vc class]);
    if (vcTypeStr && [riskHomeVCList containsObject:vcTypeStr]) {
        @CJWeakify(self)
        vc.cjBackBlock = ^{
            @CJStrongify(self)
            if (!self.navigationController) {
                CJ_CALL_BLOCK(self.completionBlock,CJPayOrderStatusCancel, @"极速付取消");
            } else {
                [self.navigationController dismissViewControllerAnimated:YES completion:^{
                    CJ_CALL_BLOCK(self.completionBlock,CJPayOrderStatusCancel, @"极速付取消");
                }];
            }
        };
    }
    
    UIViewController *topVC = [UIViewController cj_topViewController];
    // 需要新起导航栈
    if (topVC.navigationController != self.navigationController || !self.navigationController) {
        [self p_presentVC:vc animated:animated];
    } else {
        
        CJPayNavigationController *navi = self.navigationController;
        if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            [self p_handlePushHalfViewController:(CJPayHalfPageBaseViewController *)vc];
        }

        [navi pushViewController:vc animated:animated];
    }
    
}

- (UIViewController *)topVC {
    return [UIViewController cj_topViewController];
}

- (void)endVerifyWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    // 这里展示结果页
    if (![resultResponse isSuccess]) {
        [CJToast toastText:CJString(resultResponse.msg) inWindow:[self topVC].cj_window];
        CJ_CALL_BLOCK(self.completionBlock, CJPayOrderStatusFail, @"极速付查单报错");
        return;
    }
    CJ_CALL_BLOCK(self.completionBlock, resultResponse.tradeInfo.tradeStatus, @"极速付完成查单");
    return;
}

#pragma mark - Getter
- (CJPaySuperPayVerifyManagerQueen *)verifyManagerQueen {
    if (!_verifyManagerQueen) {
        _verifyManagerQueen = [[CJPaySuperPayVerifyManagerQueen alloc] init];
        [_verifyManagerQueen bindManager:self.verifyManager];
    }
    return _verifyManagerQueen;
}

- (CJPaySuperPayVerifyManager *)verifyManager {
    if (!_verifyManager) {
        _verifyManager = [CJPaySuperPayVerifyManager managerWith:self];
        _verifyManager.verifyManagerQueen = self.verifyManagerQueen;
    }
    return _verifyManager;
}

- (CJPayTimerManager *)timerManager {
    if (!_timerManager) {
        _timerManager = [CJPayTimerManager new];
        @CJWeakify(self)
        _timerManager.timeOutBlock = ^{
            @CJStrongify(self)
            self.isIgnoreResponse = YES;
        };
    }
    return _timerManager;
}

@end

