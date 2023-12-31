//
//  CJPayBalanceWithdrawController.m
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import "CJPayBalanceWithdrawController.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayNavigationController.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayDefaultChannelShowConfig.h"
#import "CJPayNotSufficientFundsView.h"
#import "CJPayLoadingManager.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayWithDrawBalanceViewController.h"
#import "CJPayBalanceVerifyManager.h"
#import "CJPayToast.h"

@interface CJPayBalanceWithdrawController()

@property (nonatomic, strong) CJPayFrontCashierContext *payContext;
@property (nonatomic, strong) NSMutableArray *notSufficientFundIds;
@property (nonatomic, copy, nullable) void (^completion)(CJPayManagerResultType, CJPayBDOrderResultResponse * _Nullable);
@property (nonatomic, assign) CJPayLoadingType loadingType;


@end

@implementation CJPayBalanceWithdrawController
- (instancetype)init
{
    self = [super init];
    if (self) {
        _balanceWithdrawVerifyManager = [CJPayBalanceVerifyManager managerWith:self];
        _balanceWithdrawVerifyManager.balanceVerifyType = CJPayBalanceVerifyTypeWithdraw;
    }
    return self;
}

- (void)startWithdrawWithContext:(CJPayFrontCashierContext *)context completion:(void (^)(CJPayManagerResultType, CJPayBDOrderResultResponse * _Nullable))completion{
    self.payContext = context;
    self.balanceWithdrawVerifyManager.payContext = context;
    self.completion = [completion copy];
    if (self.isBindCardAndPay) {
        [self.balanceWithdrawVerifyManager onBindCardAndPayAction];
    } else {
        [self.balanceWithdrawVerifyManager begin];
    }
}

#pragma mark - Getter
- (NSMutableArray *)notSufficientFundIds {
    if (!_notSufficientFundIds) {
        _notSufficientFundIds = [NSMutableArray new];
    }
    return _notSufficientFundIds;
}

- (void)dealloc
{
    CJPayLogInfo(@"1");
}

@end

@implementation CJPayBalanceWithdrawController(HomeVCProtocol)

- (UIViewController *)topVC {
    return [UIViewController cj_foundTopViewControllerFrom:self.payContext.homePageVC];
}

- (nullable CJPayBDCreateOrderResponse *)createOrderResponse {
    return self.payContext.orderResponse;
}

- (nullable CJPayDefaultChannelShowConfig *)curSelectConfig {
    return self.payContext.defaultConfig;
}

- (CJPayVerifyType)firstVerifyType {
    if ([self.curSelectConfig isNeedReSigning]) {
        return CJPayVerifyTypeSignCard;
    }
    return [self.balanceWithdrawVerifyManager getVerifyTypeWithPwdCheckWay:self.createOrderResponse.userInfo.pwdCheckWay];
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
    if (![vc isKindOfClass:CJPayWithDrawBalanceViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        self.loadingType = CJPayLoadingTypeTopLoading;
        return;
    }
    @CJStartLoading(self.payContext.homePageVC)
    self.loadingType = CJPayLoadingTypeConfirmBtnLoading;
}

- (void)stopLoading {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self.payContext.homePageVC];
    if (![vc isKindOfClass:CJPayWithDrawBalanceViewController.class]) {
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

- (void)p_dismissAllVCAboveCurrent {
    if (self.payContext.homePageVC.presentedViewController && CJ_Pad) {
        [self.payContext.homePageVC.presentedViewController dismissViewControllerAnimated:CJ_Pad completion:nil];
        return;
    }
    [self.payContext.homePageVC.navigationController popToViewController:self.payContext.homePageVC animated:YES];
}

- (void)p_refreshOrderResponseWithToastMessage:(NSString *)message {
    [CJToast toastText:CJString(message) inWindow:[self.balanceWithdrawVerifyManager.homePageVC topVC].cj_window];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDPaySignSuccessAndConfirmFailNotification object:nil];
}

// 数据总线，verifyManager 向 HomePageVC通信
- (BOOL)receiveDataBus:(CJPayHomeVCEvent)eventType obj:(id)object {
    switch (eventType) {
        case CJPayHomeVCEventDismissAllAboveVCs:
            [self p_dismissAllVCAboveCurrent];
            break;
        case CJPayHomeVCEventNotifySufficient:
//            [self p_notifyNotSufficientFunds:object];
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
        case CJPayHomeVCEventGotoCardList:
            CJ_CALL_BLOCK(self.payContext.gotoCardListBlock);
            break;
        case CJPayHomeVCEventFreezeConfirmBtn:
            CJ_CALL_BLOCK(self.payContext.extCallback, CJPayHomeVCEventFreezeConfirmBtn, object);
            break;
        default:
            break;
    }
    return YES;
}

- (void)showState:(CJPayStateType)stateType {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self.payContext.homePageVC];
    if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [((CJPayHalfPageBaseViewController *)vc) showState:stateType];
    }
}

- (void)p_callbackResultWithSource:(CJPayHomeVCCloseActionSource)source {
    CJPayManagerResultType type = CJPayManagerResultError;

    if (self.completion) {
        if (source == CJPayHomeVCCloseActionSourceFromCloseAction) {
            self.completion(CJPayManagerResultCancel, self.balanceWithdrawVerifyManager.resResponse);
        } else {
            switch (self.balanceWithdrawVerifyManager.resResponse.tradeInfo.tradeStatus) {
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
            CJ_CALL_BLOCK(self.completion, type, self.balanceWithdrawVerifyManager.resResponse);
        }
    }
}

- (void)endVerifyWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse {
    [self p_callbackResultWithSource:CJPayHomeVCCloseActionSourceFromQuery];
}

// 多少秒后关闭收银台，time小于等于0 立即关闭
- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
    [self p_callbackResultWithSource:source];
}

- (void)push:(UIViewController *)vc animated:(BOOL) animated {
    UIViewController *topVC = [UIViewController cj_foundTopViewControllerFrom:self.payContext.homePageVC];
    [self push:vc animated:animated topVC:topVC];
}


@end
