//
//  CJPayBalanceRechargeController.m
//  CJPay
//
//  Created by 王新华 on 3/11/20.
//

#import "CJPayBalanceRechargeController.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayNavigationController.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayFrontCardListViewController.h"
#import "CJPayNotSufficientFundsView.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayLoadingManager.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayBalanceVerifyManager.h"
#import "CJPayToast.h"
#import "CJPayRechargeBalanceViewController.h"

@interface CJPayBalanceRechargeController()

@property (nonatomic, copy, nullable) void (^completion)(CJPayManagerResultType, CJPayBDOrderResultResponse * _Nullable);
@property (nonatomic, assign) CJPayLoadingType loadingType;

@end

@implementation CJPayBalanceRechargeController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _frontCashierVerifyManager = [CJPayBalanceVerifyManager managerWith:self];
        _frontCashierVerifyManager.balanceVerifyType = CJPayBalanceVerifyTypeRecharge;
    }
    return self;
}

- (void)startPaymentWithContext:(CJPayFrontCashierContext *)context completion:(void (^)(CJPayManagerResultType, CJPayBDOrderResultResponse * _Nullable))completion {
    self.payContext = context;
    self.frontCashierVerifyManager.payContext = context;
    self.completion = [completion copy];
    if (self.isBindCardAndPay) {
        [self.frontCashierVerifyManager onBindCardAndPayAction];
    } else {
        [self.frontCashierVerifyManager begin];
    }
}


@end

@implementation CJPayBalanceRechargeController(HomeVCProtocol)

- (UIViewController *)topVC {
    return [UIViewController cj_foundTopViewControllerFrom:self.payContext.homePageVC];
}

- (nullable CJPayBDCreateOrderResponse *)createOrderResponse {
    return self.payContext.orderResponse;
}

- (nullable CJPayDefaultChannelShowConfig *)curSelectConfig {
    return self.payContext.defaultConfig;
}

// 数据总线，verifyManager 像 HomePageVC通信
- (BOOL)receiveDataBus:(CJPayHomeVCEvent)eventType obj:(id)object {
    switch (eventType) {
        case CJPayHomeVCEventDismissAllAboveVCs:
            [self p_dismissAllVCAboveCurrent];
            break;
        case CJPayHomeVCEventNotifySufficient:
            [self p_notifyNotSufficientFunds:object];
            break;
        case CJPayHomeVCEventQueryOrderSuccess:
            [self p_callbackResultWithSource:CJPayHomeVCCloseActionSourceFromQuery];
            break;
        case CJPayHomeVCEventShowState:
            [self showState:[object integerValue]];
            break;
        case CJPayHomeVCEventSignAndPayFailed:
            [self p_refreshOrderResponseWithToastMessage:object];
            break;
        default:
            break;
    }
    return YES;
}

- (void)push:(UIViewController *)vc animated:(BOOL) animated {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self.payContext.homePageVC];
    [self push:vc animated:animated topVC:topVC];
}

- (void)startLoading {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self.payContext.homePageVC];
    if (self.isBindCardAndPay) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading];
        self.loadingType = CJPayLoadingTypeTopLoading;
        return;
    }
    if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
        self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
        return;
    }
    if (![vc isKindOfClass:CJPayRechargeBalanceViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        self.loadingType = CJPayLoadingTypeTopLoading;
        return;
    }
    @CJStartLoading(self.payContext.homePageVC);
    self.loadingType = CJPayLoadingTypeConfirmBtnLoading;
}

- (void)stopLoading {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self.payContext.homePageVC];
    if (![vc isKindOfClass:CJPayRechargeBalanceViewController.class]) {
       [[CJPayLoadingManager defaultService] stopLoading];
    } else {
        switch (self.loadingType) {
            case CJPayLoadingTypeConfirmBtnLoading:
                @CJStopLoading(self.payContext.homePageVC)
                break;
            default:
                [[CJPayLoadingManager defaultService] stopLoading];
                break;
        }
    }
}

- (CJPayVerifyType)firstVerifyType {
    if ([self.curSelectConfig isNeedReSigning]) {
        return CJPayVerifyTypeSignCard;
    }
    return [self.frontCashierVerifyManager getVerifyTypeWithPwdCheckWay:self.createOrderResponse.userInfo.pwdCheckWay];
}

- (void)endVerifyWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    if (!resultResponse || ![resultResponse isSuccess]) {
        [CJToast toastText:CJPayNoNetworkMessage inWindow:[self topVC].cj_window];
        [self p_dismissAllVCAboveCurrent];
        return;
    }
    [self p_callbackResultWithSource:CJPayHomeVCCloseActionSourceFromQuery];
}

- (void)p_notifyNotSufficientFunds:(id)response {
    if (![response isKindOfClass:CJPayOrderConfirmResponse.class]) {
        return;
    }
    CJPayOrderConfirmResponse *confirmResponse = (CJPayOrderConfirmResponse *)response;
    if (self.payContext.extCallback && Check_ValidString([self curSelectConfig].cjIdentify)) {
        self.payContext.extCallback(CJPayHomeVCEventNotifySufficient, CJString([self curSelectConfig].cjIdentify));
    }
    @CJWeakify(self)
    BDChooseCardCommonModel *commonModel = [BDChooseCardCommonModel new];
    commonModel.orderResponse = [self createOrderResponse];
    commonModel.defaultConfig = [self curSelectConfig];
    commonModel.notSufficientFundsIDs = self.payContext.latestNotSufficientFundIds ? self.payContext.latestNotSufficientFundIds() : @[];
    commonModel.fromVC = self.payContext.homePageVC;
    commonModel.chooseCardCompletion = ^(CJPayChooseCardResultModel * _Nonnull model) {
        @CJStrongify(self)
        if ([self.payContext.defaultConfig isNeedReSigning] || [model.config isNeedReSigning]) { //补签约卡切普通卡&普通卡切补签约卡
            [self p_dismissAllVCAboveCurrent];
            self.payContext.defaultConfig = model.config;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self.frontCashierVerifyManager begin];
            });
        } else {
            self.payContext.defaultConfig = model.config;
        }
        
        CJ_CALL_BLOCK(self.payContext.changeSelectConfigBlock, model.config);
    };
    commonModel.backToMainVCBlock = ^{
        @CJStrongify(self)
        UIViewController *homePageVC = self.payContext.homePageVC;
        [homePageVC.navigationController popToViewController:homePageVC animated:YES];
    };
    commonModel.bindCardBlock = ^(BDChooseCardDismissLoadingBlock _Nonnull dismissLoadingBlock) {
        @CJStrongify(self)
        UIViewController *homePageVC = self.payContext.homePageVC;
        if (![homePageVC isKindOfClass:CJPayRechargeBalanceViewController.class]) {
            return;
        }
        CJPayRechargeBalanceViewController *rechargeVC = (CJPayRechargeBalanceViewController *)homePageVC;
        [rechargeVC bindCardFromCardList:dismissLoadingBlock];
    };
    CJPayFrontCardListViewController *cardListVC = [[CJPayFrontCardListViewController alloc] initWithCardCommonModel:commonModel];
    [cardListVC.notSufficientFundsView updateTitle:confirmResponse.msg];
    __block NSUInteger lastHalfScreenIndex = NSNotFound;
    [self.payContext.homePageVC.navigationController.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([viewController isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            lastHalfScreenIndex = idx;
            *stop = YES;
        }
    }];
    
    if (lastHalfScreenIndex < self.payContext.homePageVC.navigationController.viewControllers.count - 1) {
        NSMutableArray *vcStack = [self.payContext.homePageVC.navigationController.viewControllers mutableCopy];
        [vcStack insertObject:cardListVC atIndex:lastHalfScreenIndex];
        self.payContext.homePageVC.navigationController.viewControllers = [vcStack copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.payContext.homePageVC.navigationController popToViewController:cardListVC animated:YES];
        });
    } else {
        [self push:cardListVC animated:YES];
    }
}

- (void)p_dismissAllVCAboveCurrent {
    if (self.payContext.homePageVC.presentedViewController && CJ_Pad) {
        [self.payContext.homePageVC.presentedViewController dismissViewControllerAnimated:CJ_Pad completion:nil];
        return;
    }
    [self.payContext.homePageVC.navigationController popToViewController:self.payContext.homePageVC animated:YES];
}

- (void)showState:(CJPayStateType)stateType {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self.payContext.homePageVC];
    if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [((CJPayHalfPageBaseViewController *)vc) showState:stateType];
    }
}

- (void)p_refreshOrderResponseWithToastMessage:(NSString *)message {
    [CJToast toastText:CJString(message) inWindow:[self.frontCashierVerifyManager.homePageVC topVC].cj_window];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDPaySignSuccessAndConfirmFailNotification object:nil];
}

- (void)p_callbackResultWithSource:(CJPayHomeVCCloseActionSource)source {
    CJPayManagerResultType type = CJPayManagerResultError;

    if (self.completion) {
        if (source == CJPayHomeVCCloseActionSourceFromCloseAction) {
            self.completion(CJPayManagerResultCancel, self.frontCashierVerifyManager.resResponse);
        } else {
            switch (self.frontCashierVerifyManager.resResponse.tradeInfo.tradeStatus) {
                case CJPayOrderStatusProcess:
                    type = CJPayManagerResultProcessing;
                    break;
                case CJPayOrderStatusFail:
                    type = CJPayManagerResultFailed;
                    break;
                case CJPayOrderStatusTimeout:
                    type = CJPayManagerResultTimeout;
                    break;
                case CJPayOrderStatusSuccess:
                    type = CJPayManagerResultSuccess;
                    break;
                default:
                    break;
            }
            CJ_CALL_BLOCK(self.completion, type, self.frontCashierVerifyManager.resResponse);
        }
    }
}

// 多少秒后关闭收银台，time小于等于0 立即关闭
- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
    [self p_callbackResultWithSource:source];
}

@end
