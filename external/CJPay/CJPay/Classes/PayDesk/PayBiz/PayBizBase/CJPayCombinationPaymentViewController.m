//
//  CJPayCombinationPaymentViewController.m
//  Pods
//
//  Created by xiuyuanLee on 2021/4/12.
//

#import "CJPayCombinationPaymentViewController.h"

#import "CJPayBizChoosePayMethodViewController.h"
#import "CJPayTypeInfo+Util.h"
#import "CJPayCombinePaymentAmountModel.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayCreateOrderResponse.h"
#import "CJPayBytePayMethodView.h"
#import "CJPayCombinationPaymentAmountView.h"
#import "CJPayIntegratedCashierProcessManager.h"
#import "CJPayStyleButton.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayUIMacro.h"
#import "CJPaySubPayTypeData.h"
#import "CJPayCardManageModule.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayBizDeskUtil.h"

@interface CJPayCombinationPaymentViewController ()<CJPayMethodTableViewDelegate>

#pragma mark - views
@property (nonatomic, strong) CJPayCombinationPaymentAmountView *combinationPaymentAmountView;
@property (nonatomic, strong) CJPayBytePayMethodView *payMethodView;
@property (nonatomic, strong) CJPayStyleButton *confirmPayBtn;

#pragma mark - manager
@property (nonatomic, strong) CJPayIntegratedCashierProcessManager *processManager;
@property (nonatomic, weak) UIViewController *homeVC;

#pragma mark - data
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultConfig;
@property (nonatomic, strong) CJPayCreateOrderResponse *response;
@property (nonatomic, copy) NSArray<CJPayChannelBizModel *> *bizModels;

@property (nonatomic, assign) NSInteger balanceAmount;
@property (nonatomic, assign) NSInteger incomeAmount;
@property (nonatomic, assign) NSInteger bankCardAmount;

@property (nonatomic, assign) CJPayLoadingType loadingType;

@end

@implementation CJPayCombinationPaymentViewController

- (instancetype)initWithOrderResponse:(CJPayCreateOrderResponse *)response
                        defaultConfig:(CJPayDefaultChannelShowConfig *)config
                       processManager:(CJPayIntegratedCashierProcessManager *)manager
                                 type:(CJPayChannelType)type {
    self = [super init];
    if (self) {
        self.response = response;
        config.combineType = type;
        self.combineType = type;
        self.defaultConfig = config;
        self.processManager = manager;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_updateWithResponse:) name:BDPayBindCardSuccessRefreshNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccess:) name:CJPayBindCardSuccessPreCloseNotification object:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
    self.bizModels = [self p_buildPayMethodModels];
    [self p_setupAmount];
    [self p_updatePayMethodView];
    NSArray *showConfigArray = [self getShouldShowConfigs];
    NSMutableArray *campaignInfos = [NSMutableArray array];
    NSMutableArray *methodLists = [NSMutableArray array];
    [showConfigArray enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj toActivityInfoTracker].count > 0) {
            [campaignInfos addObject:[obj toActivityInfoTracker]];
        }
        if ([obj toActivityInfoTrackerForCreditPay].count > 0) {
            [campaignInfos addObjectsFromArray:[obj toActivityInfoTrackerForCreditPay]];
        }
        if ([obj toMethodInfoTracker].count > 0) {
            [methodLists addObject:[obj toMethodInfoTracker]];
        }
    }];
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:@{
        @"balance_amount" : @(self.balanceAmount),
        @"card_amount" : @(self.bankCardAmount),
        @"campaign_info" : campaignInfos,
        @"all_method_list" : methodLists,
    }];
    if (self.showNotSufficientFundsHeaderLabel) {
        [params cj_setObject:@"1" forKey:@"error_info"];
    }
    [self p_trackWithEventName:@"wallet_cashier_combine_imp" params:params];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.processManager.backVC = self;
    
    [self.combinationPaymentAmountView updateStyleIfShowNotSufficient:self.showNotSufficientFundsHeaderLabel];
}

- (void)p_bindCardSuccess:(NSNotification *)notification {
    self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
}

- (void)back {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.showNotSufficientFundsHeaderLabel) {
        [dict cj_setObject:@"1" forKey:@"error_info"];
    }
    [self p_trackWithEventName:@"wallet_cashier_combine_back_click" params:dict];
    self.processManager.backVC = nil;
    [super back];
}

- (void)showState:(CJPayStateType)stateType {
    self.navigationBar.bottomLine.hidden = stateType == CJPayStateTypeNone;
    self.combinationPaymentAmountView.hidden = stateType != CJPayStateTypeNone;
    [super showState:stateType];
}

- (void)startLoading {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    if ([vc isKindOfClass:self.class]) {
        if (self.loadingType == CJPayLoadingTypeConfirmBtnLoading) {
            @CJStartLoading(self.confirmPayBtn)
        } else {
            [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
        }
    } else if ([vc isKindOfClass:CJPayHalfPageBaseViewController.class]) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinHalfLoading];
        self.loadingType = CJPayLoadingTypeDouyinHalfLoading;
    } else {
       [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading];
        self.loadingType = CJPayLoadingTypeTopLoading;
    }

//    会导致支付成功后引导页无法响应点击事件，需要再排查一下， todo: xutianxi
//    CJ_DelayEnableView(self.view.window);
}

- (void)stopLoading {
    UIViewController *vc = [UIViewController cj_foundTopViewControllerFrom:self];
    if ([vc isKindOfClass:self.class]) {
        switch (self.loadingType) {
            case CJPayLoadingTypeConfirmBtnLoading:
                @CJStopLoading(self.confirmPayBtn)
                break;
            default:
                [[CJPayLoadingManager defaultService] stopLoading];
                break;
        }
    } else {
        [[CJPayLoadingManager defaultService] stopLoading];
    }
}

- (void)notifyNotsufficient:(NSString *)bankCardId {
    if (!self.showNotSufficientFundsHeaderLabel) {
        self.showNotSufficientFundsHeaderLabel = YES;
        [self.combinationPaymentAmountView updateStyleIfShowNotSufficient:self.showNotSufficientFundsHeaderLabel];
    }
    
    if (Check_ValidString(bankCardId) && ![self.notSufficientFundsIDs containsObject:bankCardId]) {
        [self.notSufficientFundsIDs addObject:bankCardId];
    }
    
    [self p_reloadCurrentView];
}

- (void)p_reloadCurrentView {
    self.bizModels = [self p_buildPayMethodModels];
    [self p_updatePayMethodView];
    [self.payMethodView scrollToTop];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - private method
- (void)p_setupUI {
    [self.contentView addSubview:self.combinationPaymentAmountView];
    [self.contentView addSubview:self.payMethodView];
    [self.contentView addSubview:self.confirmPayBtn];
    
    CJPayMasMaker(self.combinationPaymentAmountView, {
        make.top.equalTo(self.contentView).offset(-4);
        make.left.right.equalTo(self.contentView);
    })
    CJPayMasMaker(self.confirmPayBtn, {
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        if (@available(iOS 11.0, *)) {
            make.bottom.equalTo(self.contentView.mas_safeAreaLayoutGuideBottom).offset(CJ_IPhoneX ? 0 : -8);
        } else {
            make.bottom.equalTo(self.contentView).offset(-8);
        }
    })
    CJPayMasMaker(self.payMethodView, {
        make.top.equalTo(self.combinationPaymentAmountView.mas_bottom);
        make.bottom.equalTo(self.confirmPayBtn.mas_top);
        make.left.right.equalTo(self.contentView);
    })
}

- (void)p_setupAmount {
    NSInteger totalAmount = [self.response totalAmountWithDiscount];
    if (self.type == BDPayChannelTypeIncomePay) {
        self.balanceAmount = [self.response.payInfo.bdPay.subPayTypeSumInfo incomeTypeData].incomeAmount;
        self.bankCardAmount = totalAmount - self.balanceAmount;
    } else if (self.type == BDPayChannelTypeBalance) {
        self.balanceAmount = [self.response.payInfo.bdPay.subPayTypeSumInfo balanceTypeData].balanceAmount;
        self.bankCardAmount = totalAmount - self.balanceAmount;
    }
    
    CGFloat floatTotalAmount = totalAmount / 100.0;
    CGFloat floatBalanceAmount = self.balanceAmount / 100.0;
    CGFloat floatBankCardAmount = self.bankCardAmount / 100.0;
    
    CJPayCombinePaymentAmountModel *amountModel = [CJPayCombinePaymentAmountModel new];
    amountModel.totalAmount = [NSString stringWithFormat:@"%0.2f", floatTotalAmount];
    amountModel.detailInfo = CJString(self.response.tradeInfo.tradeName);
    amountModel.cashAmount = [NSString stringWithFormat:@"%0.2f", floatBalanceAmount];
    amountModel.bankCardAmount = [NSString stringWithFormat:@"%0.2f", floatBankCardAmount];
    
    [self.combinationPaymentAmountView updateAmount:amountModel];
}

- (void)p_updatePayMethodView {
    [self.bizModels enumerateObjectsUsingBlock:^(CJPayChannelBizModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isConfirmed = [obj isEqual:[self.defaultConfig toBizModel]];
        obj.isConfirmed = isConfirmed;
    }];
    self.payMethodView.models = self.bizModels;
}

- (void)updateSelectConfig:(nullable CJPayDefaultChannelShowConfig *)selectConfig {
    
    self.defaultConfig = selectConfig;
    
    [self p_updatePayMethodView];
}

- (CJPayDefaultChannelShowConfig *)p_curSelectConfig {
    return self.defaultConfig;
}

- (void)p_updateWithResponse:(NSNotification *)notification {
    if (nil != notification.object && [notification.object isKindOfClass:CJPayCreateOrderResponse.class]) {
        self.response = (CJPayCreateOrderResponse *)notification.object;
        self.bizModels = [self p_buildPayMethodModels];
        [self p_updatePayMethodView];
    }
}

// 组合支付确认接口
- (void)p_onConfirmPayAction {
    
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *infoDict = [[self p_curSelectConfig] toActivityInfoTracker];
    if (infoDict.count > 0) {
        [activityInfos addObject:infoDict];
    }
    
    if ([self p_curSelectConfig].type == BDPayChannelTypeAddBankCard) {
        [self p_trackWithEventName:@"wallet_cashier_add_newcard_click" params:@{
            @"from" : @"组合支付页",
            @"activity_info": activityInfos,
            @"addcard_info": CJString([self p_curSelectConfig].title),
        }];
    }
    
    NSString *buttonName = [self p_curSelectConfig].type == BDPayChannelTypeAddBankCard ? @"添加新卡支付" : @"确认支付";
    if ([[self p_curSelectConfig].payChannel.identityVerifyWay isEqualToString:@"3"]) {
        buttonName = @"免密支付";
    }
    
    [self p_trackWithEventName:@"wallet_cashier_confirm_click" params:@{
        @"balance_amount" : @(self.balanceAmount),
        @"card_amount" : @(self.bankCardAmount),
        @"icon_name" : CJString(buttonName),
        @"activity_info" : activityInfos,
        @"is_combine_page" : @"1"
    }];
    
    self.loadingType = CJPayLoadingTypeConfirmBtnLoading;
    CJ_DelayEnableView(self.view);
    CJ_CALL_BLOCK(self.payBlock, [self p_curSelectConfig]);
}

- (NSArray<CJPayChannelBizModel *> *)p_buildPayMethodModels {
    NSMutableArray<CJPayChannelBizModel *> *array = [NSMutableArray array];
    
    NSMutableDictionary *invalidMethods = [NSMutableDictionary new];
    
    CJPayDefaultChannelShowConfig *firstChannelConfig = nil;
    
    for (CJPayDefaultChannelShowConfig *channelConfig in [self getShouldShowConfigs]) {
        CJPayChannelBizModel *model = [channelConfig toBizModel];
        model.isChooseMethodSubPage = YES;
        model.hasConfirmBtnWhenUnConfirm = YES;
        if ([self.notSufficientFundsIDs containsObject:channelConfig.cjIdentify]) {
            model.enable = NO;
            model.isConfirmed = NO;
            if (!Check_ValidString(model.reasonStr)) {
                model.reasonStr = CJPayLocalizedStr(@"银行卡余额不足");
                model.subTitle = CJPayLocalizedStr(@"银行卡余额不足");
            }
            [invalidMethods cj_setObject:model forKey:channelConfig.cjIdentify];
        } else {
            if ((model.type != BDPayChannelTypeBalance) && (model.type != BDPayChannelTypeIncomePay) && (model.type != BDPayChannelTypeCreditPay)) {
                if (firstChannelConfig == nil) {
                    firstChannelConfig = channelConfig;
                }
                [array addObject:model];
            }
        }
    }
    
    // 如果没有选中的卡，就默认选中第一张
    __block BOOL hasConfirmedChannel = NO;
    [array enumerateObjectsUsingBlock:^(CJPayChannelBizModel * _Nonnull channel, NSUInteger idx, BOOL * _Nonnull stop) {
        if (channel.isConfirmed && [channel isEqual:[self.defaultConfig toBizModel]]) {
            hasConfirmedChannel = YES;
            self.defaultConfig = channel.channelConfig;
            *stop = YES;
        }
    }];
    if (!hasConfirmedChannel) {
        self.defaultConfig = firstChannelConfig;
    }
    
    // 根据余额不足要求重新排序展示卡列表
    for (NSString *cjidentify in self.notSufficientFundsIDs) {
        id object = [invalidMethods cj_objectForKey:cjidentify];
        if (object) {
            [array addObject:object];
        }
    }
    return [CJPayBizDeskUtil reorderDisableCardsWithMethodArray:array
                                             zoneSplitInfoModel:self.response.payInfo.bdPay.subPayTypeSumInfo.zoneSplitInfoModel];
}

- (NSArray<CJPayDefaultChannelShowConfig *> *)getShouldShowConfigs {
    NSArray *showConfigs = [self.response.payInfo showConfigForCardList];
    [showConfigs enumerateObjectsUsingBlock:^(CJPayDefaultChannelShowConfig * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.isCombinePay = YES;
    }];
    return showConfigs;
}

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *mutableDic = [[NSMutableDictionary alloc] initWithDictionary:self.commonTrackerParams];
    [mutableDic addEntriesFromDictionary:params];
    [mutableDic addEntriesFromDictionary:@{
        @"method" : [CJPayTypeInfo getTrackerMethodByChannelConfig:[self p_curSelectConfig]]
    }];
    [CJTracker event:eventName params:mutableDic];
}

#pragma mark - CJPayMethodTableViewDelegate
- (void)didSelectAtIndex:(int)selectIndex {
    if (selectIndex < 0 || selectIndex >= self.payMethodView.models.count) {
        return;
    }
    
    CJPayChannelBizModel *model = [self.payMethodView.models cj_objectAtIndex:selectIndex];
    CJPayDefaultChannelShowConfig *selectChannelConfig = model.channelConfig;
    
    if(!model.enable) {
        return;
    }
    
    [self updateSelectConfig:selectChannelConfig];
    
    NSMutableArray *activityInfos = [NSMutableArray array];
    NSDictionary *infoDict = [selectChannelConfig toActivityInfoTracker];
    if (infoDict.count > 0) {
        [activityInfos addObject:infoDict];
    }
    
    [self p_trackWithEventName:@"wallet_cashier_combine_method_click" params:@{
        @"activity_info": activityInfos,
        @"front_bank_code": CJString(selectChannelConfig.frontBankCode)
    }];
}

#pragma mark - getter & setter
- (NSMutableArray<NSString *> *)notSufficientFundsIDs {
    if (!_notSufficientFundsIDs) {
        _notSufficientFundsIDs = [NSMutableArray new];
    }
    return _notSufficientFundsIDs;
}

#pragma mark - lazy views
- (CJPayCombinationPaymentAmountView *)combinationPaymentAmountView {
    if (!_combinationPaymentAmountView) {
        _combinationPaymentAmountView = [[CJPayCombinationPaymentAmountView alloc] initWithType:self.type];
    }
    return _combinationPaymentAmountView;
}

- (CJPayBytePayMethodView *)payMethodView {
    if (!_payMethodView) {
        _payMethodView = [CJPayBytePayMethodView new];
        _payMethodView.isChooseMethodSubPage = YES;
        _payMethodView.delegate = self;
    }
    return _payMethodView;
}

- (CJPayStyleButton *)confirmPayBtn {
    if (!_confirmPayBtn) {
        _confirmPayBtn = [CJPayStyleButton new];
        
        CJPayButtonStyle *buttonStyle = [CJPayThemeStyleManager shared].serverTheme.buttonStyle;
        if (buttonStyle) {
            _confirmPayBtn.cornerRadius = buttonStyle.cornerRadius;
        }
        _confirmPayBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmPayBtn.titleLabel.textColor = [UIColor whiteColor];
        
        [_confirmPayBtn cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        if (self.type == BDPayChannelTypeBalance) {
            if ([[self p_curSelectConfig].payChannel.identityVerifyWay isEqualToString:@"3"]) {
                [_confirmPayBtn setTitle:CJPayLocalizedStr(@"零钱+银行卡免密支付") forState:UIControlStateNormal];
            } else {
                [_confirmPayBtn setTitle:CJPayLocalizedStr(@"零钱+银行卡支付") forState:UIControlStateNormal];
            }
        } else if (self.type == BDPayChannelTypeIncomePay) {
            if ([[self p_curSelectConfig].payChannel.identityVerifyWay isEqualToString:@"3"]) {
                [_confirmPayBtn setTitle:CJPayLocalizedStr(@"钱包收入+银行卡免密支付") forState:UIControlStateNormal];
            } else {
                [_confirmPayBtn setTitle:CJPayLocalizedStr(@"钱包收入+银行卡支付") forState:UIControlStateNormal];
            }
        }
        [_confirmPayBtn addTarget:self action:@selector(p_onConfirmPayAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmPayBtn;
}

@end
