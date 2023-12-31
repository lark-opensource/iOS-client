//
//  CJPayBytePayHomePageViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/4/16.
//

#import "CJPayBytePayHomePageViewController.h"
#import "CJPayBytePayHomeContentView.h"
#import "CJPayCombinationPaymentViewController.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayBizChoosePayMethodViewController.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayTypeInfo.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayBizWebViewController.h"
#import "CJPayAlertUtil.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayMarketingMsgView.h"
#import "CJPayAlertUtil.h"

@interface CJPayBytePayHomePageViewController ()

#pragma mark - view & vc
@property (nonatomic, strong) CJPayCombinationPaymentViewController *combinePayViewController;
@property (nonatomic, strong) CJPayBizChoosePayMethodViewController *choosePayMethodVC;

#pragma mark - config
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *currentPayConfig;

#pragma mark - flag
@property (nonatomic, assign, readonly, getter=isSendToCombinePaymentVC) BOOL isSendToCombinePaymentVC;

#pragma mark - data
@property (nonatomic, strong) NSMutableArray *notSufficientFundIdsInCombinePay;

@end

@implementation CJPayBytePayHomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.countDownView.style = CJPayCountDownTimerViewStyleSmall;
    [self updateAmountViewByShowConfig:[self curSelectConfig]]; //首次加载时更新金额区UI
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccess) name:CJPayBindCardSuccessPreCloseNotification object:nil];
}

- (void)p_bindCardSuccess {
    self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
    UIViewController *backVC = nil;
    NSArray *vcStacks = [self.navigationController viewControllers];
    if (self.isSendToCombinePaymentVC && [vcStacks containsObject:self.combinePayViewController]) {
        // 确保要返回到的 VC 还在当前导航栈中
        backVC = self.combinePayViewController;
    } else {
        backVC = self;
    }
    [self.navigationController popToViewController:backVC animated:NO];
}

- (void)updateOrderResponse:(CJPayCreateOrderResponse *)response {
    [super updateOrderResponse:response];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDPayBindCardSuccessRefreshNotification object:response];
}

- (void)setupNavigatinBar {
    
    [self.countDownView.superview sendSubviewToBack:self.countDownView]; //避免金额被navi遮挡
    
    [self useCloseBackBtn];
    self.navigationBar.bottomLine.hidden = YES;
    self.navigationBar.title = @"";
    if (self.isPaymentForOuterApp && self.response.payInfo.bdPay.merchantInfo.merchantShortToCustomer.length) {
        if (self.outerAppName.length) {
            // app 拉起的端外支付
            self.navigationBar.titleLabel.font = [UIFont cj_boldFontOfSize:15];
            self.navigationBar.titleLabel.numberOfLines = 1;
            self.navigationBar.title = [NSString stringWithFormat:@"%@%@商户", self.outerAppName, self.response.payInfo.bdPay.merchantInfo.merchantShortToCustomer];
        } else {
            // 浏览器拉起的端外支付
            self.navigationBar.titleLabel.font = [UIFont cj_boldFontOfSize:15];
            self.navigationBar.titleLabel.numberOfLines = 1;
            self.navigationBar.title = [NSString stringWithFormat:@"%@商户", CJString(self.response.payInfo.bdPay.merchantInfo.merchantName)];
        }
    }

    CJPayMasUpdate(self.countDownView, {
        make.height.mas_equalTo(46);
    });
}

- (BOOL)isSecondaryCellView:(CJPayChannelType)channelType {
    return [super isSecondaryCellView:channelType] || channelType == BDPayChannelTypeBalance || channelType == BDPayChannelTypeIncomePay || channelType == BDPayChannelTypeCreditPay; // 品牌升级收银台余额在卡列表里面
}

- (void)showState:(CJPayStateType)stateType {
    if ([self.homeContentView isKindOfClass:CJPayBytePayHomeContentView.class]) {
        BOOL hiddenFlag = stateType == CJPayStateTypeNone;
        self.navigationBar.bottomLine.hidden = stateType == CJPayStateTypeNone;
        ((CJPayBytePayHomeContentView *)self.homeContentView).marketingMsgView.hidden = !hiddenFlag;
        ((CJPayBytePayHomeContentView *)self.homeContentView).orderDetailLabel.hidden = !hiddenFlag;
    }
    [super showState:stateType];
    
    if (self.isSendToCombinePaymentVC) {
        [self.combinePayViewController showState:stateType];
    }
}

- (void)didSelectAtIndex:(int)selectIndex {
    if (selectIndex > self.channels.count) {
        return;
    }
    CJPayDefaultChannelShowConfig *selectConfig = ((CJPayDefaultChannelShowConfig *)[self.channels cj_objectAtIndex:selectIndex]);
    
    // 支付方式不可用的时候不能选中
    if (!selectConfig || !selectConfig.enable) {
        return;
    }
    
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *infoDict = [[self curSelectConfig] toActivityInfoTracker];
    if (infoDict.count > 0) {
        [activityInfos addObject:infoDict];
    }
    
    if (selectConfig.type == BDPayChannelTypeAddBankCard || selectConfig.type == BDPayChannelTypeIncomePay) {
        [self gotoChooseMethodVC:NO];
        [self trackWithEventName:@"wallet_cashier_more_method_click" params:@{
            @"activity_info": activityInfos
        }];
        return;
    }
    
    [super didSelectAtIndex:selectIndex];
    // 切换一级支付方式时需更新金额区
    [self updateAmountViewByShowConfig:[self curSelectConfig]];
}

- (void)didSelectNewCustomerSubCell:(NSInteger)selectIndex {
    [super didSelectNewCustomerSubCell:selectIndex];
    
    [self updateAmountViewByShowConfig:[self curSelectConfig]];
}

- (void)notifyNotsufficient:(NSString *)bankCardId {
    if (!self.isSendToCombinePaymentVC) {
        [super notifyNotsufficient:bankCardId];
        return;
    }
    
    //  组合支付余额不足处理
    if (self.currentPayConfig.type == BDPayChannelTypeAddBankCard) {
        // 取到最新的支付方式
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
        [self.processManager updateCreateOrderResponseWithCompletionBlock:^(NSError * _Nonnull error, CJPayCreateOrderResponse * _Nonnull response) {
            if (![response isSuccess]) {
                [CJToast toastText:response.msg ?: CJPayNoNetworkMessage inWindow:self.cj_window];
            }
            
            [self p_notifyHomeVCAndChooseVCNotSufficientWithResponse:response error:error bankCardId:bankCardId];
        }];
    } else {
        [self p_notifyHomeVCAndChooseVCNotSufficientWithResponse:nil error:nil bankCardId:bankCardId];
    }
    
    // 组合支付页余额不足卡更新
    [self.combinePayViewController notifyNotsufficient:bankCardId];
    [self.navigationController popToViewController:self.combinePayViewController animated:YES];
}

- (void)p_notifyHomeVCAndChooseVCNotSufficientWithResponse:(CJPayCreateOrderResponse *)response error:(NSError *)error bankCardId:(NSString *)bankCardId {
    if ([response isSuccess]) {
        [self updateOrderResponse:response];
    }
    
    [[self.combinePayViewController getShouldShowConfigs] enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull channelConfig, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([channelConfig.cjIdentify isEqualToString:bankCardId]) {
            // 刷新支付方式为新绑定的卡
            self.currentPayConfig = channelConfig;
            *stop = YES;
        }
    }];
    NSString *cjIdentify = self.currentPayConfig.cjIdentify;
    if (Check_ValidString(cjIdentify) && ![self.notSufficientFundIds containsObject:cjIdentify]) {
        [self.notSufficientFundIds addObject:cjIdentify];
    }
    
    if (Check_ValidString(cjIdentify) && ![self.notSufficientFundIdsInCombinePay containsObject:cjIdentify]) {
        [self.notSufficientFundIdsInCombinePay addObject:cjIdentify];
    }
    
    // 卡列表余额不足刷新
    [self p_tryInsertChooseViewControllerWithNotSufficientID:bankCardId];
    [[CJPayLoadingManager defaultService] stopLoading];
}

- (void)p_tryInsertChooseViewControllerWithNotSufficientID:(NSString *)bankCardId {
    __block NSUInteger combineVCIndex = 0;
    __block BOOL isHaveChooseVC = NO;
    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayBizChoosePayMethodViewController.class]) {
            isHaveChooseVC = YES;
            self.choosePayMethodVC = obj;
        }
        if ([obj isKindOfClass:CJPayCombinationPaymentViewController.class]) {
            combineVCIndex = idx;
        }
    }];
    
    if (isHaveChooseVC) {
        // 卡列表页存在，则刷新卡列表页余额不足状态
        [self.choosePayMethodVC notifyNotsufficient:bankCardId];
        self.choosePayMethodVC.isShowDetentionAlert = YES;
        self.choosePayMethodVC.showNotSufficientFundsHeaderLabel = NO;
        return;
    }
    
    if (!isHaveChooseVC && combineVCIndex > 0) { //有组合支付页面且没有卡列表页时，把卡列表塞进组合支付下面
        self.choosePayMethodVC = [self choosePayMethodVCWithshowNotSufficentFund:NO];
        NSMutableArray *naviViewControllers = [self.navigationController.viewControllers mutableCopy];
        [naviViewControllers insertObject:self.choosePayMethodVC atIndex:combineVCIndex];
        self.navigationController.viewControllers = [naviViewControllers copy];
    }
}

// 根据选中的支付方式更新金额区UI
- (void)updateAmountViewByShowConfig:(CJPayDefaultChannelShowConfig *)showConfig {
    //priceZoneShowStyle != "LINE"时金额区不展示营销，则无需变更
    if (![self.response.payInfo.bdPay.subPayTypeSumInfo.priceZoneShowStyle isEqualToString:@"LINE"]) {
        return;
    }
    
    NSString *payAmount = @"";
    NSString *payVoucherMsg = @"";
    
    if (showConfig.type == BDPayChannelTypeCreditPay) {
        // 抖分期,需要从里面取出分期数对应的支付金额和营销信息
        __block CJPayBytePayCreditPayMethodModel *selectedCreditPayMethodModel = nil;
        if ([showConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
            CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)showConfig.payChannel;
            [payChannel.payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.choose) {
                    selectedCreditPayMethodModel = obj;
                    *stop = YES;
                }
            }];
            // 若有分期信息，则取对应的支付金额和营销信息，否则从payTypeData取支付金额和营销信息
            if (selectedCreditPayMethodModel) {
                payAmount = selectedCreditPayMethodModel.standardShowAmount;
                payVoucherMsg = selectedCreditPayMethodModel.standardRecDesc;
            } else {
                payAmount = payChannel.payTypeData.standardShowAmount;
                payVoucherMsg = payChannel.payTypeData.standardRecDesc;
            }
        } else {
            CJPayLogAssert(YES, @"下发抖分期数据错误");
        }
    } else {
        // 银行卡、余额等二级支付方式直接取payAmount和payVoucherMsg
        payAmount = showConfig.payAmount;
        payVoucherMsg = showConfig.payVoucherMsg;
    }
    // payAmount 或 payVoucherMsg 为空时，兜底走线上逻辑
    if (!Check_ValidString(payAmount) || !Check_ValidString(payVoucherMsg)) {
        payAmount = [NSString stringWithFormat:@"%.2f", [self.response totalAmountWithDiscount] / 100.0];
        payVoucherMsg = @"";
    }
    
    if ([self.homeContentView isKindOfClass:CJPayBytePayHomeContentView.class]) {
        [(CJPayBytePayHomeContentView *)self.homeContentView refreshPriceViewWithAmount:payAmount voucher:payVoucherMsg];
    }
}

#pragma mark - CJChangePayMethodDelegate
- (void)combinePayWithType:(CJPayChannelType)type {
    [self p_gotoCombinationPaymentType:type];
}

- (void)changePayMethodTo:(CJPayDefaultChannelShowConfig *)defaultModel {
    [super changePayMethodTo:defaultModel];
    // 卡列表页面切卡时，应该更新 currentPayConfig
    self.currentPayConfig = defaultModel;
    // 卡列表页面切卡时，应该更新金额区UI
    [self updateAmountViewByShowConfig:defaultModel];
}

#pragma mark - contentDelegate
- (void)didClickBannerWithType:(CJPayChannelType)channelType {
    if (channelType == CJPayChannelTypeBannerCombinePay) {
        [self trackWithEventName:@"wallet_cashier_combine_click" params:@{}];
        [self p_gotoCombinationPaymentType:BDPayChannelTypeBalance];
    } else if (channelType == CJPayChannelTypeBannerVoucher) {
        [self trackWithEventName:@"wallet_cashier_wxcard_click" params:@{}];
        [self gotoChooseMethodVC:NO];
    }
}

- (void)didChangeCreditPayInstallment:(NSString *)installment {
    [self changeCreditPayInstallment:installment];
    // 首页更改月付分期数时，应该更新金额区UI
    [self updateAmountViewByShowConfig:[self curSelectConfig]];
}

- (void)p_gotoCombinationPaymentType:(CJPayChannelType)type {
    self.combinePayViewController = [[CJPayCombinationPaymentViewController alloc] initWithOrderResponse:self.response
                                                                                           defaultConfig:[self curSelectConfig]
                                                                                          processManager:self.processManager
                                                                                                    type:type];
    self.combinePayViewController.delegate = self;
    @weakify(self);
    self.combinePayViewController.payBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull showConfig) {
        @strongify(self);
        showConfig.combineType = self.combinePayViewController.combineType;
        self.currentPayConfig = showConfig;
        [self.processManager confirmPayWithConfig:showConfig];
    };
    
    self.combinePayViewController.commonTrackerParams = self.commonTrackerParams;
    self.combinePayViewController.showNotSufficientFundsHeaderLabel = NO;
    self.combinePayViewController.notSufficientFundsIDs = [self.notSufficientFundIdsInCombinePay mutableCopy];
    self.combinePayViewController.type = type;
    [self.navigationController pushViewController:self.combinePayViewController animated:YES];
}

- (void)onConfirmPayAction {
    self.currentPayConfig = [self curSelectConfig];
    self.currentPayConfig.isCombinePay = NO;
    
    if (self.isStandardDouPayProcess) {
        [super onConfirmPayAction];
        return;
    }
    
    if (self.currentPayConfig.type == BDPayChannelTypeIncomePay) {
        [self p_checkAuthStatusAndPay];
    } else {
        [super onConfirmPayAction];
    }
}

- (void)p_checkAuthStatusAndPay {
    if ([self.response.userInfo.authStatus isEqualToString:@"0"] || self.response.userInfo.isNewUser) {
        @CJWeakify(self);

        [self p_showAuthAlertWithAuthUrl:self.response.userInfo.authUrl completion:^{
            @CJStrongify(self);
            self.response.payInfo.bdPay.userInfo.authStatus = @"1";
            self.response.payInfo.bdPay.userInfo.isNewUser = NO;
            [super onConfirmPayAction];
        }];
    } else {
        [super onConfirmPayAction];
    }
}

- (void)p_showAuthAlertWithAuthUrl:(NSString *)authUrl completion:(void (^)(void))completion
{
    @CJWeakify(self)
    [CJPayAlertUtil customDoubleAlertWithTitle:CJPayLocalizedStr(@"根据监管要求，使用钱包收入支付前需先完成抖音零钱开户认证")
                                       content:nil
                                leftButtonDesc:CJPayLocalizedStr(@"取消")
                               rightButtonDesc:CJPayLocalizedStr(@"去认证")
                               leftActionBlock:nil
                               rightActioBlock:^{
        @CJStrongify(self)
        if (Check_ValidString(authUrl)) {
            CJPayBizWebViewController *webVC = [[CJPayBizWebViewController alloc] initWithUrlString:authUrl];
            webVC.closeCallBack = ^(id  _Nonnull data) {
                NSDictionary *dic = (NSDictionary *)data;
                if (dic && [dic isKindOfClass:NSDictionary.class]) {
                    NSString *service = [dic cj_stringValueForKey:@"service"];
                    if ([service isEqualToString:@"openAccount"]) {
                        CJ_CALL_BLOCK(completion);
                    }
                }
            };
            [self.navigationController pushViewController:webVC animated:YES];
        }
    } useVC:self];
}

- (CJPayHomeBaseContentView *)getCurrentContentView {
    return [[CJPayBytePayHomeContentView alloc] initWithFrame:CGRectZero createOrderResponse:self.response];
}

- (void)startLoading {
    if (self.isSendToCombinePaymentVC) {
        @CJStartLoading(self.combinePayViewController)
    } else {
        @CJStartLoading(super)
    }
}

- (void)stopLoading {
    if (self.isSendToCombinePaymentVC) {
        @CJStopLoading(self.combinePayViewController)
    } else {
        @CJStopLoading(super)
    }
}

#pragma mark - getter
- (BOOL)isSendToCombinePaymentVC {
    if (self.currentPayConfig.isCombinePay && self.combinePayViewController) {
        return YES;
    } else {
        return NO;
    }
}

- (NSMutableArray *)notSufficientFundIdsInCombinePay {
    if (!_notSufficientFundIdsInCombinePay) {
        _notSufficientFundIdsInCombinePay = [NSMutableArray new];
    }
    return _notSufficientFundIdsInCombinePay;
}

@end
