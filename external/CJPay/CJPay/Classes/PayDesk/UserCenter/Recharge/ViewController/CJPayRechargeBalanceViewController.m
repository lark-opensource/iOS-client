//
//  BDPayRechargeBalanceViewController.m
//  CJPay
//
//  Created by 王新华 on 3/10/20.
//

#import "CJPayRechargeBalanceViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayRechargeMainView.h"
#import "CJPayFrontCashierManager.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPayFrontCashierCreateOrderRequest.h"
#import "CJPayRechargeResultViewController.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayLineUtil.h"
#import "CJPayCommonSafeHeader.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayQuickPayChannelModel.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayBalanceRechargeController.h"
#import "CJPayMetaSecManager.h"
#import "CJPayBalanceVerifyManager.h"
#import "CJPayWebViewUtil.h"
#import "CJPayDouyinKeyboard.h"
#import "CJPayBindCardManager.h"
#import "CJPayUserCenter.h"
#import "CJPayNavigationBarView.h"
#import "CJPayBalancePromotionModel.h"

@interface CJPayRechargeBalanceViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) CJPayRechargeMainView *mainView;
@property (nonatomic, strong) UILabel *serviceTipsLabel;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayButton *rechargeRecordButton;

@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, copy) void(^completion)(CJPayBDOrderResultResponse* response, CJPayOrderStatus orderStatus);
@property (nonatomic, copy) NSDictionary *bizParams;
@property (nonatomic, copy) NSString *bizUrl;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultConfig;
@property (nonatomic, strong) NSMutableArray *notSufficientIds;
@property (nonatomic, strong) CJPayBalanceRechargeController *frontCashierController;
@property (nonatomic, strong) CJPayLoadingButton *confirmBtn;
@property (nonatomic, strong) CJPayLoadingButton *staticConfirmBtn;
@property (nonatomic, copy) NSString *memBizOrderNo;

@end

@implementation CJPayRechargeBalanceViewController

- (instancetype)initWithBizParams:(NSDictionary *)bizParams bizurl:(NSString *)bizUrl response:(CJPayBDCreateOrderResponse *)response completionBlock:(nonnull void (^)(CJPayBDOrderResultResponse *resResponse, CJPayOrderStatus orderStatus))completionBlock {
    self = [super init];
    if (self) {
        _bizParams = bizParams;
        _bizUrl = bizUrl;
        _orderResponse = response;
        _completion = [completionBlock copy];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    CJPayLogInfo(@"dealloc");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setNavTitle:CJPayLocalizedStr(@"零钱充值")];
    [self.navigationBar addSubview:self.rechargeRecordButton];
    
    [self setupViews];
    [self p_updateOrderResponse];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(silentRefreshAndCheckVoucher:) name:CJPayBindCardSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(silentRefreshAndCheckVoucher:) name:CJPayH5BindCardSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(silentRefresh) name:BDPaySignSuccessAndConfirmFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccessPreClose) name:CJPayBindCardSuccessPreCloseNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidInBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];

    [self p_trackerWithEventName:@"wallet_change_cashier_imp"
                          params:@{@"bank_name": CJString(self.defaultConfig.title)}];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([self.mainView.amountView.amountField.textField isFirstResponder]) {
        [self.mainView.amountView resignFirstResponder];
    }
    if (self.confirmBtn.superview != self.view) {
        [self.view addSubview:self.confirmBtn];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.confirmBtn.superview) {
        [self.view addSubview:self.confirmBtn];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mainView.amountView becomeFirstResponder];
    });
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide) name:UIKeyboardDidHideNotification object:nil];
}

- (void)bindCardFromCardList:(BDChooseCardDismissLoadingBlock)dismissLoadingBlock {
    if (!Check_ValidString(self.mainView.amountView.getAmountValue)) {
        [self p_bindCard:dismissLoadingBlock];
        return;
    }
    if ([self p_isHitBindCardTest]) {
        CJ_CALL_BLOCK(dismissLoadingBlock);
        [self p_confirmPayWithBindCardAndPay:YES];
        return;
    }
    [self p_bindCard:dismissLoadingBlock];
}

- (void)silentRefreshAndCheckVoucher:(NSNotification *)noti {
    NSDictionary *dic = noti.object;
    if (![dic isKindOfClass:NSDictionary.class]) {
        [self p_silentRefreshWithCheckVoucher:NO];
        return;
    }
    
    self.memBizOrderNo = [dic cj_stringValueForKey:@"bind_order_no"];
    if ([dic cj_integerValueForKey:@"bind_scene"] == CJPayLynxBindCardBizScenceBalanceRecharge) {
        [self p_silentRefreshWithCheckVoucher:YES];
        return;
    }
    [self p_silentRefreshWithCheckVoucher:NO];
}

- (void)silentRefresh {
    [self p_silentRefreshWithCheckVoucher:NO];
}

- (void)p_silentRefreshWithCheckVoucher:(BOOL)isNeedCheckVoucher {
    NSDictionary *bizConParams = [self p_buildBizParams:self.bizParams isNeedCheckVoucher:isNeedCheckVoucher];
    @CJStartLoading(self.mainView.methodView)
    @CJWeakify(self)
    [CJPayFrontCashierCreateOrderRequest startRequestWithAppid:[bizConParams cj_stringValueForKey:@"app_id"] merchantId:[bizConParams cj_stringValueForKey:@"merchant_id"] bizContentParams:@{@"params": bizConParams?:@{}} completion:^(NSError * _Nullable error, CJPayBDCreateOrderResponse * _Nullable response) {
        @CJStrongify(self)
        @CJStopLoading(self.mainView.methodView)
        if (!response.isSuccess) {
            return;
        }
        
        [self.frontCashierController.frontCashierVerifyManager useLatestResponse];
        self.orderResponse = response;
        [self p_updateOrderResponse];
        // 绑卡成功后查询发券结果
        if (!isNeedCheckVoucher) {
            return;
        }
        NSString *toastMsg = self.orderResponse.balancePromotionModel.hasBindCardLottery ? @"绑卡成功\n券已发放" : @"绑卡成功";
        [CJPayToast toastImage:@"cj_balance_success_icon" title:toastMsg duration:2 inWindow:self.cj_window];
        [self p_trackerWithEventName:@"wallet_recharge_toast_imp" params:@{
            @"toast_name": @"充值绑卡"
        }];
    }];
}

- (void)p_updateOrderResponse {
    CJPayDefaultChannelShowConfig *config = [self.orderResponse.payTypeInfo obtainDefaultConfig];
    if (config.enable) {
        self.defaultConfig = config;
        self.frontCashierController.payContext.defaultConfig = config;
    } else {
        self.defaultConfig = nil;
    }
}

- (void)p_bindCardSuccessPreClose {
    [self.navigationController popToViewController:self animated:NO];
}

- (void)p_trackPromotionWithEvent:(NSString *)event param:(nullable NSDictionary *)param {
    CJPayBalancePromotionModel *promotionMdel = self.orderResponse.balancePromotionModel;
    if (!Check_ValidString(promotionMdel.promotionDescription)) {
        return;
    }
    [self p_trackerWithEventName:event params:@{
        @"plan_no": CJString(promotionMdel.planNo),
        @"material_no": CJString(promotionMdel.materialNo),
        @"resource_no": CJString(promotionMdel.resourceNo),
        @"biztype": CJString(promotionMdel.bizType),
    }];
}

#pragma mark: get Methods;
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
    }
    return _scrollView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [UIView new];
        _scrollContentView.backgroundColor = [UIColor cj_f8f8f8ff];
        [_scrollContentView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapContent)]];
    }
    return _scrollContentView;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

- (CJPayRechargeMainView *)mainView {
    if (!_mainView) {
        _mainView = [CJPayRechargeMainView new];
        _mainView.defaultDiscount = self.orderResponse.balancePromotionModel.promotionDescription;
        [self p_trackPromotionWithEvent:@"wallet_recharge_marketing_imp" param:nil];
        @CJWeakify(self)
        _mainView.chooseCardBlock = ^{
            [weak_self gotoChooseCard];
        };
        
        _mainView.amountView.rechargeTextFieldTapGestureClickBlock = ^{
            @CJStrongify(self)
            [self p_trackerWithEventName:@"wallet_change_cashier_input"
                                        params:@{@"bank_name": CJString(self.defaultConfig.title)}];
        };
        
        _mainView.amountView.amountDidChangeBlock = ^{
            @CJStrongify(self)
            NSString *amount = [self.mainView.amountView getAmountValue];
            
            if (self.defaultConfig && [self.defaultConfig.payChannel isKindOfClass:CJPayQuickPayCardModel.class]) {
                CJPayQuickPayCardModel *model = (CJPayQuickPayCardModel *)self.defaultConfig.payChannel;
                if ([amount doubleValue] > [model.perPayLimit doubleValue]) {
                    [self.mainView showLimitLabel:YES];
                } else {
                    [self.mainView showLimitLabel:NO];
                }
            }
            [self p_updateConfirmBtnState];
        };
    }
    return _mainView;
}

- (CJPayLoadingButton *)p_genConfirmBtn {
    CJPayLoadingButton *confirmBtn = [[CJPayLoadingButton alloc] init];
    [confirmBtn setTitle:@"充值" forState:UIControlStateNormal];
    [confirmBtn.titleLabel setFont:[UIFont cj_boldFontOfSize:16]];
    [confirmBtn cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
    
    UIColor *disableColor = [self cj_currentThemeMode] == CJPayThemeModeTypeDark? [UIColor cj_colorWithHexString:@"78203D"]: [UIColor cj_colorWithHexString:@"F3B5C4"];
    UIImage *disableBgImage = [UIImage cj_imageWithColor:disableColor];
    UIImage *normalBgImage = [UIImage cj_imageWithColor:[UIColor cj_fe2c55ff]];
    [confirmBtn setBackgroundImage:disableBgImage forState:UIControlStateSelected];
    [confirmBtn setBackgroundImage:disableBgImage forState:UIControlStateHighlighted];
    [confirmBtn setBackgroundImage:disableBgImage forState:UIControlStateDisabled];
    [confirmBtn setBackgroundImage:normalBgImage forState:UIControlStateNormal];
    
    UIColor *disableTitleColor = [self cj_currentThemeMode] == CJPayThemeModeTypeDark? [UIColor cj_ffffffWithAlpha:0.34] :  [UIColor cj_ffffffWithAlpha:1] ;
    [confirmBtn setTitleColor:disableTitleColor forState:UIControlStateDisabled];
    confirmBtn.frame = CGRectMake(CJ_SCREEN_WIDTH - 16 - kKeyBoardConfirmBtnWidth, CJ_SCREEN_HEIGHT- 56 - 81, kKeyBoardConfirmBtnWidth, 56);
    confirmBtn.clipsToBounds = YES;
    confirmBtn.layer.cornerRadius = 8;
    return confirmBtn;
}

- (CJPayLoadingButton *)staticConfirmBtn {
    if (!_staticConfirmBtn) {
        _staticConfirmBtn = [self p_genConfirmBtn];
    }
    return _staticConfirmBtn;
}

- (UIButton *)confirmBtn {
    if (!_confirmBtn) {
        _confirmBtn = [self p_genConfirmBtn];
        [_confirmBtn addTarget:self action:@selector(p_confirmClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmBtn;
}

- (UILabel *)serviceTipsLabel {
    if (!_serviceTipsLabel) {
        _serviceTipsLabel = [UILabel new];
        _serviceTipsLabel.text = CJPayLocalizedStr(@"本服务由合众易宝提供");
        _serviceTipsLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _serviceTipsLabel;
}

- (CJPayButton *)rechargeRecordButton {
    if (!_rechargeRecordButton) {
        _rechargeRecordButton = [CJPayButton new];
        _rechargeRecordButton.titleLabel.textAlignment = NSTextAlignmentRight;
        _rechargeRecordButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [_rechargeRecordButton addTarget:self action:@selector(rechargeRecordClick) forControlEvents:UIControlEventTouchUpInside];
        [_rechargeRecordButton setTitleColor:[UIColor cj_161823ff] forState:UIControlStateNormal];
        [_rechargeRecordButton setTitle:CJPayLocalizedStr(@"充值记录") forState:UIControlStateNormal];
        _rechargeRecordButton.titleLabel.font = [UIFont cj_fontOfSize:15];
    }
    return _rechargeRecordButton;
}

#pragma mark - private methods
- (void)p_updateConfirmBtnState {
    BOOL overPerPayLimit = NO;
    if (self.defaultConfig.payChannel && [self.defaultConfig.payChannel isKindOfClass:CJPayQuickPayCardModel.class]) {
        CJPayQuickPayCardModel *cardModel = (CJPayQuickPayCardModel *)self.defaultConfig.payChannel;
        overPerPayLimit = [self.mainView.amountView getAmountValue].doubleValue * 100 > [cardModel.perPayLimit integerValue] * 100;
    }
    
    if (Check_ValidString([self.mainView.amountView getAmountValue]) &&
        [self.mainView.amountView getAmountValue].doubleValue * 100 >= 1 &&
        !overPerPayLimit) {
        self.staticConfirmBtn.enabled = YES;
        self.confirmBtn.enabled = YES;
    } else {
        self.staticConfirmBtn.enabled = NO;
        self.confirmBtn.enabled = NO;
    }
    
}

- (void)setupViews {
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.staticConfirmBtn];
    [self.view addSubview:self.confirmBtn];
    [self.scrollView addSubview:self.scrollContentView];
    [self.scrollContentView addSubview:self.mainView];
    [self.scrollContentView addSubview:self.serviceTipsLabel];
    
    CJPayMasMaker(self.scrollView, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view).offset([self navigationHeight]);
    });
    
    CJPayMasMaker(self.scrollContentView, {
        make.edges.equalTo(self.scrollView);
        make.size.equalTo(self.scrollView);
    });
    
    CJPayMasMaker(self.mainView, {
        make.left.equalTo(self.scrollContentView).offset(12);
        make.right.equalTo(self.scrollContentView).offset(-12);
        make.top.equalTo(self.scrollContentView);
    });
    
    CJPayMasMaker(self.serviceTipsLabel, {
        make.bottom.equalTo(self.scrollContentView).offset(-CJ_TabBarSafeBottomMargin - 16);
        make.centerX.equalTo(self.scrollContentView);
    });
    
    self.confirmBtn.enabled = NO;
    [self p_adapterTheme];
    // 显示账户安全险
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.view addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.centerX.width.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-16-CJ_TabBarSafeBottomMargin);
            make.height.mas_equalTo(18);
        });
        self.serviceTipsLabel.hidden = YES;
    }
    
    CJPayMasMaker(self.rechargeRecordButton, {
        make.right.equalTo(self.navigationBar).offset(-16);
        if(CJ_Pad) {
            make.centerY.equalTo(self.navigationBar);
        } else {
            make.centerY.equalTo(self.navigationBar.mas_bottom).offset(-22);
        }
        make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right).offset(6);
    });
}

-(void)p_adapterTheme {
    CJPayLocalThemeStyle *localTheme = self.cjLocalTheme ?: [CJPayLocalThemeStyle defaultThemeStyle];
    if ([self cj_currentThemeMode] != CJPayThemeModeTypeDark) {
        [self.navigationBar setBackgroundColor:[UIColor cj_f8f8f8ff]];
    }

    [self.rechargeRecordButton cj_setBtnTitleColor:localTheme.withdrawTitleTextColor];
    self.scrollContentView.backgroundColor = localTheme.rechargeBackgroundColor;
    self.serviceTipsLabel.textColor = localTheme.withdrawServiceTextColor;
}

- (void)tapContent {
    [self.view endEditing:YES];
}

- (void)setDefaultConfig:(CJPayDefaultChannelShowConfig * _Nullable)defaultConfig {
    _defaultConfig = defaultConfig;
    NSArray *cardList = self.orderResponse.payTypeInfo.quickPay.cards;
    self.mainView.methodView.cardNum = cardList ? cardList.count : 0;
    self.mainView.selectConfig = defaultConfig;
    [self.scrollContentView setNeedsLayout];
    [self.scrollContentView layoutIfNeeded];
    [self p_updateConfirmBtnState];
}

- (void)gotoChooseCard {
    if (self.defaultConfig || self.orderResponse.payTypeInfo.quickPay.cards.count > 0) {
        BDChooseCardCommonModel *model = [BDChooseCardCommonModel new];
        model.hasSfficientBlockBack = NO;
        model.notSufficientFundsIDs = [self.notSufficientIds copy];
        model.orderResponse = self.orderResponse;
        model.defaultConfig = self.defaultConfig;
        model.fromVC = self;
        @CJWeakify(self)
        model.dismissLoadingBlock = ^{
            @CJStrongify(self)
            @CJStopLoading(self.mainView.methodView)
        };
        model.chooseCardCompletion = ^(CJPayChooseCardResultModel * _Nonnull model) {
            @CJStrongify(self)
            if (model.isCancel) {
                CJPayLogInfo(@"选卡取消");
            } else {
                if (!model.isNewCard) {
                    self.defaultConfig = model.config;
                    [self p_trackerWithEventName:@"wallet_change_cashier_method_page_click"
                                                params:@{@"bank_name": CJString(self.defaultConfig.title)}];
                    
                }
            }
        };
        model.bindCardBlock = ^(BDChooseCardDismissLoadingBlock _Nonnull dismissLoadingBlock) {
            @CJStrongify(self)
            [self bindCardFromCardList:dismissLoadingBlock];
        };
        @CJStartLoading(self.mainView.methodView)
        model.bizParams = [self p_buildBizParams:model.bizParams isNeedCheckVoucher:NO];
        model.trackerParams = [self p_baseTrackerParams];
        [[CJPayFrontCashierManager shared] chooseCardWithCommonModel:model];
        [self p_trackerWithEventName:@"wallet_change_cashier_choose_method_click"
                              params:@{@"bank_name": CJString(self.defaultConfig.title)}];
        
        [self p_trackCardSelectImp];
       
    } else {
        [self.view endEditing:YES];
        [self p_trackPromotionWithEvent:@"wallet_recharge_marketing_click" param:nil];
        @CJStartLoading(self.mainView.methodView)
        @CJWeakify(self)
        [self bindCardFromCardList:^{
            @CJStrongify(self)
            @CJStopLoading(self.mainView.methodView)
        }];
        [self p_trackerWithEventName:@"wallet_change_cashier_add_newcard_click"
                              params:@{@"from": @"收银台一级页"}];
    }
}

- (void)p_trackCardSelectImp {
    NSUInteger cardNum = self.orderResponse.payTypeInfo.quickPay.cards.count;
    NSMutableString *cardListStr = [NSMutableString new];
    __block BOOL cardAble = NO;
    [self.orderResponse.payTypeInfo.quickPay.cards enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        CJPayQuickPayCardModel *cardModel = obj;
        [cardListStr appendString:[NSString stringWithFormat:@"%@ ", cardModel.frontBankCodeName]];
        if ([cardModel.status isEqualToString:@"1"]) {
            cardAble = YES;
        }
    }];
    
    // 为了和安卓保持一致，先将错就错一下
    NSString *ifAbleStr = cardAble ? @"0" : @"1";
    
    [self p_trackerWithEventName:@"wallet_change_cashier_method_page_imp"
                          params:@{@"bank_name": CJString(self.defaultConfig.title),
                                   @"bank_num": @(cardNum),
                                   @"bank_list": CJString(cardListStr),
                                   @"if_able": ifAbleStr}];
}

//组装请求接口service
- (NSDictionary *)p_buildBizParams:(NSDictionary *)bizParams isNeedCheckVoucher:(BOOL)isNeedCheckVoucher {
    NSMutableDictionary *bizConParams = [NSMutableDictionary dictionaryWithDictionary:bizParams];
    [bizConParams cj_setObject:@"prepay.balance.confirm" forKey:@"service"];
    if (isNeedCheckVoucher) {
        [bizConParams cj_setObject:self.memBizOrderNo forKey:@"independent_bind_order_no"];
    }
    return bizConParams;
}

- (void)p_bindCard:(void(^)(void))finishBlock {
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.cardBindSource = CJPayCardBindSourceTypeBalanceRecharge;
    model.appId = self.orderResponse.merchant.appId;
    model.merchantId = self.orderResponse.merchant.merchantId;
    model.processInfo = self.orderResponse.processInfo;
    model.jhAppId = self.orderResponse.merchant.jhAppId;
    model.jhMerchantId = self.orderResponse.merchant.intergratedMerchantId;
    model.dismissLoadingBlock = ^{
        CJ_CALL_BLOCK(finishBlock);
    };
    model.completion = ^(CJPayBindCardResultModel * _Nonnull cardResult) {
        if (cardResult.result == CJPayBindCardResultSuccess) {
            self.memBizOrderNo = cardResult.memberBizOrderNo;
//                CJPayDefaultChannelShowConfig *bindCardShowConfig = [[cardResult.bankCardInfo toQuickPayCardModel] buildShowConfig].firstObject;
//                self.defaultConfig = bindCardShowConfig;
        } else {
            CJPayLogInfo(@"绑卡失败 code: %ld", cardResult.result);
        }
    };
    
    [[CJPayFrontCashierManager shared] bindCardWithCommonModel:model];
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *baseParams = [[self p_baseTrackerParams] mutableCopy];
    [baseParams addEntriesFromDictionary:params];
    [CJTracker event:eventName params:[baseParams copy]];
}

- (NSDictionary *)p_baseTrackerParams {
    NSString *amountStr = CJString([self.mainView.amountView getAmountValue]);
    amountStr = (amountStr.length == 0) ? @"0" : amountStr;
    NSInteger amount = [amountStr intValue];
    amount *= 100; // 单位 元 => 分
    amountStr = [NSString stringWithFormat:@"%ld", amount];
    NSString *hasBankCardStr = [self.orderResponse.payTypeInfo.quickPay hasValidBankCard] ? @"1" : @"0";
    NSDictionary *bindCardTrackerBaseParams = [[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams];

    return @{
        @"app_id": CJString(self.orderResponse.merchant.appId),
        @"merchant_id": CJString(self.orderResponse.merchant.merchantId),
        @"is_chaselight": @"1",
        @"amount": amountStr,
        @"caijing_source": @"充值收银台",
        @"is_bankcard": hasBankCardStr,
        @"needidentify" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"needidentify"]),
        @"haspass" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"haspass"])
    };
}

- (void)p_confirmPayWithBindCardAndPay:(BOOL)isBindCardAndPay {
    CJPayFrontCashierContext *context = [CJPayFrontCashierContext new];
    context.createOrderParams = self.bizParams;
    @CJWeakify(self)
    context.latestOrderResponseBlock = ^CJPayBDCreateOrderResponse * _Nonnull{
        @CJStrongify(self)
        return self.orderResponse;
    };
    context.defaultConfig = self.defaultConfig;
    context.changeSelectConfigBlock = ^(CJPayDefaultChannelShowConfig * _Nonnull selConfig) {
        @CJStrongify(self)
        self.defaultConfig = selConfig;
    };
    context.extCallback = ^(CJPayHomeVCEvent eventType, id  _Nullable value) {
        @CJStrongify(self)
        if (value && eventType == CJPayHomeVCEventNotifySufficient && ![self.notSufficientIds containsObject:value]) {
            [self.notSufficientIds insertObject:value atIndex:0];
        }
    };
    context.latestNotSufficientFundIds = ^NSArray * _Nonnull{
        @CJStrongify(self)
        return [self.notSufficientIds copy];
    };
    context.homePageVC = self;
    NSDecimalNumber *tradeNumber = [NSDecimalNumber decimalNumberWithString:[weak_self.mainView.amountView getAmountValue]];
    NSString *tradeAmount = [[tradeNumber decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] stringValue];
    context.confirmRequestParams = @{ @"pre_params": @{@"total_amount": CJString(tradeAmount), @"currency":@"CNY"}};
    [self p_startPaymentWithContext:context
                   isBindCardAndPay:isBindCardAndPay
                         completion:^(CJPayManagerResultType type, CJPayBDOrderResultResponse * _Nullable response) {
        @CJStrongify(self);
        if (type == CJPayManagerResultCancel) {
            CJ_CALL_BLOCK(weak_self.completion, response, CJPayOrderStatusCancel);
            [weak_self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            NSString *statusStr = @"";
            NSString *resultStr = @"";
            switch (response.tradeInfo.tradeStatus) {
                case CJPayOrderStatusSuccess:
                    statusStr = @"充值成功";
                    resultStr = @"1";
                    break;
                case CJPayOrderStatusProcess:
                    statusStr = @"充值处理中";
                    resultStr = @"0";
                    break;
                default:
                    statusStr = @"充值失败";
                    resultStr = @"0";
                    break;
            }
            [self p_trackerWithEventName:@"wallet_change_cashier_pay_finish_page_imp"
                                  params:@{@"bank_name": CJString(self.defaultConfig.title),
                                           @"status": statusStr}];
            
            [self p_trackerWithEventName:@"wallet_change_cashier_result"
                                  params:@{@"bank_name": CJString(self.defaultConfig.title),
                                           @"result": resultStr,
                                           @"error_code": CJString(response.code),
                                           @"error_message": CJString(response.msg),
                                           @"loading_time": [NSString stringWithFormat:@"%f", response.responseDuration]}];
            
            CJPayRechargeResultViewController *viewController = [CJPayRechargeResultViewController new];
            viewController.tradeInfo = response.tradeInfo;
            viewController.merchant = response.merchant;
            viewController.closeAfterTime = response.closeAfterTime;
            viewController.response = response;
            viewController.memberBizOrderNo = self.memBizOrderNo;
            viewController.preOrderTrackInfo = @{@"is_bankcard" : CJString(self.orderResponse.preTradeInfoWrapper.trackInfo.bankCardStatus)};
            
            viewController.closeAction = ^{
                CJ_CALL_BLOCK(weak_self.completion, response, CJPayOrderStatusNull);
            };
            if ([self.navigationController isKindOfClass:CJPayNavigationController.class]) {
                CJPayNavigationController *cjpayNavi = (CJPayNavigationController *)self.navigationController;
                [cjpayNavi pushViewControllerSingleTop:viewController animated:YES completion:nil];
            } else {
                [self.navigationController setViewControllers:@[viewController] animated:YES];
            }
        }
    }];
}

- (void)p_confirmClick {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeConfirmPay];
    @CJWeakify(self)
    [self.view endEditing:YES];
    if (!self.defaultConfig || (self.defaultConfig && [self.defaultConfig.status isEqualToString:@"0"])) {
        [self p_trackerWithEventName:@"wallet_change_cashier_add_newcard_click"
                              params:@{@"from": @"收银台一级页确认按钮"}];
        
        [self p_trackerWithEventName:@"wallet_change_cashier_confirm_click"
                              params:@{@"bank_name": CJString(self.defaultConfig.title),
                                       @"icon_name": @"添加新卡"
                              }];
        if ([self p_isHitBindCardTest]) {
            [self p_confirmPayWithBindCardAndPay:YES];
            return;
        }
        
        @CJStartLoading(self.confirmBtn)
        @CJWeakify(self)
        [self p_bindCard:^{
            @CJStrongify(self)
            @CJStopLoading(self.confirmBtn)
        }];
        return;
    }
    [self p_trackerWithEventName:@"wallet_recharge_password_verify_show"
                          params:@{}];

    [self p_trackerWithEventName:@"wallet_change_cashier_confirm_click"
                          params:@{@"bank_name": CJString(self.defaultConfig.title),
                                   @"icon_name": @"充值"
                          }];
    [self p_confirmPayWithBindCardAndPay:NO];

}

- (BOOL)p_isHitBindCardTest {
    NSString *chargeWithdrawStyle = self.orderResponse.userInfo.chargeWithdrawStyle;
    return Check_ValidString(chargeWithdrawStyle) && ![chargeWithdrawStyle isEqualToString:@"v1"];
}

- (void)p_startPaymentWithContext:(CJPayFrontCashierContext *)context isBindCardAndPay:(BOOL)isBindCardAndPay completion:(void (^)(CJPayManagerResultType, CJPayBDOrderResultResponse * _Nullable))completion {
    self.frontCashierController = [CJPayBalanceRechargeController new];
    self.frontCashierController.isBindCardAndPay = isBindCardAndPay;
    @CJWeakify(self)
    [self.frontCashierController startPaymentWithContext:context completion:^(CJPayManagerResultType type, CJPayBDOrderResultResponse * _Nullable response) {
        @CJStrongify(self)
        id tmp = self.frontCashierController;
        CJPayLogInfo(@"%@", tmp);
        CJ_CALL_BLOCK(completion, type, response);
        tmp = nil;
    }];
}

- (void)back {
    [super back];
    [self p_trackerWithEventName:@"wallet_change_cashier_click"
                          params:@{@"bank_name": CJString(self.defaultConfig.title)}];
    CJ_CALL_BLOCK(self.completion, nil, CJPayOrderStatusCancel);
}

- (void)rechargeRecordClick {
    [self p_trackerWithEventName:@"wallet_recharge_record_click" params:@{@"button_name" : @"充值记录"}];

    NSString *rechargeRecordUrl = [NSString stringWithFormat:@"%@/cashdesk_withdraw/yue_recordList",[CJPayBaseRequest bdpayH5DeskServerHostString]];
    
    NSDictionary *params = @{
        @"app_id": CJString(self.orderResponse.merchant.appId),
        @"merchant_id": CJString(self.orderResponse.merchant.merchantId),
        @"trade_type": @"DEPOSIT",
        @"title": CJPayLocalizedStr(@"充值记录"),
    };
    
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self toUrl:rechargeRecordUrl params:params];
}

#pragma mark - Getter
- (NSMutableArray *)notSufficientIds {
    if (!_notSufficientIds) {
        _notSufficientIds = [NSMutableArray new];
    }
    return _notSufficientIds;
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self];
}

- (void)stopLoading {
    [[CJPayLoadingManager defaultService] stopLoading];
}

- (BOOL)cjAllowTransition {
    return YES;
}

#pragma mark - keyboard delegate

- (void)keyboardWillHide {
    if (!self.mainView.amountView.amountField.textField.isFirstResponder) {
        return;
    }
    [self p_trackerWithEventName:@"wallet_recharge_keyboard_hide" params:@{}];
    self.staticConfirmBtn.hidden = YES;

    self.confirmBtn.frame = CGRectMake(CJ_SCREEN_WIDTH - 16 - kKeyBoardConfirmBtnWidth, CJ_SCREEN_HEIGHT- 56 - 81, kKeyBoardConfirmBtnWidth, 56);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.staticConfirmBtn.hidden = NO;
    });
}

- (void)keyboardDidHide {
    if (self.confirmBtn.superview != self.view) {
        [self.view addSubview:self.confirmBtn];
    }
}

- (void)keyboardWillShow:(NSNotification *)noti {
    if (!self.mainView.amountView.amountField.textField.isFirstResponder) {
        return;
    }
    self.staticConfirmBtn.hidden = YES;
    [self p_trackerWithEventName:@"wallet_recharge_keyboard_show" params:@{}];
    
    CJPayDouyinKeyboard *keyboardView = self.mainView.amountView.amountField.safeKeyBoard;
    
    @CJWeakify(self)
    keyboardView.dismissBlock = ^{
        @CJStrongify(self)
        if (self.confirmBtn.superview != self.view) {
            [self.view addSubview:self.confirmBtn];
        }
    };
    
    UIWindow *keyboardWindow = keyboardView.window;
    if (keyboardWindow) {
        [self.confirmBtn setFrame:CGRectMake(CJ_SCREEN_WIDTH - kKeyBoardConfirmBtnRightMargin - kKeyBoardConfirmBtnWidth,
                                             CJ_SCREEN_HEIGHT- kKeyBoardConfirmBtnHeight - kKeyBoardConfirmBtnBottomMargin,
                                             kKeyBoardConfirmBtnWidth,
                                             kKeyBoardConfirmBtnHeight)];
        [keyboardWindow addSubview:self.confirmBtn];
    }
}

- (void)appDidInBackground {
    [self.view endEditing:YES];
}

- (void)appWillEnterForeground {
    [self.mainView.amountView becomeFirstResponder];
}

@end
