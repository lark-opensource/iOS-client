//
//  CJPayOPHomePageViewController.m
//  Pods
//
//  Created by xutianxi on 2022/3/28.
//

#import "CJPayOPHomePageViewController.h"
#import "CJPayOPHomeContentView.h"
#import "CJPayCombinationPaymentViewController.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayBizChoosePayMethodViewController.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayTypeInfo.h"
#import "CJPayHomePageAmountView.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayBizWebViewController.h"
#import "CJPayBDPayMainMessageView.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPaySubPayTypeInfoModel.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayMarketingMsgView.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayAlertUtil.h"
#import "CJPayAlertUtil.h"
#import "CJPayKVContext.h"

@interface CJPayOPHomePageViewController ()

@property (nonatomic, strong) CJPayOPHomeContentView *outerPayHomeContentView;

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

@implementation CJPayOPHomePageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.countDownView.style = CJPayCountDownTimerViewStyleSmall;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccess) name:CJPayBindCardSuccessPreCloseNotification object:nil];
    self.currentPayConfig = [self curSelectConfig];
    [self updatePayTypeView];
    
    CJPayMasUpdate(self.homeContentView, {
        make.top.equalTo(self.contentView);
    });
    if (!self.isSignAndPay) {
        NSDate *dt = [NSDate dateWithTimeIntervalSinceNow:0];
        double currentTimestamp = [dt timeIntervalSince1970]*1000;
        double duration = currentTimestamp - self.lastTimestamp;
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        [trackData addEntriesFromDictionary:@{@"from": @"outerpay_desk_loaded",
                                              @"duration" : @(duration),
                                              @"channel" : CJString([UIApplication btd_currentChannel]),
                                              @"outer_aid" : CJString(self.outerAppID),
                                              @"is_cold_launch" : @(self.isColdLaunch)}];
        [CJTracker event:@"wallet_cashier_outerpay_track_event"
                  params:trackData];
    }
}

- (void)p_bindCardSuccess {
    self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
    [self.navigationController popToViewController:self animated:NO];
}

- (void)updateOrderResponse:(CJPayCreateOrderResponse *)response {
    [super updateOrderResponse:response];
    [[NSNotificationCenter defaultCenter] postNotificationName:BDPayBindCardSuccessRefreshNotification object:response];
}

- (void)setupNavigatinBar {
    
    [self.countDownView.superview sendSubviewToBack:self.countDownView]; //避免金额被navi遮挡
    
    [self useCloseBackBtn];
    self.navigationBar.bottomLine.hidden = YES;
    
    // 先注释导航栏 logo
    self.navigationBar.title = @"";
    [self.navigationBar setTitleImage:@"cj_nav_title_image_icon"];
    
    if (self.isSignAndPay) { //签约并支付流程全部使用merchantShortToCustomer字段
        [self.outerPayHomeContentView.tradeMesageView updateDescLabelText:CJString(self.response.payInfo.bdPay.merchantInfo.merchantShortToCustomer)];
    } else if (self.isPaymentForOuterApp && self.response.payInfo.bdPay.merchantInfo.merchantShortToCustomer.length) {
        NSString *tradeInfo = nil;
        if (self.outerAppName.length) {
            // app 拉起的端外支付
            tradeInfo = self.response.payInfo.bdPay.merchantInfo.merchantShortToCustomer;
        } else {
            // 浏览器拉起的端外支付
            tradeInfo = [NSString stringWithFormat:@"%@商户", CJString(self.response.payInfo.bdPay.merchantInfo.merchantName)];
        }
        
        [self.outerPayHomeContentView.tradeMesageView updateDescLabelText:tradeInfo];
    }

    CJPayMasUpdate(self.countDownView, {
        make.height.mas_equalTo(46);
    });
}

- (BOOL)isSecondaryCellView:(CJPayChannelType)channelType {
    return [super isSecondaryCellView:channelType] || channelType == BDPayChannelTypeBalance || channelType == BDPayChannelTypeIncomePay || channelType == BDPayChannelTypeCreditPay; // 品牌升级收银台余额在卡列表里面
}

- (void)showState:(CJPayStateType)stateType {
    [super showState:stateType];
    
    if (self.isSendToCombinePaymentVC) {
        [self.combinePayViewController showState:stateType];
    }
}

- (void)didSelectAtIndex:(int)selectIndex {
    if (selectIndex > self.channels.count) {
        return;
    }
    
    CJPayDefaultChannelShowConfig *selectConfig = nil;
    if ([[self.channels cj_objectAtIndex:selectIndex] isKindOfClass:[CJPayDefaultChannelShowConfig class]]) {
        selectConfig = ((CJPayDefaultChannelShowConfig *)[self.channels cj_objectAtIndex:selectIndex]);
    } else {
        return;
    }
    
    // 支付方式不可用的时候不能选中
    if (!selectConfig || !selectConfig.enable) {
        return;
    }
    
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *infoDict = [[self curSelectConfig] toActivityInfoTracker];
    if (infoDict.count > 0) {
        [activityInfos btd_addObject:infoDict];
    }
    
    if (selectConfig.type == BDPayChannelTypeAddBankCard || selectConfig.type == BDPayChannelTypeIncomePay) {
        [self gotoChooseMethodVC:NO];
        [self trackWithEventName:@"wallet_cashier_more_method_click" params:@{
            @"activity_info": activityInfos
        }];
        return;
    }
    
    [super didSelectAtIndex:selectIndex];
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
        [self.notSufficientFundIds btd_addObject:cjIdentify];
    }
    
    if (Check_ValidString(cjIdentify) && ![self.notSufficientFundIdsInCombinePay containsObject:cjIdentify]) {
        [self.notSufficientFundIdsInCombinePay btd_addObject:cjIdentify];
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
        self.choosePayMethodVC.showNotSufficientFundsHeaderLabel = NO;
        return;
    }
    
    if (!isHaveChooseVC && combineVCIndex > 0) { //有组合支付页面且没有卡列表页时，把卡列表塞进组合支付下面
        self.choosePayMethodVC = [self choosePayMethodVCWithshowNotSufficentFund:NO];
        NSMutableArray *naviViewControllers = [self.navigationController.viewControllers mutableCopy];
        [naviViewControllers btd_insertObject:self.choosePayMethodVC atIndex:combineVCIndex];
        self.navigationController.viewControllers = [naviViewControllers copy];
    }
}

- (void)updatePayTypeView {
    NSString *payAmount = @"";
    NSString *payVoucherMsg = @"";
    NSString *payTypeTitle = CJString(self.currentPayConfig.title);
    if (self.currentPayConfig.type == BDPayChannelTypeCreditPay) {
        // 抖分期，特殊处理,需要从里面取出分期数以及支付金额和营销信息
        __block CJPayBytePayCreditPayMethodModel *selectedCreditPayMethodModel = nil;
        if ([self.currentPayConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
            CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)self.currentPayConfig.payChannel;
            [payChannel.payTypeData.creditPayMethods enumerateObjectsUsingBlock:^(CJPayBytePayCreditPayMethodModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.choose) {
                    selectedCreditPayMethodModel = obj;
                    *stop = YES;
                }
            }];
            
            if (selectedCreditPayMethodModel) {
                payAmount = selectedCreditPayMethodModel.standardShowAmount;
                payVoucherMsg = selectedCreditPayMethodModel.standardRecDesc;
                if (![selectedCreditPayMethodModel.installment isEqualToString:@"1"]) {
                    payTypeTitle = [payTypeTitle stringByAppendingFormat:@"·%@期", CJString( selectedCreditPayMethodModel.installment)];
                }
            } else {
                payAmount = payChannel.payTypeData.standardShowAmount;
                payVoucherMsg = payChannel.payTypeData.standardRecDesc;
            }
        } else {
            CJPayLogAssert(YES, @"下发抖分期数据错误");
        }
    } else {
        payAmount = self.currentPayConfig.payAmount;
        payVoucherMsg = self.currentPayConfig.payVoucherMsg;
    }
    
    if (!Check_ValidString(payAmount)) {
        // 线上兜底策略，理论上不应该走到这里。线下走断言
        CJPayLogAssert(YES, @"下发数据异常，请与后端同学确认数据格式.");
        payAmount = [NSString stringWithFormat:@"%.2f", [self.response totalAmountWithDiscount] / 100.0];
    }
    
    [self.outerPayHomeContentView.marketingMsgView updateWithPayAmount:payAmount voucherMsg:payVoucherMsg];
    [self.outerPayHomeContentView.payTypeMessageView updateDescLabelText:payTypeTitle];
    if (self.currentPayConfig.type != BDPayChannelTypeAddBankCard || Check_ValidString(self.currentPayConfig.frontBankCode)) {
        // 添加银行卡在首页不展示icon
        [self.outerPayHomeContentView.payTypeMessageView updateWithIconUrl:self.currentPayConfig.iconUrl];
    }
    if (self.currentPayConfig.voucherInfo.vouchers.count > 0) {
        NSMutableArray *vouchers = [NSMutableArray array];
        [self.currentPayConfig.voucherInfo.vouchers enumerateObjectsUsingBlock:^(CJPayVoucherModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [vouchers addObject:CJString(obj.label)];
        }];
        [self.outerPayHomeContentView.payTypeMessageView updateWithVoucher:vouchers];
    } else {
        [self.outerPayHomeContentView.payTypeMessageView updateWithVoucher:@[]];
    }
    NSMutableDictionary *trackerParams = [[NSMutableDictionary alloc] initWithDictionary: @{
        @"activity_title": CJString(payVoucherMsg),
        @"addcard_type": CJString(payTypeTitle)
    }];
    [self trackWithEventName:@"wallet_cashier_activity_title_imp" params:[trackerParams copy]];
}

- (void)back {
    [self trackWithEventName:@"wallet_cashier_back_click" params:@{}];
    [super back];
}

#pragma mark - CJChangePayMethodDelegate
- (void)combinePayWithType:(CJPayChannelType)type {
    [self p_gotoCombinationPaymentType:type];
}

- (void)changePayMethodTo:(CJPayDefaultChannelShowConfig *)defaultModel {
    [super changePayMethodTo:defaultModel];
    
    // 卡列表页面切卡时，应该更新 currentPayConfig
    self.currentPayConfig = defaultModel;
    [self updatePayTypeView];
}

#pragma mark - contentDelegate
- (void)didClickBannerWithType:(CJPayChannelType)channelType {
    if (channelType == CJPayChannelTypeBannerCombinePay) {
        [self trackWithEventName:@"wallet_cashier_combine_click" params:@{}];
        [self p_gotoCombinationPaymentType:BDPayChannelTypeBalance];
    } else if (channelType == CJPayChannelTypeBannerVoucher) {
        [self gotoChooseMethodVC:NO];
    }
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
                if (data && [data isKindOfClass:NSDictionary.class]) {
                    NSDictionary *dic = (NSDictionary *)data;
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
    self.outerPayHomeContentView = [[CJPayOPHomeContentView alloc] initWithFrame:CGRectZero createOrderResponse:self.response];
    @CJWeakify(self)
    self.outerPayHomeContentView.payTypeMessageView.arrowBlock = ^{
        @CJStrongify(self)
        [self gotoChooseMethodVC:NO];
    };
    
    return self.outerPayHomeContentView;
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
