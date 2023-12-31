//
//  CJPayHomePageViewController.m
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import <Masonry/View+MASAdditions.h>
#import "CJPayHomePageViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayManager.h"
#import "CJPayCountDownTimerView.h"
#import "CJPayCurrentTheme.h"
#import "CJPaySDKDefine.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayBizChoosePayMethodViewController.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayChannelBizModel.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayKVContext.h"
#import "CJPayProtocolManager.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayAlertUtil.h"
#import "CJPayKVContext.h"
#import "CJPayBDTypeInfo.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayRetainUtil.h"
#import "CJPayMetaSecManager.h"
#import "CJPaySubPayTypeIconTipModel.h"
#import "CJPayRetainInfoV2Config.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"

@interface CJPayHomePageViewController ()<CJPayCountDownTimerViewDelegate, CJPayTrackerProtocol>

#pragma mark - vc
@property (nonatomic, weak) CJPayBizChoosePayMethodViewController *chooseVC;
#pragma mark - views
@property (nonatomic, strong) UIImageView *titleBGImageView;
@property (nonatomic, strong) CJPayCountDownTimerView *countDownView;
@property (nonatomic, strong) CJPayHomeBaseContentView *homeContentView;
#pragma mark - block
@property (nonatomic, copy) void(^completionBlock)(CJPayOrderResultResponse* response, CJPayOrderStatus orderStatus);
#pragma mark - manager
@property (nonatomic, strong) CJPayIntegratedCashierProcessManager *processManager;  // 流程控制
#pragma mark - data
@property (nonatomic, assign) BOOL isCut; //是否展示‘立即查看’灰色框，埋点使用
@property (nonatomic, assign) BOOL confirmNeedRedirectToBindCardPage;
@property (nonatomic, copy) NSArray *channels;
@property (nonatomic, copy) NSString *lastPWD;
@property (nonatomic, strong) CJPayCreateOrderResponse *response;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultConfig;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *showCardConfig;
@property (nonatomic, strong) NSMutableArray *notSufficientFundIds;
@property (nonatomic, assign) NSUInteger lastPayAmount;
@property (nonatomic, copy) NSString *creditPayInstallment;
@property (nonatomic, copy) NSDictionary *commonTrackerParams; // 埋点通参
@property (nonatomic, assign, readonly) CJPayDeskType currentDeskType;
@property (nonatomic, strong) CJPayChannelBizModel *bytePayBizModel;
@property (nonatomic, strong) NSMutableDictionary<NSString *,NSString *> *channelDisableReason; //渠道不可用原因
@property (nonatomic, assign) BOOL isCloseFromRetain;
@property (nonatomic, assign) NSInteger newCustomerChooseIndex; // 新客卡片选择的下标

@end

@implementation CJPayHomePageViewController

@synthesize defaultConfig = _defaultConfig;

- (instancetype)initWithBizParams:(NSDictionary *)bizParams
                           bizurl:(NSString *)bizUrl
                         response:(CJPayCreateOrderResponse *)response completionBlock:(nonnull void (^)(CJPayOrderResultResponse * _Nullable, CJPayOrderStatus))completionBlock {
    self = [super init];
    if (self) {
        self.response = response;
        self.animationType = HalfVCEntranceTypeFromBottom;
        self.completionBlock = [completionBlock copy];
        self.processManager = [[CJPayIntegratedCashierProcessManager alloc] initWith:response bizParams:bizParams];
        self.processManager.completionBlock = [completionBlock copy];
        self.processManager.homeVC = self;
        self.newCustomerChooseIndex = 0;
        self.isStandardDouPayProcess = [[CJPayABTest getABTestValWithKey:CJPayABIsDouPayProcess exposure:NO] isEqualToString:@"1"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.from = @"收银台";
    if (CJ_Pad) {
        if (@available(iOS 13.0, *)) {
            self.modalInPresentation = YES;
        }
    }
    
    [self.contentView addSubview:self.homeContentView];
    [self.containerView addSubview:self.countDownView];
    
    [self setupNavigatinBar];
    
    if (Check_ValidString(self.response.payInfo.bdPay.homePagePictureUrl)) {
        [self.containerView addSubview:self.titleBGImageView];
        [self.containerView bringSubviewToFront:self.navigationBar];
        CJPayMasMaker(self.titleBGImageView, {
            make.top.equalTo(self.navigationBar.mas_top);
            make.left.right.equalTo(self.navigationBar);
            make.height.mas_equalTo(80);
        });
    }
    
    CJPayMasMaker(self.homeContentView, {
        if (self.isPaymentForOuterApp) {
            make.top.equalTo(self.contentView).offset(20);
        } else {
            make.top.equalTo(self.contentView);
        }
        make.left.right.equalTo(self.contentView);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom);
        } else {
            make.bottom.equalTo(self.contentView);
        }
    });
    
    CJPayMasMaker(self.countDownView, {
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset(1);
        make.width.equalTo(self.containerView).offset(-100);
        make.height.mas_equalTo(48);
    });
    [self setupContent];
    [self updateOrderResponse:self.response];
    
    if (self.isPaymentForOuterApp) {
        self.processManager.isPaymentForOuterApp = self.isPaymentForOuterApp;
    }
    
    if (!self.channels) {
        self.channels = [self buildCurrentPayChannels];
    }
    NSMutableArray *campaignInfos = [NSMutableArray array];
    __block NSString *byteTitle = @"";
    [self.channels enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj toActivityInfoTrackerForCreditPay].count >0) {
            [campaignInfos addObjectsFromArray:[obj toActivityInfoTrackerForCreditPay]];
        }
        if ([obj toActivityInfoTracker].count > 0) {
            [campaignInfos addObject:[obj toActivityInfoTracker]];
        }
        
        if (obj.type == BDPayChannelTypeCardCategory) {
            byteTitle = [obj.marks componentsJoinedByString:@","];
        }
    }];
    
    NSMutableDictionary *trackerParams = [[NSMutableDictionary alloc] initWithDictionary: @{
        @"is_cut": Check_ValidString(self.bytePayBizModel.channelConfig.voucherMsg) ? @"1" : @"0",
        @"campaign_info": campaignInfos,
        @"is_combine": self.response.payInfo.bdPay.subPayTypeSumInfo.homePageBanner ? @"1" : @"0",
        @"byte_title": CJString(byteTitle)
    }];
    [trackerParams addEntriesFromDictionary:[self.processManager.createOrderParams btd_dictionaryValueForKey:@"track_info"]];
    if (self.currentDeskType != CJPayDeskTypeBytePayHybrid) {
        [self trackWithEventName:@"wallet_cashier_imp" params:[trackerParams copy]];
    }
    
    [CJPayKVContext kv_setValue:@"0" forKey:CJPayUnionPayIsUnAvailable]; //云闪付绑卡初始化为可用
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(silentRefresh) name:CJPayBindCardSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccess) name:CJPayBindCardSuccessPreCloseNotification object:nil];

}

- (void)silentRefresh {
    self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
}

- (void)p_bindCardSuccess {
    self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
    [self.navigationController popToViewController:self animated:NO];
}

- (void)changeCreditPayInstallment:(NSString *)installment {
    self.creditPayInstallment = installment;
    [CJPayKVContext kv_setValue:CJString(self.creditPayInstallment) forKey:CJPayTrackerCommonParamsCreditStage];
    for (CJPayDefaultChannelShowConfig *config in self.channels) {
        if (config.type == BDPayChannelTypeCreditPay && self.curSelectConfig.type != BDPayChannelTypeCreditPay) {
                [self updateSelectConfig:config];
        }
    }
    NSArray *activityInfos = [[self curSelectConfig] toActivityInfoTrackerForCreditPay:installment];
    [self trackWithEventName:@"wallet_cashier_doustage_click" params:@{
        @"activity_info": Check_ValidArray(activityInfos) ? activityInfos : @[]
    }];
}

- (void)setupNavigatinBar {
    [self useCloseBackBtn];
    
    if(Check_ValidString([CJPayBrandPromoteABTestManager shared].model.cashierTitle)) {
        [self.navigationBar setTitle:CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.cashierTitle)];
    } else {
        [self.navigationBar setTitle:CJPayLocalizedStr(@"支付")];
    }
}

#pragma mark 初始化设置
- (void)setupContent {
    [self refreshContent];
    [self.homeContentView refreshDataWithModels:[self buildPayMethodModels]];
    [self.homeContentView updateAmount:[self.response totalAmountWithDiscount] from:[self.response totalAmountWithDiscount]];
}

- (void)refreshContent {
    [self.countDownView startTimerWithCountTime:@(self.response.deskConfig.leftTime).intValue];
    // 外部 App 拉起时不展示倒计时
    if (self.response.deskConfig.whetherShowLeftTime && !self.isPaymentForOuterApp) {
        self.countDownView.hidden = NO;
    }
}

#pragma mark 选择支付方式
- (void)changeSelectChannelTo:(NSString *)channelIdentify {
    if (channelIdentify == nil || channelIdentify.length < 1) {
        return;
    }
    [self.channels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass: CJPayDefaultChannelShowConfig.class]) {
            CJPayDefaultChannelShowConfig *channel = obj;
            if ([channel.cjIdentify isEqualToString:channelIdentify]) {
                channel.isSelected = YES;
            } else {
                channel.isSelected = NO;
            }
        }
    }];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)buildCurrentPayChannels {
    return [self.response.payInfo showConfigForHomePageWithId:@""];
}

- (NSArray *)buildPayMethodModels {
    NSMutableArray *array = [NSMutableArray array];
    BOOL needEnableBtn = NO;
    for (int i = 0; i < self.channels.count; i++) {
        CJPayChannelBizModel *model = [((CJPayDefaultChannelShowConfig *)self.channels[i]) toBizModel];
        if (model.channelConfig.payChannel.signStatus != 1) {
            needEnableBtn = YES;
        }
        model.isDefaultBytePay = self.response.payInfo.isDefaultBytePay;
        model.isPaymentForOuterApp = self.isPaymentForOuterApp;
        [self p_refreshSecondListTrackerParamsWithModel:model];
        [array addObject:model];
    }
    self.homeContentView.confirmPayBtn.enabled = needEnableBtn;
    return array;
}

- (void)p_refreshSecondListTrackerParamsWithModel:(CJPayChannelBizModel *)bizModel {
    if (bizModel.type == BDPayChannelTypeBalance ||
        bizModel.type == BDPayChannelTypeBankCard ||
        bizModel.type == BDPayChannelTypeAddBankCard) {
        
        self.bytePayBizModel = bizModel;
        NSString *methodStr = [CJPayTypeInfo getChannelStrByChannelType:bizModel.type];
        [self p_addParamsToCommonTracker:CJString(methodStr) forKey:@"second_method_list"];
    }
}

// 确认支付后续接口
- (void)onConfirmPayAction {
    NSArray *activityInfos = [self p_buildActivityInfo];
    [self trackWithEventName:@"wallet_cashier_confirm_click" params:@{
        @"icon_name" : CJString(self.homeContentView.confirmPayBtn.titleLabel.text),
        @"activity_info" : Check_ValidArray(activityInfos) ? activityInfos : @[],
        @"is_combine_page" : @"0"
    }];
    
    if ([self curSelectConfig].type == BDPayChannelTypeAddBankCard) {
        [self trackWithEventName:@"wallet_cashier_add_newcard_click" params:@{
            @"from" : @"收银台一级页确认按钮",
            @"activity_info": Check_ValidArray(activityInfos) ? activityInfos : @[],
            @"addcard_info": CJString([self curSelectConfig].title),
        }];
    }

    if (!self.countDownView.curTimeIsValid) {
        [self showTimeOutAlertVC];
        return;
    }
    // 发起支付
    [self.processManager confirmPayWithConfig:[self curSelectConfig]];
}

- (void)showTimeOutAlertVC {
    [self trackWithEventName:@"wallet_order_timeout_pop_imp" params:@{}];
    @CJWeakify(self)
    [CJPayAlertUtil customSingleAlertWithTitle:CJPayLocalizedStr(@"订单已超时，请重新下单") content:nil buttonDesc:CJPayLocalizedStr(@"我知道了") actionBlock:^{
        @CJStrongify(self)
        [self trackWithEventName:@"wallet_order_timeout_pop_click" params:@{}];
        if (self.navigationController.presentedViewController) {
            @CJWeakify(self)
            [self.navigationController dismissViewControllerAnimated:NO completion:^{
                @CJStrongify(self)
                [self closeActionAfterTime:0 closeActionSource:CJPayOrderStatusTimeout];
            }];
        } else {
            [self closeActionAfterTime:0 closeActionSource:CJPayOrderStatusTimeout];
        }
    } useVC:[UIViewController cj_topViewController]];
}

#pragma mark - CJPayCountDownTimerViewDelegate
- (void)countDownTimerRunOut {
    self.processManager.orderIsInvalid = YES;
    self.countDownView.hidden = YES;
    [self showTimeOutAlertVC];
}

- (void)refreshCountDownTimerState:(CJPayStateType) stateType {
    if (self.response.deskConfig.whetherShowLeftTime) {
        if (!self.countDownView.curTimeIsValid) {
            self.countDownView.hidden = YES;
        } else if (stateType != CJPayStateTypeNone) {
            self.countDownView.hidden = YES;
        } else {
            self.countDownView.hidden = NO;
        }
        if (stateType == CJPayStateTypeTimeOut) {
            self.countDownView.hidden = YES;
        }
    }
}

- (void)invalidateCountDownView {
    [self.countDownView invalidate];
    self.countDownView.hidden = YES;
}

#pragma mark 内容代理实现

- (BOOL)isSecondaryCellView:(CJPayChannelType)channelType
{
    return channelType == BDPayChannelTypeBankCard;
}

#pragma mark - CJPayMethodTableViewDelegate
- (CJPayBizChoosePayMethodViewController *)choosePayMethodVCWithshowNotSufficentFund:(BOOL)showNotSufficentFund {
    CJPayBizChoosePayMethodViewController *vc = [[CJPayBizChoosePayMethodViewController alloc] initWithOrderResponse:self.response defaultConfig:[self curSelectConfig] processManager:self.processManager];
    vc.notSufficientFundsIDs = [self.notSufficientFundIds copy];
    vc.showNotSufficientFundsHeaderLabel = showNotSufficentFund;
    vc.channelDisableReason = [self.channelDisableReason copy];
    @CJWeakify(self)
    vc.delegate = self;
    return vc;
}

- (void)p_tryAddNotSufficientIdsWithDisableStr:(NSString *)disableStr {
    NSString *cjIdentify = [self curSelectConfig].cjIdentify;
    if (Check_ValidString(cjIdentify) && ![self.notSufficientFundIds containsObject:cjIdentify]) {
        [self.notSufficientFundIds addObject:cjIdentify];
        if (Check_ValidString(disableStr)) {
            [self.channelDisableReason setValue:disableStr forKey:cjIdentify];
        }
    }
}

- (void)gotoChooseMethodVC:(BOOL)showNotSufficentFund {
    [self p_gotoChooseMethodVCWithShowTipsView:showNotSufficentFund iconTips:nil tipsMsg:nil];
}

- (void)payLimitWithTipsMsg:(NSString *)tipsMsg iconTips:(CJPaySubPayTypeIconTipModel *)iconTips {
    [self p_tryAddNotSufficientIdsWithDisableStr:CJPayLocalizedStr(@"超出使用限额")];
    [self p_gotoChooseMethodVCWithShowTipsView:YES iconTips:iconTips tipsMsg:CJString(tipsMsg)];
}

- (void)creditPayFailWithTipsMsg:(NSString *)tipsMsg disableMsg:(NSString *)disableMsg {
    [self p_tryAddNotSufficientIdsWithDisableStr:disableMsg];
    [self p_gotoChooseMethodVCWithShowTipsView:YES iconTips:nil tipsMsg:tipsMsg];
}

- (void)p_gotoChooseMethodVCWithShowTipsView:(BOOL)isShowTipView iconTips:(CJPaySubPayTypeIconTipModel *)iconTips tipsMsg:(NSString *)tipsMsg {
    CJPayBizChoosePayMethodViewController *vc = [self choosePayMethodVCWithshowNotSufficentFund:isShowTipView];
    if (isShowTipView) {
        vc.isShowDetentionAlert = YES;
        [self.navigationController popToViewController:self animated:NO];
    } else {
        vc.isShowDetentionAlert = NO;
    }
    if (iconTips) {
        vc.iconTips = iconTips;
    }
    if (Check_ValidString(tipsMsg)) {
        [vc updateNotSufficientFundsViewTitle:tipsMsg];
    }
    if (CJ_Pad && !isShowTipView) {
        [vc presentWithNavigationControllerFrom:self useMask:NO completion:nil];
    } else {
        [self p_dealWithNavigation:vc];
    }
    self.chooseVC = vc;
}

- (void)p_dealWithNavigation:(UIViewController *)vc {
    __block NSUInteger lastHalfScreenIndex = NSNotFound;
    [self.navigationController.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull vc, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
            lastHalfScreenIndex = idx;
            *stop = YES;
        }
    }];

    if (lastHalfScreenIndex < self.navigationController.viewControllers.count - 1) {
        NSMutableArray *vcStack = [self.navigationController.viewControllers mutableCopy];
        [vcStack insertObject:vc atIndex:lastHalfScreenIndex];
        self.navigationController.viewControllers = [vcStack copy];
        [self.navigationController popToViewController:vc animated:YES];
    } else {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

#pragma mark - CJChooseMethodDelegate

- (void)changePayMethodTo:(CJPayDefaultChannelShowConfig *)defaultModel {
    if (defaultModel.type == BDPayChannelTypeBankCard || defaultModel.type == BDPayChannelTypeBalance || defaultModel.type == BDPayChannelTypeIncomePay || defaultModel.type == BDPayChannelTypeCreditPay) {
        self.channels = [self.response.payInfo showConfigForHomePageWithId:defaultModel.cjIdentify];
        NSMutableArray *channels = [self.channels mutableCopy];
        if ([channels containsObject:_showCardConfig]) {
            NSUInteger showCardIndex = [channels indexOfObject:_showCardConfig];
            channels[showCardIndex] = defaultModel;
            self.channels = [channels copy];
        }
        self.showCardConfig = defaultModel;
        if (Check_ValidString(self.chooseVC.creditPayInstallment)) {
            self.creditPayInstallment = self.chooseVC.creditPayInstallment;
        }
    }
    [self updateSelectConfig:defaultModel];
}

- (void)bindCard:(CJPayDefaultChannelShowConfig *)bindCardConfig {
    self.loadingType = CJPayLoadingTypeMethodCellLoading;
    [self.processManager confirmPayWithConfig:bindCardConfig];
}

- (void)updateSelectConfig:(nullable CJPayDefaultChannelShowConfig *)selectConfig {
    // 如果选择的是银行卡支付需要更新银行卡目录cell的选中状态，如果selectConfig为空，配置的默认支付方式是银行卡，也选择银行卡目录cell
    self.defaultConfig = selectConfig;
    CJPayChannelType curType = selectConfig ? selectConfig.type : [CJPayTypeInfo getChannelTypeBy:self.response.payInfo.defaultPayChannel]; // 优先根据选中处理，未选中取默认支付方式
    
    if ([self isSecondaryCellView:curType]) {
        curType = BDPayChannelTypeCardCategory;
    }
    
    if (curType == BDPayChannelTypeCardCategory || curType == CJPayChannelTypeBytePay) {
        __block CJPayDefaultChannelShowConfig *addCardConfig; // 如果没有可用的银行卡，就把
        [self.channels enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.type == BDPayChannelTypeBankCard && [obj enable]) {
                self.showCardConfig = obj;
                *stop = YES;
            } else if ([self isSecondaryCellView:obj.type] && [obj enable]) {
                self.showCardConfig = obj;
                *stop = YES;
            } else if (obj.type == BDPayChannelTypeAddBankCard) {
                addCardConfig = obj;
            } else if (obj.type == BDPayChannelTypeAddBankCardNewCustomer) {
                NSArray<CJPayDefaultChannelShowConfig *> *sholdShowConfig = [self p_getShouldShowConfigs];
                for (CJPayDefaultChannelShowConfig *showConfig in sholdShowConfig) {
                    if (showConfig.isSelected) {
                        self.showCardConfig = showConfig;
                        break;
                    }
                }
            }
        }];
        if (!self.showCardConfig) {
            self.showCardConfig = addCardConfig;
        }
    }
    
    for (CJPayDefaultChannelShowConfig *channel in self.channels) {
        channel.isSelected = NO;
        if (curType == channel.type) {
            channel.isSelected = YES;
            if (!self.defaultConfig) {
                self.defaultConfig = channel;
            }
        }
    }
    [self.homeContentView refreshDataWithModels:[self buildPayMethodModels]];
    [self refreshConfirmBtnRespondEvent];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)p_getShouldShowConfigs {
    return [self.response.payInfo showConfigForCardList];
}

- (void)setDefaultConfig:(CJPayDefaultChannelShowConfig *)defaultConfig {
    _defaultConfig = defaultConfig;
    self.homeContentView.confirmPayBtn.enabled = _defaultConfig != nil && defaultConfig.enable;
}

- (void)refreshConfirmBtnRespondEvent {
    // 当选中的卡不可用时，需要修改底下的button，和点击行为 跳转到绑卡页面
    CJPayDefaultChannelShowConfig *curSelectConfig = [self curSelectConfig];
    if (!curSelectConfig) {
        [self updateConfirmBtnTitle:CJPayLocalizedStr(@"确认支付")];
        return;
    }
    if (curSelectConfig.type == BDPayChannelTypeCardCategory) {
        if (!self.showCardConfig || ![self.showCardConfig enable]) {
            [self updateConfirmBtnTitle:CJPayLocalizedStr(@"添加银行卡支付")];
            self.confirmNeedRedirectToBindCardPage = YES;
            return;
        }
    }
    
    if (curSelectConfig.type == BDPayChannelTypeAddBankCard) {
        [self updateConfirmBtnTitle:CJPayLocalizedStr(@"添加银行卡支付")];
        self.confirmNeedRedirectToBindCardPage = YES;
        return;
    }
    
    if ([curSelectConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)curSelectConfig.payChannel;
        if (Check_ValidString(self.creditPayInstallment)) {
            payChannel.payTypeData.creditPayInstallment = self.creditPayInstallment;
        }
    }
    
    if ([curSelectConfig.payChannel.identityVerifyWay isEqualToString:@"3"]) {
        if ([@[@(BDPayChannelTypeBankCard), @(BDPayChannelTypeBalance), @(BDPayChannelTypeCreditPay)] containsObject:@(curSelectConfig.type)]) {
            // 免密并且是自有支付的支付方式
            [self updateConfirmBtnTitle:CJPayLocalizedStr(@"免密支付")];
            self.confirmNeedRedirectToBindCardPage = NO;
            return;
        }
    }

    self.confirmNeedRedirectToBindCardPage = NO;
    NSString *defaultBtnTitle = [self.response.paySource isEqualToString:@"sign_and_pay"] ? CJPayLocalizedStr(@"支付并开通") : CJPayLocalizedStr(@"确认支付");
    [self updateConfirmBtnTitle:self.response.deskConfig.confirmBtnDesc ?: defaultBtnTitle];
}

- (void)updateConfirmBtnTitle:(NSString *)title {
    [self.homeContentView.confirmPayBtn setTitle:title forState:UIControlStateNormal];
}

#pragma mark - stateView 相关
- (void)showState:(CJPayStateType)stateType {
    [super showState:stateType];
    [self refreshCountDownTimerState:stateType];
    if (stateType == CJPayStateTypeTimeOut) {
        [CJTracker event:@"pay_apply_result_imp" params:@{@"toast": @"支付超时"}];
    }
    if (stateType == CJPayStateTypeSuccess) {
        [CJTracker event:@"pay_apply_result_imp" params:@{@"toast": @"支付成功"}];
    }
    if (stateType == CJPayStateTypeWaiting) {
        [CJTracker event:@"pay_apply_result_imp" params:@{@"toast": @"支付中"}];
    }
}

#pragma mark - 页面关闭
- (void)back{
    [self trackWithEventName:@"wallet_cashier_back_click" params:@{}];
    // 如果需要阻塞返回
    if (self.cjBackBlock) {
        CJ_CALL_BLOCK(self.cjBackBlock);
        return;
    }
    
    CJ_DECLARE_ID_PROTOCOL(CJPayClosePayDeskAlertProtocol);
    if (objectWithCJPayClosePayDeskAlertProtocol && [objectWithCJPayClosePayDeskAlertProtocol respondsToSelector:@selector(showDetainmentAlertWithVC:completion:)]) {
        @CJWeakify(self)
        [objectWithCJPayClosePayDeskAlertProtocol showDetainmentAlertWithVC:self.navigationController completion:^(BOOL isClose) {
            @CJStrongify(self)
            if (isClose) {
                self.isCloseFromRetain = YES;
                [self p_closePayDesk];
            }
        }];
    } else {
        if (![self p_payCancelRetain]) {//不展示弹窗
            self.isCloseFromRetain = NO;
            [self p_closePayDesk];
        }
    }
}

- (BOOL)p_isBytePay:(CJPayChannelType)payType {
    switch (payType) {
        case CJPayChannelTypeNone:
        case CJPayChannelTypeWX:
        case CJPayChannelTypeTbPay:
        case CJPayChannelTypeDyPay:
        case CJPayChannelTypeQRCodePay:
        case CJPayChannelTypeCustom:
        case CJPayChannelTypeWXH5:
        case CJPayChannelTypeSignTbPay:
            return NO;
        
        case CJPayChannelTypeBytePay:
        case CJPayChannelTypeQuickWithdraw:
        case CJPayChannelTypeUnBindBankCard:
        case CJPayChannelTypeFrontCardList:
        case CJPayChannelTypeBDPay:
        case CJPayChannelTypeBannerCombinePay:
        case CJPayChannelTypeBannerVoucher:
        case BDPayChannelTypeBankCard:
        case BDPayChannelTypeBalance:
        case BDPayChannelTypeAddBankCard:
        case BDPayChannelTypeFrontAddBankCard:
        case BDPayChannelTypeCardCategory:
        case BDPayChannelTypeCreditPay:
        case BDPayChannelTypeIncomePay:
        case BDPayChannelTypeTransferPay:
            return YES;
        default:
            CJPayLogAssert(NO, @"Judge it is BytePay or not!");
            return NO;
    }
    
    CJPayLogAssert(NO, @"Judge it is BytePay or not!");
    return NO;
}

- (BOOL)p_lynxRetain:(CJPayRetainUtilModel *)retainUtilModel {
    retainUtilModel.lynxRetainActionBlock = ^(CJPayLynxRetainEventType eventType, NSDictionary * _Nonnull data) {
        self.processManager.lynxRetainTrackerParams = [data cj_dictionaryValueForKey:@"tea_params"]; // 这里前端会传一些埋点参数
        switch (eventType) {
            case CJPayLynxRetainEventTypeOnCancelAndLeave: {
                self.isCloseFromRetain = YES;
                [self p_closePayDesk];
                break;
            }
            case CJPayLynxRetainEventTypeOnConfirm: {
                break;
            }
            case CJPayLynxRetainEventTypeOnPay: {
                [self p_onPay:data];
                break;
            }
            case CJPayLynxRetainEventTypeOnSelectPay: {
                [self p_onSelectPay:data];
                break;
            }
            default:
                break;
        }
    };
    
    return [CJPayRetainUtil couldShowLynxRetainVCWithSourceVC:self.navigationController retainUtilModel:retainUtilModel completion:nil];
}

- (void)p_onPay:(NSDictionary *)data {
    [self confirmButtonClick];
}

- (void)p_onSelectPay:(NSDictionary *)data {
    NSString *index = [data cj_stringValueForKey:@"index"];
    NSArray<CJPayDefaultChannelShowConfig *> *array = [self buildCurrentPayChannels];
    __block CJPayDefaultChannelShowConfig *selectedConfig;
    [array enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *tmpIndex = [NSString stringWithFormat:@"%ld",obj.index];
        if ([CJString(tmpIndex) isEqualToString:index]) {
            selectedConfig = obj;
            *stop = YES;
        }
    }];
    [self updateSelectConfig:selectedConfig];
    
    if ([CJString([data cj_stringValueForKey:@"need_pay"]) isEqualToString:@"need"]) {
        // 可配置成选择支付方式并支付，或者直接支付。
        [self p_onPay:data];
    }
}

- (BOOL)p_payCancelRetain {
    CJPayDefaultChannelShowConfig *curSelectConfig = [self curSelectConfig];
    
    CJPayRetainUtilModel *retainUtilModel = [CJPayRetainUtilModel new];
    retainUtilModel.retainInfo = [self.response.payInfo bdPay].retainInfo;
    retainUtilModel.intergratedTradeNo = self.response.tradeInfo.tradeNo;
    retainUtilModel.processInfoDic = [self.response.payInfo bdPay].promotionProcessInfo;
    retainUtilModel.positionType = CJPayRetainHomePage;
    retainUtilModel.intergratedMerchantID = self.response.merchantInfo.merchantId;
    retainUtilModel.trackDelegate = self;
    
    if ([self p_buildRetainInfoV2Config:retainUtilModel]) {
        return [self p_lynxRetain:retainUtilModel];
    }
    // 保留原来的逻辑，只有bytepay才有挽留弹窗。 因为挽留弹窗要支持配置化，所以这期其他的支付方式也支持挽留弹窗
    if (![self p_isBytePay:curSelectConfig.type]) {
        return NO;
    }
    
    retainUtilModel.eventNameForPopUpClick = @"wallet_cashier_keep_pop_click";
    retainUtilModel.eventNameForPopUpShow = @"wallet_cashier_keep_pop_show";
    
    @CJWeakify(self)
    retainUtilModel.closeActionBlock = ^{
        @CJStrongify(self)
        self.isCloseFromRetain = YES;
        [self p_closePayDesk];
    };
    
    return [CJPayRetainUtil couldShowRetainVCWithSourceVC:self.navigationController retainUtilModel:retainUtilModel];
}

- (BOOL)p_buildRetainInfoV2Config:(CJPayRetainUtilModel *)retainUtilModel {
    CJPayDefaultChannelShowConfig *curSelectConfig = [self curSelectConfig];
    
    if (!Check_ValidDictionary(curSelectConfig.retainInfoV2)) {
        return NO;
    }
    NSDictionary *homePageInfo = [curSelectConfig.retainInfoV2 cj_dictionaryValueForKey:@"home_page_info"];//标准收银台首页挽留弹窗的设置
    CJPayMerchantInfo *merchantInfo = self.response.merchantInfo;
    
    
    CJPayRetainInfoV2Config *config = [[CJPayRetainInfoV2Config alloc] init];
    config.retainInfoV2 = curSelectConfig.retainInfoV2;
    config.selectedPayType = curSelectConfig.subPayType;
    config.isCombinePay = curSelectConfig.isCombinePay;
    config.index = [NSString stringWithFormat:@"%ld",curSelectConfig.index];
    
    NSString *lynxSchema = [homePageInfo cj_stringValueForKey:@"lynx_schema"];
    config.retainSchema = lynxSchema;
    config.notShowRetain = (!Check_ValidString(lynxSchema)); // 如果不展示挽留弹窗的话homePageInfo应该下发为null。但是因为后端链路调用问题，最后拿到的值是 {} 。所以与各端约定好使用lynxSchema来判断展不展示挽留弹窗。
    
    config.appId = merchantInfo.appId;
    config.merchantId = merchantInfo.merchantId; // 这个merchantId在前端验密页主要做埋点用。因为取不到追光merchantId,所以这里merchant_id 与 jhMerchantId 取同一个值
    config.jhMerchantId = merchantInfo.merchantId;
    
    config.traceId = [self.response.feMetrics cj_stringValueForKey:@"trace_id"];
    config.processInfo = [self.response.payInfo bdPay].promotionProcessInfo;
    config.from = @"native";
    config.method = [self.commonTrackerParams cj_stringValueForKey:@"method"];
    config.hostDomain = [CJPayBaseRequest jhHostString];
    
    
    retainUtilModel.retainInfoV2Config = config;
    
    return YES;
}

- (void)p_showStayAlertViewWithViewController {
    @CJWeakify(self)
    BOOL hasVoucher = NO;
    
    for (CJPayDefaultChannelShowConfig *config in self.channels) {
        if (Check_ValidString(config.discountStr)) {
            hasVoucher = YES;
            break;
        }
    }
    
    void(^leftActionBlock)(void) = ^{
        @CJStrongify(self)
        self.isCloseFromRetain = YES;
        [self trackWithEventName:@"wallet_cashier_keep_pop_click"
                          params:@{@"is_discount":hasVoucher ? @"1" : @"0" ,
                                   @"button_name" : @"0"
                          }];
        [self p_closePayDesk];
    };
    
    void(^rightActionBlock)(void) = ^{
        @CJStrongify(self)
        [self trackWithEventName:@"wallet_cashier_keep_pop_click"
                          params:@{@"is_discount":hasVoucher ? @"1" : @"0" ,
                                   @"button_name" : @"1"
                          }];
    };
    
    [CJPayAlertUtil customDoubleAlertWithTitle:hasVoucher ? CJPayLocalizedStr(@"继续支付可享受优惠，确定放弃吗") : CJPayLocalizedStr(@"还差一步就支付完成了，确定放弃吗")
                                 content:nil
                          leftButtonDesc:CJPayLocalizedStr(@"放弃")
                         rightButtonDesc:CJPayLocalizedStr(@"继续付款")
                         leftActionBlock:leftActionBlock
                         rightActioBlock:rightActionBlock useVC:self];
    [self trackWithEventName:@"wallet_cashier_keep_pop_show" params:@{@"is_discount":hasVoucher ? @"1" : @"0"}];
}

- (void)p_closePayDesk {
    [self invalidateCountDownView];
    @CJWeakify(self)
    [super closeWithAnimation:YES comletion:^(BOOL isFinish) {
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.completionBlock, nil, CJPayOrderStatusCancel);
    }];
}

#pragma mark - contentDelegate
- (void)didSelectAtIndex:(int)selectIndex {
    if (selectIndex > self.channels.count) {
        return;
    }
    CJPayDefaultChannelShowConfig *selectConfig = ((CJPayDefaultChannelShowConfig *)[self.channels cj_objectAtIndex:selectIndex]);
    // 支付方式不可用、【签约并支付】的已签约 的时候不能选中
    if (!selectConfig || !selectConfig.enable || selectConfig.payChannel.signStatus == 1) {
        return;
    }
    
    if (selectConfig.type == BDPayChannelTypeAddBankCard) {
        self.loadingType = CJPayLoadingTypeMethodCellLoading;
        [self.processManager confirmPayWithConfig:selectConfig];
        NSArray *activityInfos = [self p_buildActivityInfo];
        [self trackWithEventName:@"wallet_cashier_add_newcard_click" params:@{
            @"from" : @"收银台一级页",
            @"activity_info": Check_ValidArray(activityInfos) ? activityInfos : @[],
            @"addcard_info": CJString(selectConfig.title),
        }];
        return;
    } else if (selectConfig.type == CJPayChannelTypeQRCodePay) {
        self.loadingType = CJPayLoadingTypeMethodCellLoading;
        [self.processManager confirmPayWithConfig:selectConfig];
        return;
    } else if (selectConfig.type == BDPayChannelTypeBankCard ||
               ([self isSecondaryCellView:selectConfig.type] && selectConfig.type == BDPayChannelTypeBalance)) { //余额支付在二级
        [self gotoChooseMethodVC:NO];
        NSArray *activityInfos = [self p_buildActivityInfo];
        [self trackWithEventName:@"wallet_cashier_more_method_click" params:@{
            @"activity_info": Check_ValidArray(activityInfos) ? activityInfos : @[]
        }];
        return;
    } else if (selectConfig.type == BDPayChannelTypeCreditPay) { //余额支付在二级
        [self gotoChooseMethodVC:NO];
        return;
    }
    if (selectConfig.type == BDPayChannelTypeCreditPay) {
        [CJPayKVContext kv_setValue:@"1" forKey:CJPayTrackerCommonParamsCreditStage];
    } else {
        [CJPayKVContext kv_setValue:@"" forKey:CJPayTrackerCommonParamsCreditStage];
    }
    
    if (selectConfig.type == BDPayChannelTypeCardCategory) {
        [self setDefaultSecondaryCardInstallment];
    } else {
        [self clearSelectSecondaryCardInstallment];
    }
    
    [self updateSelectConfig:selectConfig];
    NSArray *activityInfos = [self p_buildActivityInfo];
    [self trackWithEventName:@"wallet_cashier_choose_method_click" params:@{
        @"activity_info": Check_ValidArray(activityInfos) ? activityInfos : @[],
        @"page_type":@(1)
    }];
}

- (void)setDefaultSecondaryCardInstallment {
    // 目前端内抖音二级支付卡片样式只有两种：抖音支付卡片样式、抖音月付样式
    for (CJPayDefaultChannelShowConfig *config in self.channels) {
        if (config.type == BDPayChannelTypeCreditPay && ([config.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]])) {
            CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)config.payChannel;
            BOOL hasChoose = NO;
            for (CJPayBytePayCreditPayMethodModel *model in payChannel.payTypeData.creditPayMethods) {
                if (model.choose) {
                    hasChoose = YES;
                }
            }
            if (hasChoose == NO) {
                CJPayBytePayCreditPayMethodModel *model = [payChannel.payTypeData.creditPayMethods firstObject];
                model.choose = YES;
                self.creditPayInstallment = @"1";
            }
            break;
        } else if (config.type == BDPayChannelTypeAddBankCardNewCustomer) {
            for (NSInteger index = 0;index < 2; index++) {
                CJPaySubPayTypeInfoModel *payModel = [config.subPayTypeData cj_objectAtIndex:self.newCustomerChooseIndex];
                if (index == self.newCustomerChooseIndex) {
                    payModel.isChoosed =YES;
                }
            }
            break;
        }
    }
}

- (void)clearSelectSecondaryCardInstallment {
    for (CJPayDefaultChannelShowConfig *config in self.channels) {
        if (config.type == BDPayChannelTypeCreditPay && ([config.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]])) {
            CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)config.payChannel;
            for (CJPayBytePayCreditPayMethodModel *model in payChannel.payTypeData.creditPayMethods) {
                model.choose = NO;
            }
            break;
        } else if (config.type == BDPayChannelTypeAddBankCardNewCustomer) {
            for (CJPaySubPayTypeInfoModel *payModel in config.subPayTypeData) {
                payModel.isChoosed = NO;
            }
            break;
        }
    }
}

- (void)confirmButtonClick {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeConfirmPay];
    self.loadingType = CJPayLoadingTypeConfirmBtnLoading;
    [self onConfirmPayAction];
}

- (CJPayDefaultChannelShowConfig *)curSelectConfig {
    // 如果当前选择的是银行卡的目录，则直接返回银行卡
    if ([_showCardConfig.payChannel isKindOfClass:[CJPaySubPayTypeInfoModel class]]) {
        CJPaySubPayTypeInfoModel *payChannel = (CJPaySubPayTypeInfoModel *)_showCardConfig.payChannel;
        if (Check_ValidString(self.creditPayInstallment)) {
            payChannel.payTypeData.creditPayInstallment = self.creditPayInstallment;
        }
    }

    if (_defaultConfig && (_defaultConfig.type == CJPayChannelTypeBytePay ||
                           _defaultConfig.type == BDPayChannelTypeCardCategory ||
                           _defaultConfig.type == BDPayChannelTypeBankCard)) {
        return _showCardConfig;
    }
    
    return _defaultConfig;
}

- (CJPayDeskType)currentDeskType {
    return [self.response.deskConfig currentDeskType];
}

- (void)didSelectNewCustomerSubCell:(NSInteger)selectIndex {
    CJPayDefaultChannelShowConfig *bytePayConfig = nil;
    CJPayDefaultChannelShowConfig *subPayConfig = nil;
    for (CJPayDefaultChannelShowConfig *config in self.channels) {
        if (config.type == BDPayChannelTypeAddBankCardNewCustomer) {
            subPayConfig = config;
        } else if (config.type == BDPayChannelTypeCardCategory) {
            bytePayConfig = config;
        }
    }
    NSInteger maxCardShow = 2;
    if (selectIndex < maxCardShow) {
        self.newCustomerChooseIndex = selectIndex;
        
        CJPaySubPayTypeInfoModel * selectedModel = [subPayConfig.subPayTypeData cj_objectAtIndex:selectIndex];
        CJPaySubPayTypeInfoModel * deSelectedModel = [subPayConfig.subPayTypeData cj_objectAtIndex:!selectIndex];
        selectedModel.isChoosed = YES;
        deSelectedModel.isChoosed = NO;
        [self updateSelectConfig:bytePayConfig];
    } else {
        // 进入选卡界面
        [self gotoChooseMethodVC:NO];
    }
}

#pragma mark - Getter

- (UIImageView *)titleBGImageView {
    if (!_titleBGImageView) {
        _titleBGImageView = [UIImageView new];
        _titleBGImageView.backgroundColor = [UIColor clearColor];
        if (Check_ValidString(self.response.payInfo.bdPay.homePagePictureUrl)) {
            [_titleBGImageView cj_setImageWithURL:[NSURL URLWithString:self.response.payInfo.bdPay.homePagePictureUrl]];
        }
    }
    return _titleBGImageView;
}

- (CJPayCountDownTimerView *)countDownView {
    if (!_countDownView) {
        _countDownView = [CJPayCountDownTimerView new];
        _countDownView.hidden = YES;
        _countDownView.delegate = self;
        _countDownView.style = CJPayCountDownTimerViewStyleNormal;
    }
    return _countDownView;
}

- (CJPayHomeBaseContentView *)homeContentView {
    if (!_homeContentView) {
        _homeContentView = [self getCurrentContentView];
        _homeContentView.tableViewDelegate = self;
        _homeContentView.delegate = self;
    }
    return _homeContentView;
}

- (CJPayHomeBaseContentView *)getCurrentContentView {
    //子类需覆写
    return nil;
}

- (NSMutableArray *)notSufficientFundIds {
    if (!_notSufficientFundIds) {
        _notSufficientFundIds = [NSMutableArray new];
    }
    return _notSufficientFundIds;
}

- (NSDictionary *)commonTrackerParams {
    _commonTrackerParams = [self.processManager buildCommonTrackDic:@{}];
    CJPayDefaultChannelShowConfig *trackerConfig = (self.curSelectConfig.type == BDPayChannelTypeCardCategory) ? self.showCardConfig : self.curSelectConfig;
    NSMutableDictionary *mutableDic = [_commonTrackerParams mutableCopy];
    if (!Check_ValidString([mutableDic cj_stringValueForKey:@"method"])) {
        [mutableDic addEntriesFromDictionary:@{
            @"method" : [CJPayTypeInfo getTrackerMethodByChannelConfig:trackerConfig]
        }];
    }
    _commonTrackerParams = [mutableDic copy];
    
    return _commonTrackerParams;
}

- (NSMutableDictionary *)channelDisableReason {
    if (!_channelDisableReason) {
        _channelDisableReason = [NSMutableDictionary new];
    }
    return _channelDisableReason;
}

#pragma mark - Tracker
- (void)p_addParamsToCommonTracker:(NSObject *)obj forKey:(NSString *)key {
    if (!Check_ValidString(key)) {
        return;
    }
    NSMutableDictionary *trackerParams = [self.commonTrackerParams mutableCopy];
    [trackerParams cj_setObject:obj forKey:key];
    self.commonTrackerParams = trackerParams;
}

- (NSArray *)p_buildActivityInfo {
    if ([self curSelectConfig].type == BDPayChannelTypeCreditPay) {
        return [[self curSelectConfig] toActivityInfoTrackerForCreditPay];
    }
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *infoDict = [[self curSelectConfig] toActivityInfoTracker];
    if (infoDict.count > 0) {
        [activityInfos addObject:infoDict];
    }
    return [activityInfos copy];
}

#pragma mark - CJPayTrackerProtocol

- (void)event:(NSString *)event params:(NSDictionary *)params {
    [self trackWithEventName:event params:params];
}

- (void)trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:self.commonTrackerParams];
    if (params) {
        [mutableDic addEntriesFromDictionary:params];
    }
    
    if (self.outerAppID) {
        [mutableDic cj_setObject:CJString(self.outerAppID) forKey:@"outer_aid"];
    }
    
    [mutableDic cj_setObject:self.isSignAndPay ? @"1" : @"0" forKey:@"pay_source"];
    
    [CJTracker event:eventName params:mutableDic];
}

#pragma mark - CJPayStateDelegate
- (void)stateButtonClick:(NSString *)buttonName {
    [self close];
}

@end

@implementation CJPayHomePageViewController(HomeVCProtocol)

#pragma mark - CJPayHomeVCProtocol
//- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayHomeVCCloseActionSource)source {
//    [self invalidateCountDownView];
//
//    if (time < 0) { // 小于等于0的话，不关闭收银台，让业务方手动关闭
//        return;
//    }
//    [CJTracker event:@"pay_apply_cannel" params:@{}];
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        @CJWeakify(self)
//        [self.navigationController dismissViewControllerAnimated:YES completion:^{
//            //消失后执行
//            @CJStrongify(self)
//            CJ_CALL_BLOCK(self.completionBlock, self.processManager.resResponse, [self p_convertSourceToStatus:source]);
//        }];
//    });
//}

- (void)enableConfirmBtn:(BOOL)enable {
    self.homeContentView.confirmPayBtn.userInteractionEnabled = enable;
}

- (void)closeActionAfterTime:(CGFloat)time closeActionSource:(CJPayOrderStatus)orderStatus {
    [self invalidateCountDownView];
    
    if (time < 0) { // 小于等于0的话，不关闭收银台，让业务方手动关闭
        return;
    }
    [CJTracker event:@"pay_apply_cannel" params:@{}];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJWeakify(self)
        if (self.navigationController.presentingViewController) {
            UIViewController *topVC = [UIViewController cj_topViewController];
            if ([topVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
                ((CJPayNavigationController *)topVC.navigationController).dismissAnimatedType = CJPayDismissAnimatedTypeFromBottom;
            }
            [self.navigationController.presentingViewController dismissViewControllerAnimated:YES completion:^{
                //消失后执行
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.completionBlock, self.processManager.resResponse, orderStatus);
            }];
        } else {
            [self.navigationController dismissViewControllerAnimated:YES completion:^{
                //消失后执行
                @CJStrongify(self)
                CJ_CALL_BLOCK(self.completionBlock, self.processManager.resResponse, orderStatus);
            }];
        }
    });
}

//- (CJPayOrderStatus)p_convertSourceToStatus:(CJPayHomeVCCloseActionSource)source {
//    switch (source) {
//        case CJPayHomeVCCloseActionSourceFromBack:
//        case CJPayHomeVCCloseActionSourceFromCloseAction:
//            return CJPayOrderStatusCancel;
//        case CJPayHomeVCCloseActionSourceFromOrderTimeOut:
//            return CJPayOrderStatusTimeout;
//        default:
//            return CJPayOrderStatusNull;
//    }
//}

- (void)updateOrderResponse:(CJPayCreateOrderResponse *)response {
    NSString *lastIdentify = self.defaultConfig.cjIdentify;
    self.response = response;
    self.processManager.orderResponse = response; // response更新后需要同步更新processmanger，以保证processid等信息是最新的
    self.channels = [self buildCurrentPayChannels];
    if ([UIViewController cj_foundTopViewControllerFrom:self] == self) { //顶部vc为自己时更新首页，否则静默刷新
        [self changeSelectChannelTo:lastIdentify];
        [CJPayCurrentTheme shared].showStyle = self.response.deskConfig.showStyle;
        [self updateSelectConfig:nil];
    }
}

- (void)notifyNotsufficient:(NSString *)bankCardId {
    [self p_tryAddNotSufficientIdsWithDisableStr:@""];
    [self gotoChooseMethodVC:YES];
}

- (void)startLoading {
    CJ_DelayEnableView(self.view);
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    if ([vc isKindOfClass:self.class] || [vc isKindOfClass:CJPayBizChoosePayMethodViewController.class]) {
        switch (self.loadingType) {
            case CJPayLoadingTypeConfirmBtnLoading:
                @CJStartLoading(self.homeContentView.confirmPayBtn)//非模态,但默认加载时禁用交互
                break;
            case CJPayLoadingTypeMethodCellLoading:
                if (self.chooseVC) {
                    @CJStartLoading(self.chooseVC.payMethodView)
                } else {
                    @CJStartLoading(self.homeContentView)
                }
                break;
            case CJPayLoadingTypeNullLoading:
            default:
                [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
                self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
                break;
        }
    } else if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
        self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        self.loadingType = CJPayLoadingTypeTopLoading;
    }
}

- (void)stopLoading {
    CJ_DelayEnableView(self.view);
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    if ([vc isKindOfClass:self.class] || [vc isKindOfClass:CJPayBizChoosePayMethodViewController.class]) {
        switch (self.loadingType) {
            case CJPayLoadingTypeConfirmBtnLoading:
                @CJStopLoading(self.homeContentView.confirmPayBtn)
                break;
            case CJPayLoadingTypeMethodCellLoading:
                if (self.chooseVC){
                    @CJStopLoading(self.chooseVC.payMethodView)
                } else {
                    @CJStopLoading(self.homeContentView)
                }
                break;
            case CJPayLoadingTypeNullLoading:
            default:
                [[CJPayLoadingManager defaultService] stopLoading];
                break;
        }
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)closeDesk {
    // 自己处理导航栈，解决转场问题
    self.navigationController.viewControllers = @[self];
    [self closeActionAfterTime:0 closeActionSource:CJPayOrderStatusCancel];
}

- (NSDictionary *)trackerParams {
    return @{
        @"second_method_list" : CJString([CJPayTypeInfo getChannelStrByChannelType:self.bytePayBizModel.type]),
        @"outer_aid" : CJString(self.outerAppID),
        @"cashier_style" : self.isSignAndPay ? @"1" : @"0"
    };
}



@end
