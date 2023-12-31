//
//  CJPayBizDYPayController.m
//  CJPaySandBox
//
//  Created by wangxiaohong on 2022/11/7.
//

#import "CJPayBizDYPayController.h"

#import "CJPayBizDYPayVerifyManager.h"
#import "CJPayBizDYPayVerifyManagerQueen.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPaySkippwdGuideUtil.h"
#import "CJPayBDResultPageViewController.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayPayAgainHalfViewController.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayCombineLimitViewController.h"
#import "CJPayHintInfo.h"
#import "CJPayCombinePayLimitModel.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayBizDYPayPlugin.h"
#import "CJPayHomePageViewController.h"
#import "CJPayCreditPayUtil.h"
#import "CJPayFullResultPageViewController.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayOrderResultRequest.h"
#import "CJPayWebViewUtil.h"
#import "CJPayChooseDyPayMethodManager.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPayDeskUtil.h"
#import "CJPayBioPaymentPlugin.h"
#import "CJPayFrontCashierResultModel.h"
#import "CJPayResultPageModel.h"

@interface CJPayBizDYPayController()<CJPayBizDYPayPlugin, CJPayHomeVCProtocol, CJPayPayAgainDelegate, CJPayChooseDyPayMethodDelegate>

@property (nonatomic, weak) CJPayHomePageViewController *homeVC;
@property (nonatomic, strong) CJPayBizDYPayVerifyManager *verifyManager;
@property (nonatomic, strong) CJPayBizDYPayVerifyManagerQueen *verifyManagerQueen;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *bdCreateResponse;
@property (nonatomic, strong) CJPayBDOrderResultResponse *bdResultResponse;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *currentPayConfig;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultPayConfig;
@property (nonatomic, strong) NSMutableDictionary *payDisabledFundID2ReasonMap;

@property (nonatomic, weak) CJPayIntegratedCashierProcessManager *processManager;  // 流程控制
@property (nonatomic, strong) CJPayBizDYPayModel *dypayModel;
@property (nonatomic, copy) void(^completionBlock)(CJPayOrderStatus orderStatus, CJPayBDOrderResultResponse * _Nonnull response);
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *bindcardPayConfig; //支付中选择绑卡时，单独存储绑卡支付方式
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *signCardShowConfig; //支付中选择补签约卡时，单独存储绑卡支付方式

@end

@implementation CJPayBizDYPayController

CJPAY_REGISTER_PLUGIN({
    CJPayRegisterCurrentClassToPtocol(self, CJPayBizDYPayPlugin);
});

- (void)dyPayWithModel:(nonnull CJPayBizDYPayModel *)model completion:(nonnull void (^)(CJPayOrderStatus, CJPayBDOrderResultResponse * _Nonnull))completion {
    self.dypayModel = model;
    self.completionBlock = completion;
    CJPayBDCreateOrderResponse *bdCreateResponse = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:@{@"response": [model.createResponseStr cj_toDic] ?: @{}} error:nil];
    bdCreateResponse.intergratedTradeIdentify = CJString(model.intergratedTradeIdentify);
    bdCreateResponse.cj_merchantID = CJString(model.cj_merchantID);
    self.bdCreateResponse = bdCreateResponse;
    self.defaultPayConfig = model.showConfig;
    self.currentPayConfig = model.showConfig;
    self.homeVC = model.homeVC;
    self.processManager = model.processManager;
    self.verifyManager.trackParams = model.trackParams;
    self.verifyManager.notStopLoading = [model.jhResultPageStyle isEqualToString:@"1"];
    self.verifyManager.isPaymentForOuterApp = model.isPaymentForOuterApp;
    self.verifyManager.changePayMethodDelegate = self;
    self.verifyManager.verifyManagerQueen = self.verifyManagerQueen;
    [self p_updateDefaultPayConfig];
    if (self.currentPayConfig.type == BDPayChannelTypeAddBankCard) {
        [self.verifyManager onBindCardAndPayAction];
    } else {
        if ([self p_isNeedActivateCreditPay]) {
            [self p_activateCreditPay];
        } else {
            [self.verifyManager begin];
        }
    }
}

- (BOOL)p_isNeedActivateCreditPay {
    CJPayChannelType channelType = [CJPayBDTypeInfo getChannelTypeBy:self.createOrderResponse.payInfo.businessScene];
    BOOL hasActivateCredit = self.currentPayConfig.payTypeData.isCreditActivate;
    if (channelType == BDPayChannelTypeCreditPay && !self.createOrderResponse.payInfo.isCreditActivate && !hasActivateCredit) {
        return YES;
    }
    return NO;
}

- (void)p_activateCreditPay {
    @CJWeakify(self)
    [CJPayCreditPayUtil activateCreditPayWithPayInfo:self.createOrderResponse.payInfo completion:^(CJPayCreditPayServiceResultType type, NSString * _Nonnull msg, NSInteger creditLimit, CJPayCreditPayActivationLoadingStyle style, NSString * _Nonnull token) {
        @CJStrongify(self)
        switch (type) {
            case CJPayCreditPayServiceResultTypeActivated:
                [self.verifyManager begin];
                break;
            case CJPayCreditPayServiceResultTypeNoUrl:
            case CJPayCreditPayServiceResultTypeNoNetwork:
            case CJPayCreditPayServiceResultTypeFail: {
                [self p_gotoCardListWithTipsMsg:msg disableMsg:CJPayLocalizedStr(@"激活失败")];
                break;
            }
            case CJPayCreditPayServiceResultTypeSuccess: {
                self.currentPayConfig.payTypeData.isCreditActivate = YES;
                if (creditLimit != -1) { // 有额度
                    [self p_creditAmountComparisonWithAmount:creditLimit successDesc:msg];
                } else {
                    [self p_successActiveAndPay:msg];
                }
                break;
            }
            case CJPayCreditPayServiceResultTypeCancel:
                break;
            case CJPayCreditPayServiceResultTypeTimeOut:
            default:{
                [self p_gotoCardListWithTipsMsg:msg disableMsg:CJPayLocalizedStr(@"激活超时")];
                break;
            }
        }
    }];
}

- (void)p_creditAmountComparisonWithAmount:(NSInteger)amount successDesc:(NSString *)desc {
    CJPayBDCreateOrderResponse *response = self.createOrderResponse;
    if (response.payInfo.realTradeAmountRaw > amount) {
        [self p_gotoCardListWithTipsMsg:CJPayLocalizedStr(@"抖音月付激活成功，额度不足，请更换支付方式") disableMsg:@"额度不足"];
    } else {
        [self p_successActiveAndPay:desc];
    }
}

- (void)p_gotoCardListWithTipsMsg:(NSString *)tipsMsg disableMsg:(NSString *)disableMsg {
    if ([self.homeVC respondsToSelector:@selector(creditPayFailWithTipsMsg:disableMsg:)]) {
        [self.homeVC creditPayFailWithTipsMsg:CJString(tipsMsg) disableMsg:CJString(disableMsg)];
    }
}

- (void)p_successActiveAndPay:(NSString *)successDesc {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CJToast toastText:successDesc inWindow:[UIViewController cj_topViewController].cj_window];
    });
    [self.verifyManager begin];
}

#pragma mark - CJPayHomeVCProtocol

- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
    [self.homeVC.countDownView invalidate];
    CJPayOrderStatus orderStatus = CJPayOrderStatusNull;
    switch (source) {
        case CJPayHomeVCCloseActionSourceFromBack:
        case CJPayHomeVCCloseActionSourceFromCloseAction:
            orderStatus = CJPayOrderStatusCancel;
            break;
        case CJPayHomeVCCloseActionSourceFromOrderTimeOut:
            orderStatus = CJPayOrderStatusTimeout;
            break;
        default:
            orderStatus = CJPayOrderStatusNull;
    }
    if (time < 0) {
        return;
    }
    @CJWeakify(self)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self)
        [self p_dismissAllVCWithAnimated:YES completion:^{
            @CJStrongify(self)
            [self p_callBackWithOrderResultResponse:self.bdResultResponse orderStatus:orderStatus];
        }];
    });
}

- (void)p_dismissAllVCWithAnimated:(BOOL)isAnimated completion:(void (^)(void))completion {
    if (self.homeVC.presentingViewController) {
        [self.homeVC.presentingViewController dismissViewControllerAnimated:isAnimated completion:completion];
    } else if (self.homeVC) {
        [self.homeVC dismissViewControllerAnimated:isAnimated completion:completion];
    } else {
        CJ_CALL_BLOCK(completion);
    }
}

- (void)startLoading {
    [self.homeVC startLoading];
}

- (void)stopLoading {
    [self.homeVC stopLoading];
}

- (nullable CJPayBDCreateOrderResponse *)createOrderResponse {
    return self.bdCreateResponse;
}

- (BOOL)p_isPasswordV2Style {
    return Check_ValidArray(self.createOrderResponse.payInfo.subPayTypeDisplayInfoList);
}

- (nullable CJPayDefaultChannelShowConfig *)curSelectConfig {
    if ([self p_isPasswordV2Style] && self.verifyManager.isBindCardAndPay && self.bindcardPayConfig) {
        return self.bindcardPayConfig;
    }
    
    if ([self p_isPasswordV2Style] && self.signCardShowConfig) {
        return self.signCardShowConfig;
    }
    
    return self.currentPayConfig;
}

- (CJPayVerifyType)firstVerifyType {
    CJPayVerifyType type = [self.verifyManager getVerifyTypeWithPwdCheckWay:self.bdCreateResponse.userInfo.pwdCheckWay];
    if (self.bdCreateResponse.needResignCard || [self.currentPayConfig isNeedReSigning]) {
        type = CJPayVerifyTypeSignCard;
    }
    return type;
}

- (void)push:(nonnull UIViewController *)vc animated:(BOOL)animated {
    [self.homeVC.navigationController pushViewController:vc animated:animated];
}

- (BOOL)receiveDataBus:(CJPayHomeVCEvent)eventType obj:(nonnull id)object {
    switch (eventType) {
        case CJPayHomeVCEventShowState:
            [self.homeVC showState:[object integerValue]];
            break;
        case CJPayHomeVCEventNotifySufficient:
            [self p_notifyNotSufficientFunds:object];
            break;
        case CJPayHomeVCEventPayMethodDisabled:
            [self p_handlePayMethodDisabled:object];
            break;
        case CJPayHomeVCEventBindCardNoPwdCancel:
        case CJPayHomeVCEventDismissAllAboveVCs:
            [self p_dismissAllVCAboveCurrent:[object boolValue]];
            break;
        case CJPayHomeVCEventCombinePayLimit:
            [self p_combinePayLimitWithModel:object];
            break;
        case CJPayHomeVCEventPayLimit:
            if ([object isKindOfClass:[CJPayOrderConfirmResponse class]]) { //支付触发受限
                CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)object;
                [self.homeVC payLimitWithTipsMsg:confirmResponse.changePayTypeDesc iconTips:confirmResponse.iconTips];
            }
            break;
        case CJPayHomeVCEventRefreshTradeCreate:
            [self p_refreshTradeCreateWithModel:object];
            break;
        case CJPayHomeVCEventClosePayDesk:
            [self closeActionAfterTime:0 closeActionSource:[object intValue]];
            break;
        case CJPayHomeVCEventEnableConfirmBtn:
            if ([self.homeVC respondsToSelector:@selector(enableConfirmBtn:)]) {
                [self.homeVC enableConfirmBtn:[object boolValue]];
            }
            break;
        default:
            break;
    }
    return YES;
}

- (nonnull UIViewController *)topVC {
    return [UIViewController cj_foundTopViewControllerFrom:self.homeVC];
}

- (void)endVerifyWithResultResponse:(nullable CJPayBDOrderResultResponse *)resultResponse {
    // 这里展示结果页
    self.bdResultResponse = resultResponse;
    if (![resultResponse isSuccess]) {
        [self stopLoading];//只要失败就把loading关掉
        [self.verifyManager sendEventTOVC:CJPayHomeVCEventShowState obj:@(CJPayStateTypeNone)];
        [CJToast toastText:CJString(resultResponse.msg) inWindow:[self topVC].cj_window];
        return;
    }
    [self.homeVC invalidateCountDownView];
    // 支付中勾选了开通生物识别，查单成功后异步开通生物能力
    if (self.createOrderResponse.preBioGuideInfo != nil && self.verifyManager.isNeedOpenBioPay) {
        CJ_DECLARE_ID_PROTOCOL(CJPayBioPaymentPlugin);
        [objectWithCJPayBioPaymentPlugin asyncOpenBioPayWithResponse:self.createOrderResponse
                                                             lastPWD:self.verifyManager.lastPWD];
        if (!objectWithCJPayBioPaymentPlugin) {
            [CJMonitor trackServiceAllInOne:@"wallet_rd_open_bio_exception"
                                     metric:@{}
                                   category:@{@"cashier_scene": @"standard"}
                                      extra:@{}];
        }
    }
    
    if (![self.dypayModel.jhResultPageStyle isEqualToString:@"1"] || !Check_ValidString(self.dypayModel.intergratedTradeIdentify) || !Check_ValidString(self.dypayModel.processStr) || (resultResponse.tradeInfo.tradeStatus != CJPayOrderStatusSuccess)) {
        [self p_resultPageNative:resultResponse];
    } else {
        [self p_queryBizOrderResult];
    }
    
    if (Check_ValidString(resultResponse.skipPwdOpenMsg)) {
        [CJToast toastText:resultResponse.skipPwdOpenMsg inWindow:[self topVC].cj_window];
    }
}

- (void)p_callBackWithOrderResultResponse:(CJPayBDOrderResultResponse *)resultResponse orderStatus:(CJPayOrderStatus)orderStatus {
    CJ_CALL_BLOCK(self.completionBlock, orderStatus, resultResponse);
}

- (CJPayOrderResultResponse *)p_cjOrderResponsWithBDResultResponse:(CJPayBDOrderResultResponse *)bdResponse {
    CJPayOrderResultResponse *response = [CJPayOrderResultResponse new];
    response.tradeInfo = [CJPayTradeInfo new];
    response.tradeInfo.status = bdResponse.tradeInfo.tradeStatusString;
    return response;
}

- (void)p_showResultPage:(CJPayOrderResultResponse *)cjResultResponse {
    [self stopLoading];
    if (![cjResultResponse isSuccess] || cjResultResponse.tradeInfo.tradeStatus != CJPayOrderStatusSuccess){
        [self p_resultPageNative:self.bdResultResponse];
    } else {
        if (cjResultResponse.resultPageInfo) {
            NSString *CJPayCJOrderResultCacheStringKey = @"CJPayCJPayOrderResultResponse";
            NSString *dataJsonStr = [[[cjResultResponse toDictionary] cj_dictionaryValueForKey:@"data"] btd_jsonStringEncoded];
            if (CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService)) {
                [CJ_OBJECT_WITH_PROTOCOL(CJPayParamsCacheService) i_setParams:dataJsonStr key:CJPayCJOrderResultCacheStringKey];
            }
            
            NSString *renderType = cjResultResponse.resultPageInfo.renderInfo.type;
            if ([renderType isEqualToString:@"native"]) {
                [self p_resultPageLynxCard:cjResultResponse];
            } else if ([renderType isEqualToString:@"lynx"]){
                [self p_resultPageLynx:cjResultResponse];
            } else {//这里不可能下发h5，只可能是错误
                [self p_resultPageNative:self.bdResultResponse];
            }
        } else {
            [self p_resultPageNative:self.bdResultResponse];
        }
    }
}
- (void)p_queryBizOrderResult {
    @CJWeakify(self)
    void(^completion)(NSError *error, CJPayOrderResultResponse *response) = ^(NSError *error, CJPayOrderResultResponse *response){
        @CJStrongify(self)
        [self p_showResultPage:response];
    };
    
    [self p_queryBizOrder:[self.bdCreateResponse.resultConfig queryResultTimes] completion:^(NSError *error, CJPayOrderResultResponse *response) {
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

- (void)p_queryBizOrder:(NSInteger)retryCount completion:(void (^)(NSError * _Nonnull, CJPayOrderResultResponse * _Nonnull))completionBlock {
    @CJWeakify(self)
    NSString *processInfoStr = [@{@"process_info":self.verifyManager.confirmResponse.processInfoDic ?: @{}} cj_toStr];
    [CJPayOrderResultRequest startWithTradeNo:self.dypayModel.intergratedTradeIdentify processInfo:self.dypayModel.processStr bdProcessInfo:processInfoStr completion:^(NSError *error, CJPayOrderResultResponse *response) {
        if ([response.code isEqualToString:@"GW400008"]) {//宿主未登录
            CJ_CALL_BLOCK(completionBlock, error, response);
            return;
        }
        
        if ((response.tradeInfo.tradeStatus == CJPayOrderStatusProcess || ![response isSuccess]) && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weak_self p_queryBizOrder:retryCount - 1 completion:completionBlock];
            });
            return;
        }
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}



- (void)p_resultPageLynx:(CJPayOrderResultResponse *)resultResponse {
    @CJWeakify(self)
    void(^resultPageBlock)(void) = ^(){
        @CJStrongify(self)
        NSString *url = resultResponse.resultPageInfo.renderInfo.lynxUrl;
        CJPayNavigationController *navi = (CJPayNavigationController *)([self topVC].navigationController);
        if (navi) {
            [navi.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        } else if (navi.presentingViewController) {
            [navi.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [CJPayDeskUtil openLynxPageBySchema:url completionBlock:^(CJPayAPIBaseResponse * _Nullable response) {
                [self p_callBackWithOrderResultResponse:self.bdResultResponse orderStatus:self.bdResultResponse.tradeInfo.tradeStatus];
            }];
        });
    };
    [self p_showGuidePageWithResponse:self.bdResultResponse resultPageBlock:resultPageBlock];
}

- (void)p_resultPageNative:(CJPayBDOrderResultResponse *)resultResponse {
    [self stopLoading];
    @CJWeakify(self)
    void(^resultPageBlock)(void) = ^(){
        @CJStrongify(self)
        if ([resultResponse closeAfterTime] == 0) {
            [self closeActionAfterTime:[resultResponse closeAfterTime] closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
        } else {
            CJPayBDResultPageViewController *resultPage = [CJPayBDResultPageViewController new];
            resultPage.animationType = HalfVCEntranceTypeFromBottom;
            resultPage.resultResponse = resultResponse;
            resultPage.isPaymentForOuterApp = self.dypayModel.isPaymentForOuterApp;
            resultPage.closeActionCompletionBlock = ^(BOOL isCancel) {
                [self p_callBackWithOrderResultResponse:resultResponse orderStatus:resultResponse.tradeInfo.tradeStatus];
            };
            
            resultPage.verifyManager = self.verifyManager;
            if (![[self topVC].navigationController isKindOfClass:[CJPayNavigationController class]]) {
                [self p_callBackWithOrderResultResponse:resultResponse orderStatus:CJPayOrderStatusFail];
                return;
            }
            CJPayNavigationController *navi = (CJPayNavigationController *)([self topVC].navigationController);
            if (navi && [navi isKindOfClass:[CJPayNavigationController class]]) { // 有可能找不到
                [navi pushViewControllerSingleTop:resultPage animated:NO completion:nil];
            } else {
                [self closeActionAfterTime:[resultResponse closeAfterTime] closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
            }
        }
        
    };
    //尝试展示支付后引导和结果页
    [self p_showGuidePageWithResponse:resultResponse resultPageBlock:resultPageBlock];
}

- (CJPayResultPageModel *)p_resultmodelwithResponse:(CJPayOrderResultResponse *)response {
    CJPayResultPageModel *model = [[CJPayResultPageModel alloc] init];
    model.orderType = response.tradeInfo.ptCode;
    model.amount = response.tradeInfo.amount;
//    model.tradeInfo = response.tradeInfo;
    //    model.paymentInfo = response.paymentInfo;
    model.remainTime = response.remainTime;
    model.resultPageInfo = response.resultPageInfo;
    model.openSchema = response.openSchema;
    model.openUrl = response.openUrl;
    model.orderResponse = [response toDictionary]?:@{};
    return model;
}

- (void)p_resultPageLynxCard:(CJPayOrderResultResponse *)resultResponse {   
    @CJWeakify(self)
    void(^resultPageBlock)(void) = ^(){
        @CJStrongify(self)
        NSMutableDictionary *trackParams = @{
                    @"query_type" : @"0",
                    @"result_page_type" : @"full"
                }.mutableCopy;
        [trackParams addEntriesFromDictionary:self.dypayModel.trackParams];
        CJPayFullResultPageViewController *resultPage = [[CJPayFullResultPageViewController alloc] initWithCJResultModel:[self p_resultmodelwithResponse:resultResponse] trackerParams:[trackParams copy]];
        resultPage.closeCompletion = ^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (self.homeVC.response.deskConfig.callBackType == CJPayDeskConfigCallBackTypeAfterClose) {
                    [self p_handleClose:resultResponse];
                    [self p_callBackWithOrderResultResponse:self.bdResultResponse orderStatus:self.bdResultResponse.tradeInfo.tradeStatus];
                }
            });
        };
        if (![[self topVC].navigationController isKindOfClass:[CJPayNavigationController class]]) {
            [self p_callBackWithOrderResultResponse:self.bdResultResponse orderStatus:CJPayOrderStatusFail];
            return;
        }
        CJPayNavigationController *navi = (CJPayNavigationController *)([self topVC].navigationController);
        if (navi && [navi isKindOfClass:[CJPayNavigationController class]]) { // 有可能找不到
            [navi pushViewControllerSingleTop:resultPage animated:NO completion:^{
                if (self.homeVC.response.deskConfig.callBackType == CJPayDeskConfigCallBackTypeAfterQuery) {
                    [self p_handleClose:resultResponse];
                    [self p_callBackWithOrderResultResponse:self.bdResultResponse orderStatus:self.bdResultResponse.tradeInfo.tradeStatus];
                }
            }];
        } else {
            [self closeActionAfterTime:[self.bdResultResponse closeAfterTime] closeActionSource:CJPayHomeVCCloseActionSourceFromQuery];
        }
    };
    [self p_showGuidePageWithResponse:self.bdResultResponse resultPageBlock:resultPageBlock];
}

- (void)p_handleClose:(CJPayOrderResultResponse *)response {
    NSString *buttonAction = response.resultPageInfo.buttonInfo.action;
    NSString *url = response.openUrl;
    if ([buttonAction isEqualToString:@"open"] && Check_ValidString(url)) {
        if ([url hasPrefix:@"http"]) {
            [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[UIViewController cj_topViewController] toUrl:url params:@{}];
        } else {
            [CJPayDeskUtil openLynxPageBySchema:url completionBlock:nil];
        }
    }
}

// 负责展示支付后引导
- (void)p_showGuidePageWithResponse:(CJPayBDOrderResultResponse *)resultResponse resultPageBlock:(void (^)(void))resultPageBlock {
    
    // 免密相关引导
    if ([CJPaySkippwdGuideUtil shouldShowGuidePageWithResultResponse:resultResponse]) {
        [CJPaySkippwdGuideUtil showGuidePageVCWithVerifyManager:self.verifyManager pushAnimated:YES completionBlock:^{
            CJ_CALL_BLOCK(resultPageBlock);
        }];
        return;
    }

    CJ_DECLARE_ID_PROTOCOL(CJPayBioPaymentPlugin);
    // 生物识别开通引导
    if ([objectWithCJPayBioPaymentPlugin shouldShowGuideWithResultResponse:resultResponse]) {
        [objectWithCJPayBioPaymentPlugin showGuidePageVCWithVerifyManager:self.verifyManager completionBlock:^{
            CJ_CALL_BLOCK(resultPageBlock);
        }];
        return;
    }

    // 到系统设置开启生物权限引导
    if ([objectWithCJPayBioPaymentPlugin shouldShowBioSystemSettingGuideWithResultResponse:resultResponse]) {
        [objectWithCJPayBioPaymentPlugin showBioSystemSettingVCWithVerifyManager:self.verifyManager completionBlock:^{
            CJ_CALL_BLOCK(resultPageBlock);
        }];
        return;
    }
    
    // 不展示引导，则尝试展示结果页
    CJ_CALL_BLOCK(resultPageBlock);
}

#pragma mark - CJPayPayAgainDelegate
- (void)payWithContext:(CJPayFrontCashierContext *)context loadingView:(UIView *)loadingView {
    self.verifyManager.isNotSufficient = YES;
    self.bdCreateResponse = context.orderResponse;
    self.currentPayConfig = context.defaultConfig;
    CJPayChannelType channelType = context.defaultConfig.type;
    
    if (channelType == BDPayChannelTypeBankCard || channelType == BDPayChannelTypeBalance) {
        @CJWeakify(self);
        self.verifyManager.signCardStartLoadingBlock = ^{
            @CJStrongify(self)
            if ([loadingView respondsToSelector:@selector(startLoading)]) {
                [loadingView performSelector:@selector(startLoading)];
            } else {
                @CJStartLoading(self)
            }
        };
        
        self.verifyManager.signCardStopLoadingBlock = ^{
            @CJStrongify(self)
            if ([loadingView respondsToSelector:@selector(stopLoading)]) {
                [loadingView performSelector:@selector(stopLoading)];
            } else {
                @CJStopLoading(self)
            }
        };
        [self.verifyManager begin];
        return;
    }
    
    if (channelType == BDPayChannelTypeCreditPay) {
        [self p_activateCreditPay];
        return;
    }
    
    if (channelType == BDPayChannelTypeAddBankCard) {
        self.verifyManager.bindCardStartLoadingBlock = ^{
            if ([loadingView respondsToSelector:@selector(startLoading)]) {
                [loadingView performSelector:@selector(startLoading)];
            };
        };

        self.verifyManager.bindCardStopLoadingBlock = ^{
            if ([loadingView respondsToSelector:@selector(stopLoading)]) {
                [loadingView performSelector:@selector(stopLoading)];
            };
        };
        
        [self.verifyManager onBindCardAndPayAction];
        return;
    }
}

#pragma mark - CJPayChooseDyPayMethodDelegate
// 验证过程中更改支付方式
- (void)changePayMethod:(CJPayFrontCashierContext *)payContext loadingView:(UIView *)loadingView {

    CJPayChannelType channelType = payContext.defaultConfig.type;
    
    if (channelType == BDPayChannelTypeAddBankCard) {
        // 选中绑卡时单独存储payContext，与其他支付方式区分开
        self.bindcardPayConfig = payContext.defaultConfig;
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
        
        [self.verifyManager onBindCardAndPayAction];
        return;
    }
    
    if ([payContext.defaultConfig isNeedReSigning]) { //六位密码支持补签约
        self.verifyManager.signCardStartLoadingBlock = ^{
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
        };
        self.verifyManager.signCardStopLoadingBlock = ^{
            [[CJPayLoadingManager defaultService] stopLoading];
        };
        self.signCardShowConfig = payContext.defaultConfig;
        [self.verifyManager wakeSpecificType:CJPayVerifyTypeSignCard orderRes:payContext.orderResponse event:nil];
        return;
    }
    
    [self.verifyManager exitBindCardStatus];
    
    // 若有更改过支付方式，则进行记录
    if (![self.currentPayConfig isEqual:payContext.defaultConfig] && !self.verifyManager.hasChangeSelectConfigInVerify) {
        self.verifyManager.hasChangeSelectConfigInVerify = YES;
    }
    // 修改收银台首页记录的当前支付方式
    self.currentPayConfig = payContext.defaultConfig;
}

- (void)p_updateDefaultPayConfig {
    if (!self.createOrderResponse.payInfo.subPayTypeDisplayInfoList) {
        return;
    }
    CJPayDefaultChannelShowConfig *curSelectConfig = self.currentPayConfig;
    if (curSelectConfig.type != BDPayChannelTypeBalance && curSelectConfig.type != BDPayChannelTypeBankCard && curSelectConfig.type != BDPayChannelTypeCreditPay && curSelectConfig.type != BDPayChannelTypeIncomePay) {
        return;
    }
    
    CJPayInfo *payInfo = self.bdCreateResponse.payInfo;
    if (curSelectConfig.type == BDPayChannelTypeCreditPay && [curSelectConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) { //TODO：这个逻辑可以下掉，合并老样式下线测试一下
        BOOL hasActivateCredit = curSelectConfig.payTypeData.isCreditActivate;
        CJPaySubPayTypeInfoModel *channel = (CJPaySubPayTypeInfoModel *)curSelectConfig.payChannel;
        curSelectConfig.payTypeData = channel.payTypeData;
        curSelectConfig.payTypeData.isCreditActivate = hasActivateCredit;
    } else {
        if (!Check_ValidString(curSelectConfig.payAmount)) {
            curSelectConfig.payAmount = Check_ValidString(payInfo.standardShowAmount) ? CJString(payInfo.standardShowAmount) : CJString(payInfo.realTradeAmount);
        }
        if (!Check_ValidString(curSelectConfig.payVoucherMsg)) {
            curSelectConfig.payVoucherMsg = CJString(payInfo.standardRecDesc);
        }
        if (!Check_ValidString(curSelectConfig.title)) {
            curSelectConfig.title = CJString(payInfo.payName);
        }
    }
}

- (NSDictionary *)getPayDisabledReasonMap {
    return [self.payDisabledFundID2ReasonMap copy];
}

#pragma mark - private method

- (void)p_notifyNotSufficientFunds:(id)response {
    if (![response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        CJPayLogInfo(@"数据异常%@",response);
        return;
    }
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
    
    NSString *cjIdentify = [self p_getInvalidMethodIdentify:confirmResponse];
    if (Check_ValidString(cjIdentify) && ![self.payDisabledFundID2ReasonMap.allKeys containsObject:cjIdentify]) {
        [self.payDisabledFundID2ReasonMap cj_setObject:CJPayLocalizedStr(@"余额不足") forKey:cjIdentify];
    }
    [self.homeVC notifyNotsufficient:CJString(confirmResponse.bankCardId)];
}

- (void)p_handlePayMethodDisabled:(id)response {
    if (![response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        return;
    }
    
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
        
    NSString *cjIdentify = [self p_getInvalidMethodIdentify:confirmResponse];
    if (Check_ValidString(cjIdentify) && ![self.payDisabledFundID2ReasonMap.allKeys containsObject:cjIdentify]) {
        [self.payDisabledFundID2ReasonMap cj_setObject:confirmResponse.hintInfo.statusMsg forKey:cjIdentify];
    }
    
    [self p_gotoHalfPayMethodDisabledVCWithResponse:confirmResponse];
}

- (NSString *)p_getInvalidMethodIdentify:(CJPayOrderConfirmResponse *)confirmResponse {
    CJPayDefaultChannelShowConfig *curSelectConfig = [self curSelectConfig];
    
    NSString *cjIdentify;
    if (curSelectConfig.type == BDPayChannelTypeAddBankCard) {
        cjIdentify = confirmResponse.bankCardId;
    } else if (curSelectConfig.type == BDPayChannelTypeCombinePay && !curSelectConfig.cjIdentify) {
        cjIdentify = confirmResponse.bankCardId;
    } else {
        cjIdentify = curSelectConfig.cjIdentify;
    }
    return cjIdentify;
}

- (void)p_gotoHalfPayMethodDisabledVCWithResponse:(CJPayOrderConfirmResponse *)confirmResponse {
    CJPayPayAgainHalfViewController *payMethodDisabledVC = [CJPayPayAgainHalfViewController new];
    payMethodDisabledVC.createOrderResponse = self.bdCreateResponse;
    payMethodDisabledVC.confirmResponse = confirmResponse;
    payMethodDisabledVC.verifyManager = self.verifyManager;
    payMethodDisabledVC.payDisabledFundID2ReasonMap = self.payDisabledFundID2ReasonMap;
    payMethodDisabledVC.delegate = self;
    @CJWeakify(self);
    payMethodDisabledVC.cjBackBlock = ^{
        @CJStrongify(self);
        [self p_dismissAllVCAboveCurrent:YES];
        [self.payDisabledFundID2ReasonMap removeAllObjects];
    };
    
    payMethodDisabledVC.closeActionCompletionBlock = ^(BOOL success) {
        @CJStrongify(self);
        [self closeActionAfterTime:0 closeActionSource:CJPayHomeVCCloseActionSourceFromInsufficientBalance];
    };
    
    [self push:payMethodDisabledVC animated:NO];
}


- (void)p_dismissAllVCAboveCurrent:(BOOL)animated {
    if (self.homeVC.presentedViewController && CJ_Pad) {
        [self.homeVC.presentedViewController dismissViewControllerAnimated:animated completion:nil];
        return;
    }
    
    UIViewController *backVC = nil;
    backVC = self.homeVC;
    [self.homeVC.navigationController popToViewController:backVC animated:animated];
}

- (void)p_combinePayLimitWithModel:(id)response {
    if (![response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        return;
    }
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self p_combinePayLimitWithModel:confirmResponse.combineLimitButton bankCardId:confirmResponse.bankCardId combineType:confirmResponse.combineType];
    });
}

- (void)p_combinePayLimitWithModel:(CJPayCombinePayLimitModel *)limitModel bankCardId:(NSString *)bankcardId combineType:(NSString *)combineType {
    
    [self.homeVC.navigationController popToViewController:self.homeVC animated:YES];
    [[CJPayLoadingManager defaultService] stopLoading];
    if (self.currentPayConfig.type == BDPayChannelTypeAddBankCard) {
        CJ_DelayEnableView(self.homeVC.view);
        @CJStartLoading(self.homeVC.homeContentView)
        @CJWeakify(self);
        [self.processManager updateCreateOrderResponseWithCompletionBlock:^(NSError * _Nonnull error, CJPayCreateOrderResponse * _Nonnull response) {
            @CJStrongify(self);
            @CJStopLoading(self.homeVC.homeContentView)
            
            if (![response isSuccess]) {
                [CJToast toastText:CJString(response.msg) inWindow:self.homeVC.cj_window];
                return;
            }
            self.currentPayConfig = [self p_getCurrentShowConfigWithBankCardId:bankcardId createRespons:response];
            NSDictionary *extParams = @{
                @"response_data": CJString(response.originJsonString),
                @"bankcard_id" : CJString(bankcardId)
            };
            [self p_alertCombinePayLimitViewWithModel:limitModel combineType:combineType extParams:extParams];
        }];
    } else {
        [self p_alertCombinePayLimitViewWithModel:limitModel combineType:combineType extParams:nil];
    }
}

- (CJPayDefaultChannelShowConfig *)p_getCurrentShowConfigWithBankCardId:(NSString *)bankCardId createRespons:(CJPayCreateOrderResponse *)response {
    
    NSArray<CJPayDefaultChannelShowConfig *> *showConfigs = [response.payInfo showConfigForCardList];
    
    __block CJPayDefaultChannelShowConfig *showConfig = [CJPayDefaultChannelShowConfig new];
    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.cjIdentify isEqual:bankCardId]) {
            showConfig = obj;
            *stop = YES;
        }
    }];
    return showConfig;
}

- (void)p_alertCombinePayLimitViewWithModel:(CJPayCombinePayLimitModel *)limitModel combineType:(NSString *)combineType extParams:(NSDictionary *)extParams {
    if (self.homeVC.combinePayLimitBlock) { //覆写block后，首页不会切换支付方式（依赖lynx页面触发更新页面操作）
        NSMutableDictionary *params = [NSMutableDictionary dictionary];
        [params addEntriesFromDictionary:extParams];
        CJ_CALL_BLOCK(self.homeVC.combinePayLimitBlock, [params copy]);
    } else {
        if (self.currentPayConfig) {
            [self.homeVC changePayMethodTo:self.currentPayConfig];
        }
    }
    
    @weakify(self);
    void (^actionBlock)(BOOL isClose) = ^(BOOL isClose){
        @strongify(self);
        if (isClose) {
            [self p_trackWithEventName:@"wallet_cashier_combineno_pop_click" params:@{
                @"button_name" : @"关闭",
                @"error_info" : @"1"
            }];
            self.processManager.combineType = combineType;
        } else {
            NSString *buttonDesc = @"";
            if ([limitModel respondsToSelector:@selector(buttonDesc)]) {
                buttonDesc = [limitModel performSelector:@selector(buttonDesc)];
            }
            [self p_trackWithEventName:@"wallet_cashier_combineno_pop_click" params:@{
                @"button_name" : CJString(buttonDesc),
                @"error_info" : @"1"
            }];
            [self p_combineLimitPay];
        }
    };
    CJPayCombineLimitViewController *limitVC = [CJPayCombineLimitViewController createWithModel:limitModel actionBlock:actionBlock];
    [self.homeVC.navigationController pushViewController:limitVC animated:YES];
    [self p_trackWithEventName:@"wallet_cashier_combineno_pop_show" params:@{
        @"error_info": @"1"
    }];
}

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *mutableDic = [NSMutableDictionary dictionary];
    [mutableDic addEntriesFromDictionary:self.dypayModel.trackParams];
    [CJTracker event:eventName params:mutableDic];
}

- (void)p_combineLimitPay {
    self.currentPayConfig = [self.homeVC curSelectConfig];
    self.currentPayConfig.isCombinePay = NO;
    [self.processManager confirmPayWithConfig:[self.homeVC curSelectConfig]];
}

- (void)p_refreshTradeCreateWithModel:(id)response {
    if (![response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        return;
    }
    [self.homeVC.navigationController popToViewController:self.homeVC animated:YES];
    [[CJPayLoadingManager defaultService] stopLoading];
    
    if (self.currentPayConfig.type == BDPayChannelTypeIncomePay) {
        CJ_DelayEnableView(self.homeVC.view);
        @CJStartLoading(self.homeVC.homeContentView)
        @CJWeakify(self);
        [self.processManager updateCreateOrderResponseWithCompletionBlock:^(NSError * _Nonnull error, CJPayCreateOrderResponse * _Nonnull response) {
            @CJStrongify(self);
            @CJStopLoading(self.homeVC.homeContentView)
            [self.homeVC updateOrderResponse:response];
            [self.homeVC updateSelectConfig:nil];
        }];
    }
}

#pragma mark - Getter

- (NSMutableDictionary *)payDisabledFundID2ReasonMap {
    if (!_payDisabledFundID2ReasonMap) {
        _payDisabledFundID2ReasonMap = [NSMutableDictionary new];
    }
    return _payDisabledFundID2ReasonMap;
}

- (CJPayBizDYPayVerifyManager *)verifyManager {
    if (!_verifyManager) {
        _verifyManager = [CJPayBizDYPayVerifyManager managerWith:self];
    }
    return _verifyManager;
}

- (CJPayBizDYPayVerifyManagerQueen *)verifyManagerQueen {
    if (!_verifyManagerQueen) {
        _verifyManagerQueen = [[CJPayBizDYPayVerifyManagerQueen alloc] init];
        [_verifyManagerQueen bindManager:self.verifyManager];
    }
    return _verifyManagerQueen;
}

@end
