//
//  BDPayWithDrawBalanceViewController.m
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import "CJPayWithDrawBalanceViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayWithDrawMainView.h"
#import "CJPayFrontCashierManager.h"
#import "CJPayMemBankInfoModel.h"
#import "CJPayFrontCashierCreateOrderRequest.h"
#import "CJPayWebViewUtil.h"
#import "CJPayWithDrawResultViewController.h"
#import "CJPayWithDrawNoticeView.h"
#import "CJPayWebviewStyle.h"
#import <UIKit/UIKit.h>
#import "CJBizWebDelegate.h"
#import "CJPayBizWebViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayBizWebViewController+Biz.h"
#import "CJPayCommonSafeHeader.h"
#import "CJPayCustomSettings.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayBalanceWithdrawController.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayAlertUtil.h"
#import "CJPayMetaSecManager.h"
#import "CJPayDouyinKeyboard.h"
#import "CJPayBindCardManager.h"
#import "CJPayDeskUtil.h"
#import "CJPayBalancePromotionModel.h"
#import "CJPayBalanceVerifyManager.h"

@interface CJPayWithDrawBalanceViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) CJPayWithDrawMainView *mainView;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayWithDrawNoticeView *noticeView;
@property (nonatomic, strong) CJPayButton *withdrawRecordButton;
@property (nonatomic, strong) UILabel *serviceTipsLabel;
@property (nonatomic, strong) CJPayStyleTimerButton *confirmBtn;
@property (nonatomic, strong) CJPayStyleTimerButton *staticConfirmBtn;

@property (nonatomic, strong) CJPayBDCreateOrderResponse *orderResponse;
@property (nonatomic, copy) void(^completion)(CJPayBDOrderResultResponse* response, CJPayOrderStatus orderStatus);
@property (nonatomic, copy) NSDictionary *bizParams;
@property (nonatomic, copy) NSString *bizUrl;
@property (nonatomic, strong) CJPayDefaultChannelShowConfig *defaultConfig;
@property (nonatomic, strong) CJPayWithDrawNoticeViewModel *noticeViewModel;
@property (nonatomic, assign) NSTimeInterval willAppearTime;
@property (nonatomic, assign) NSInteger completeAlertShowCount;
@property (nonatomic, copy) NSString *memBizOrderNo;
@property (nonatomic, copy) NSString *larkUnionStr;

@end

@implementation CJPayWithDrawBalanceViewController

- (instancetype)initWithBizParams:(NSDictionary *)bizParams
                           bizurl:(NSString *)bizUrl
                         response:(CJPayBDCreateOrderResponse *)response
                  completionBlock:(nonnull void (^)(CJPayBDOrderResultResponse * _Nonnull, CJPayOrderStatus))completionBlock {
    self = [super init];
    if (self) {
        _bizParams = bizParams;
        _bizUrl = bizUrl;
        _orderResponse = response;
        _completion = [completionBlock copy];
        _completeAlertShowCount = 0;
        _larkUnionStr = [bizParams cj_stringValueForKey:@"lark_union_gateway_strategy"];
    }
    return self;
}

- (void)dealloc
{
    CJPayLogInfo(@"dealloc");
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNavTitle:CJPayLocalizedStr(@"零钱提现")];
    [self setupViews];
    [self updateOrderResponse];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(silentRefreshAndCheckVoucher:) name:CJPayBindCardSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(silentRefreshAndCheckVoucher:) name:CJPayH5BindCardSuccessNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(silentRefresh) name:BDPaySignSuccessAndConfirmFailNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_bindCardSuccessPreClose) name:CJPayBindCardSuccessPreCloseNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidInBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification object:nil];
    // 显示账户安全险
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.view addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.centerX.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-16-CJ_TabBarSafeBottomMargin);
            make.height.mas_equalTo(18);
        });
        self.serviceTipsLabel.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.willAppearTime = CFAbsoluteTimeGetCurrent();
    
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

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.confirmBtn.superview != self.view) {
        [self.view addSubview:self.confirmBtn];
    }
    if ([self.mainView.amountView.withDrawAmountField.textField isFirstResponder]) {
        [self.mainView.amountView resignFirstResponder];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    [self p_trackerWithEventName:@"wallet_tixian_imp" params:@{@"loading_time": @(currentTime - self.willAppearTime),
                                                               @"is_paytype_notice_show": [self.noticeViewModel getViewHeight] > 0 ? @"1" : @"0",
                                                               @"is_tixian_record_show": @"0"
    }];
}

- (void)silentRefreshAndCheckVoucher:(NSNotification *)noti {
    NSDictionary *dic = noti.object;
    if (![dic isKindOfClass:NSDictionary.class]) {
        [self p_silentRefreshWithCheckVoucher:NO];
        return;
    }
    
    self.memBizOrderNo = [dic cj_stringValueForKey:@"bind_order_no"];
    if ([dic cj_integerValueForKey:@"bind_scene"] == CJPayLynxBindCardBizScenceBalanceWithdraw) {
        [self p_silentRefreshWithCheckVoucher:YES];
        return;
    }
    [self p_silentRefreshWithCheckVoucher:NO];
}

- (void)silentRefresh {
    [self p_silentRefreshWithCheckVoucher:NO];
}

- (void)p_silentRefreshWithCheckVoucher:(BOOL)isNeedCheckVoucher {
    @CJStartLoading(self.mainView.methodView)
    NSDictionary *bizConParams = [self p_buildBizParams:self.bizParams isNeedCheckVoucher:isNeedCheckVoucher];
    [CJPayFrontCashierCreateOrderRequest startRequestWithAppid:[bizConParams cj_stringValueForKey:@"app_id"] merchantId:[bizConParams cj_stringValueForKey:@"merchant_id"] bizContentParams:@{@"params": bizConParams?:@{}} completion:^(NSError * _Nullable error, CJPayBDCreateOrderResponse * _Nullable response) {
        @CJStopLoading(self.mainView.methodView)
        BOOL isAppear = NO;
        if (self.navigationController.viewControllers.lastObject == self && [UIViewController cj_foundTopViewControllerFrom:self] == self) {
            isAppear = YES;
        }
        if (!response.isSuccess) {
            return;
        }
        
        self.orderResponse = response;
        if (isAppear) {
            [self updateOrderResponse];
        } else {
            [self p_updateSelectConfig];
        }
        
        //绑卡成功后查询发券结果
        if (!isNeedCheckVoucher) {
            return;
        }
        NSString *toastMsg = self.orderResponse.balancePromotionModel.hasBindCardLottery ? @"绑卡成功\n券已发放" : @"绑卡成功";
        [CJPayToast toastImage:@"cj_balance_success_icon" title:toastMsg duration:2 inWindow:self.cj_window];
        [self p_trackerWithEventName:@"wallet_tixian_toast_imp" params:@{
            @"toast_name": @"提现绑卡"
        }];
    }];
}

- (void)p_bindCardSuccessPreClose {
    [self.navigationController popToViewController:self animated:NO];
}

- (void)p_updateSelectConfig {
    for (CJPayQuickPayCardModel *card in self.orderResponse.payTypeInfo.quickPay.cards) {
        card.comeFromSceneType = CJPayComeFromSceneTypeBalanceWithdraw;
        CJPayDefaultChannelShowConfig *showConfig = [card buildShowConfig].firstObject;
        if ([showConfig.cjIdentify isEqualToString:self.defaultConfig.cjIdentify]) {
            self.defaultConfig = showConfig;
        }
    }
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

- (void)updateOrderResponse {
    CJPayQuickPayCardModel *card = self.orderResponse.payTypeInfo.quickPay.cards.firstObject;
    card.comeFromSceneType = CJPayComeFromSceneTypeBalanceWithdraw;
    self.mainView.orderResponse = self.orderResponse;
    CJPayDefaultChannelShowConfig *config = [card buildShowConfig].firstObject;
    if (config.enable) {
        self.defaultConfig = config;
    } else {
        self.defaultConfig = nil;
    }
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

- (CJPayWithDrawNoticeView *)noticeView {
    if (!_noticeView) {
        _noticeView = [CJPayWithDrawNoticeView new];
        _noticeViewModel = [CJPayWithDrawNoticeViewModel modelWith:self.orderResponse];
        [_noticeView bindViewModel:_noticeViewModel];
    }
    return _noticeView;
}

- (CJPayWithDrawMainView *)mainView {
    if (!_mainView) {
        _mainView = [CJPayWithDrawMainView new];
        _mainView.defaultDiscount = self.orderResponse.balancePromotionModel.promotionDescription;
        [self p_trackPromotionWithEvent:@"wallet_tixian_marketing_imp" param:nil];
        
        [_mainView.amountView renderBalanceWithUserInfo:self.orderResponse.userInfo];
        @CJWeakify(self)
        _mainView.chooseCardBlock = ^{
            @CJStrongify(self)
            [self p_trackerWithEventName:@"wallet_tixian_cardselect" params:@{}];
            [self gotoChooseCard];
        };
        _mainView.amountView.amountDidChangeBlock = ^{
            @CJStrongify(self)
            NSString *amount = [self.mainView.amountView getAmountValue];
            if ([amount doubleValue] > ([self.orderResponse.userInfo.balanceAmount doubleValue]/100)) {
                [self.mainView.amountView showLimitLabel:YES];
            } else {
                [self.mainView.amountView showLimitLabel:NO];
            }
            [self p_updateConfirmBtnState];
        };
        
        _mainView.amountView.withdrawTextFieldTapGestureClickBlock = ^{
            @CJStrongify(self)
            [self p_trackerWithEventName:@"wallet_tixian_inputmoney" params:@{}];
        };
        
        _mainView.amountView.amountWithdrawAllBlock = ^{
            @CJStrongify(self)
            [self p_trackerWithEventName:@"wallet_tixian_allmoney" params:@{}];
        };
    }
    return _mainView;
}

- (CJPayButton *)withdrawRecordButton {
    if (!_withdrawRecordButton) {
        _withdrawRecordButton = [CJPayButton new];
        _withdrawRecordButton.titleLabel.textAlignment = NSTextAlignmentRight;
        _withdrawRecordButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [_withdrawRecordButton addTarget:self action:@selector(withDrawRecordClick) forControlEvents:UIControlEventTouchUpInside];
        [_withdrawRecordButton setTitleColor:self.cjLocalTheme.withdrawTitleTextColor ?: [UIColor cj_161823ff] forState:UIControlStateNormal];
        [_withdrawRecordButton setTitle:CJPayLocalizedStr(@"提现记录") forState:UIControlStateNormal];
        _withdrawRecordButton.titleLabel.font = [UIFont cj_fontOfSize:15];
    }
    return _withdrawRecordButton;
}

- (UILabel *)serviceTipsLabel {
    if (!_serviceTipsLabel) {
        _serviceTipsLabel = [UILabel new];
        _serviceTipsLabel.text = CJPayLocalizedStr(@"本服务由合众易宝提供");
        _serviceTipsLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _serviceTipsLabel;
}


- (CJPayStyleTimerButton *)staticConfirmBtn {
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

#pragma mark - private methods
- (CJPayStyleTimerButton *)p_genConfirmBtn {
    CJPayStyleTimerButton *confirmBtn = [[CJPayStyleTimerButton alloc] init];
    [confirmBtn setTitle:@"提现" forState:UIControlStateNormal];
    [confirmBtn.titleLabel setFont:[UIFont cj_boldFontOfSize:16]];
    confirmBtn.disabledBackgroundColorStart = nil;
    
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
    confirmBtn.cornerRadius = 8;
    return confirmBtn;
}

//更新提现按钮状态
- (void)p_updateConfirmBtnState {
    // 余额为0
    if ([self.orderResponse.userInfo.balanceAmount doubleValue] == 0) {
        self.staticConfirmBtn.enabled = NO;
        self.confirmBtn.enabled = NO;
    } else {
        NSString *amount = [self.mainView.amountView getAmountValue];
        BOOL overBalanceAmount = [amount doubleValue] > ([self.orderResponse.userInfo.balanceAmount doubleValue]/100);
        if (Check_ValidString(amount) && amount.doubleValue * 100 >= 1 && !overBalanceAmount) {
            self.staticConfirmBtn.enabled = YES;
            self.confirmBtn.enabled = YES;
        } else {
            self.staticConfirmBtn.enabled = NO;
            self.confirmBtn.enabled = NO;
        }
    }
}

- (void)setupViews {
    [self p_adapterTheme];

    [self.navigationBar addSubview:self.withdrawRecordButton];
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.serviceTipsLabel];
    [self.view addSubview:self.staticConfirmBtn];
    [self.view addSubview:self.confirmBtn];
    self.confirmBtn.enabled = NO;
    self.staticConfirmBtn.enabled = NO;


    [self.scrollView addSubview:self.scrollContentView];
    [self.scrollContentView addSubview:self.noticeView];
    [self.scrollContentView addSubview:self.mainView];
    
    CJPayMasMaker(self.scrollView, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view).offset([self navigationHeight]);
    });
    
    CJPayMasMaker(self.scrollContentView, {
        make.edges.equalTo(self.scrollView);
        make.size.equalTo(self.scrollView);
    });
    
    CJPayMasMaker(self.noticeView, {
        make.left.equalTo(self.scrollContentView).offset(0);
        make.right.equalTo(self.scrollContentView).offset(0);
        make.top.equalTo(self.scrollContentView).offset(0);
        make.height.equalTo(@([self.noticeViewModel getViewHeight]));
    });
    
    CJPayMasMaker(self.mainView, {
        make.left.equalTo(self.scrollContentView).offset(0);
        make.right.equalTo(self.scrollContentView).offset(0);
        make.top.equalTo(self.noticeView.mas_bottom);
    });
    
    CJPayMasMaker(self.serviceTipsLabel, {
        make.bottom.equalTo(self.scrollContentView).offset(-CJ_TabBarSafeBottomMargin - 16);
        make.centerX.equalTo(self.scrollContentView);
    });

    CJPayMasMaker(self.withdrawRecordButton, {
        make.right.equalTo(self.navigationBar).offset(-16);
        if(CJ_Pad) {
            make.centerY.equalTo(self.navigationBar);
        } else {
            make.centerY.equalTo(self.navigationBar.mas_bottom).offset(-22);
        }
        make.left.greaterThanOrEqualTo(self.navigationBar.titleLabel.mas_right).offset(6);
    });
    self.confirmBtn.enabled = NO;
    [self.mainView adapterTheme];
}

-(void)p_adapterTheme {
    CJPayLocalThemeStyle *localTheme = self.cjLocalTheme ?: [CJPayLocalThemeStyle defaultThemeStyle];
    if ([self cj_currentThemeMode] != CJPayThemeModeTypeDark) {
        [self.navigationBar setBackgroundColor:[UIColor cj_f8f8f8ff]];
    }
    self.scrollContentView.backgroundColor = localTheme.withdrawBackgroundColorV2;
    
    self.noticeView.backgroundColor = localTheme.withDrawNoticeViewBackgroundColor;
    self.noticeView.showResponseLabel.textColor = localTheme.withDrawNoticeViewTextColor;
    [self.withdrawRecordButton cj_setBtnTitleColor:localTheme.withdrawTitleTextColor];
    self.serviceTipsLabel.textColor = localTheme.withdrawServiceTextColor;
}

- (void)tapContent {
    [self.view endEditing:YES];
}

- (void)setDefaultConfig:(CJPayDefaultChannelShowConfig * _Nullable)defaultConfig {
    _defaultConfig = defaultConfig;
    self.mainView.selectConfig = defaultConfig;
    [self.scrollContentView setNeedsLayout];
    [self.scrollContentView layoutIfNeeded];
    [self p_updateConfirmBtnState];
}

- (void)gotoChooseCard {
    if (self.defaultConfig) {
        BDChooseCardCommonModel *model = [BDChooseCardCommonModel new];
        model.notSufficientFundsIDs = @[];
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
                [self p_trackerWithEventName:@"wallet_tixian_cardselect_change" params:@{}];
                if (!model.isNewCard) {
                    self.defaultConfig = model.config;
                }
            }
        };
        model.bindCardBlock = ^(BDChooseCardDismissLoadingBlock _Nonnull dismissLoadingBlock) {
            @CJStrongify(self)
            [self p_bindCardFromCardList:dismissLoadingBlock];
        };
        model.trackerParams = [self p_baseTrackerParams];
        @CJStartLoading(self.mainView.methodView)
        model.comeFromSceneType = CJPayComeFromSceneTypeBalanceWithdraw;
        model.bizParams = [self p_buildBizParams:model.bizParams isNeedCheckVoucher:NO];
        [[CJPayFrontCashierManager shared] chooseCardWithCommonModel:model];
    } else {
        [self p_trackPromotionWithEvent:@"wallet_tixian_marketing_click" param:nil];
        [self p_trackerWithEventName:@"wallet_tixian_cardselect_addbcard" params:@{@"from": @"收银台一级页"}];
        @CJWeakify(self)
        @CJStartLoading(self.mainView.methodView)
        [self p_bindCardFromCardList:^{
            @CJStrongify(self)
            @CJStopLoading(self.mainView.methodView)
        }];
    }
}

- (void)p_bindCardFromCardList:(BDChooseCardDismissLoadingBlock)dismissLoadingBlock {
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

//组装请求接口service
- (NSDictionary *)p_buildBizParams:(NSDictionary *)bizParams isNeedCheckVoucher:(BOOL)isNeedCheckVoucher {
    NSMutableDictionary *bizConParams = [NSMutableDictionary dictionaryWithDictionary:bizParams];
    [bizConParams cj_setObject:@"prewithdraw.balance.confirm" forKey:@"service"];
    if (isNeedCheckVoucher) {
        [bizConParams cj_setObject:self.memBizOrderNo forKey:@"independent_bind_order_no"];
    }
    return bizConParams;
}

- (void)p_bindCard:(void(^)(void))finishBlock {
    CJPayBindCardSharedDataModel *model = [CJPayBindCardSharedDataModel new];
    model.cardBindSource = CJPayCardBindSourceTypeBalanceWithdraw;
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

- (void)p_confirmClick {
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeConfirmWithDraw];
    [self p_trackerWithEventName:@"wallet_tixian_confirm_click" params:@{@"button_name" : @"提现"}];
    //是否展示“完善用户实名信息”弹窗：notShowCompleteInfoAlert控制单次订单只展示一次弹窗，userInfo.needCompleteUserInfo由后端下发作为频次控制
    if (self.completeAlertShowCount < self.orderResponse.userInfo.completeOrderTimes && self.orderResponse.userInfo.needCompleteUserInfo) {
        self.completeAlertShowCount++;
        [self p_showCompleteUserInfoAlertViewWithViewController];
        return;
    }
    
    [self.view endEditing:YES];
    if (!self.defaultConfig || (self.defaultConfig && [self.defaultConfig.status isEqualToString:@"0"])) {
        [self p_trackerWithEventName:@"wallet_tixian_cardselect_addbcard" params:@{
            @"from": @"收银台一级页确认按钮"
        }];

        if ([self p_isHitBindCardTest]) {
            [self p_confirmPayWithBindCardAndPay:YES];
            return;
        }
        @CJWeakify(self)
        @CJStartLoading(self.confirmBtn)
        [self p_bindCard:^{
            @CJStrongify(self)
            @CJStopLoading(self.confirmBtn)
        }];
        return;
    }

    [self p_confirmPayWithBindCardAndPay:NO];
    [self p_trackerWithEventName:@"wallet_tixian_password_verify_show"
                          params:@{}];
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
    context.gotoCardListBlock = ^{
        @CJStrongify(self)
        [self gotoChooseCard];
    };
    context.homePageVC = self;
    context.extCallback = ^(CJPayHomeVCEvent eventType, id  _Nonnull value) {
        @CJStrongify(self)
        [self p_trackerWithEventName:@"wallet_pv_limit_toast_imp" params:@{@"type": @"提现"}];
        NSString *str = [NSString stringWithFormat:CJPayLocalizedStr(@"提现高峰系统拥挤，请%ds后再试"), [value intValue]];
        [CJToast toastText:str inWindow:weak_self.cj_window];
        [self.navigationController popToViewController:self animated:YES];
        if (eventType == CJPayHomeVCEventFreezeConfirmBtn) {
            int delayTime = [value intValue];
            [self.confirmBtn startTimer:delayTime];
        }
    };
    NSDecimalNumber *tradeNumber = [NSDecimalNumber decimalNumberWithString:[self.mainView.amountView getAmountValue]];
    NSString *tradeAmount = [[tradeNumber decimalNumberByMultiplyingBy:[NSDecimalNumber decimalNumberWithString:@"100"]] stringValue];
    context.confirmRequestParams = @{ @"pre_params": @{@"total_amount": CJString(tradeAmount), @"currency":@"CNY"}};
    NSTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [self p_startWithdrawWithContext:context
                    isBindCardAndPay:isBindCardAndPay
                          completion:^(CJPayManagerResultType type, CJPayBDOrderResultResponse * _Nullable resultResponse) {
        @CJStrongify(self)
        if (type == CJPayManagerResultCancel) {
            CJ_CALL_BLOCK(self.completion, resultResponse, CJPayOrderStatusNull);
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self p_trackerWithEventName:@"wallet_tixian_confirm" params:@{
                @"loading_time": @(CFAbsoluteTimeGetCurrent() - startTime),
                @"tixian_result": [resultResponse isSuccess] ? @"1" : @"0",
                @"error_code": CJString(resultResponse.tradeInfo.tradeStatusString),
                @"error_message": CJString(resultResponse.tradeInfo.tradeDescMessage)
            }];
            CJPayWithDrawResultViewController *resultVC = [[CJPayWithDrawResultViewController alloc] init];
            
            resultVC.merchant = self.orderResponse.merchant;
            resultVC.memberBizOrderNo = self.memBizOrderNo;
            resultVC.tradeNo = self.orderResponse.tradeInfo.tradeNo;
            resultVC.response = resultResponse;
            resultVC.processInfo = self.orderResponse.processInfo;
            resultVC.preOrderTrackInfo = @{@"is_bankcard" : CJString(self.orderResponse.preTradeInfoWrapper.trackInfo.bankCardStatus)};
            CJPayCustomSettings *settings = [self.orderResponse customSetting];
            resultVC.withdrawResultPageDescDict = settings.withdrawResultPageDescDict;
            @CJWeakify(resultVC)
            resultVC.cjBackBlock = ^{
                @CJStrongify(resultVC)
                if ([resultVC.navigationController isKindOfClass:CJPayNavigationController.class]) {
                    [resultVC.navigationController dismissViewControllerAnimated:YES completion:^{
                        CJ_CALL_BLOCK(self.completion, resultResponse, CJPayOrderStatusNull);
                    }];
                } else {
                    CJ_CALL_BLOCK(self.completion, resultResponse, CJPayOrderStatusNull);
                }
            };
            if ([self.navigationController isKindOfClass:CJPayNavigationController.class]) {
                CJPayNavigationController *cjpayNavi = (CJPayNavigationController *)self.navigationController;
                [cjpayNavi pushViewController:resultVC animated:YES];
            } else {
                [self.navigationController setViewControllers:@[resultVC] animated:YES];
            }
        }
    }];
}

- (BOOL)p_isHitBindCardTest {
    NSString *chargeWithdrawStyle = self.orderResponse.userInfo.chargeWithdrawStyle;
    return Check_ValidString(chargeWithdrawStyle) && ![chargeWithdrawStyle isEqualToString:@"v1"];
}

// 展示“需要完善实名信息”弹窗
- (void)p_showCompleteUserInfoAlertViewWithViewController {
    @CJWeakify(self);
    NSString *alertTitle = CJString(self.orderResponse.userInfo.completeHintTitle);
    NSString *rightButtonText = Check_ValidString(self.orderResponse.userInfo.completeRightText) ? self.orderResponse.userInfo.completeRightText : CJPayLocalizedStr(@"去完善");
    [CJPayAlertUtil customDoubleAlertWithTitle:alertTitle content:nil leftButtonDesc:CJPayLocalizedStr(@"取消") rightButtonDesc:rightButtonText leftActionBlock:^{
        @CJStrongify(self)
        [self p_trackerWithEventName:@"wallet_perfect_userinfo_pop_click" params:@{
                    @"button_name": CJString(@"取消")
        }];
    } rightActioBlock:^{
        @CJStrongify(self)
        [self p_trackerWithEventName:@"wallet_perfect_userinfo_pop_click" params:@{
                    @"button_name": CJString(@"去完善")
        }];
        [self p_gotoCompletePage];
    } useVC:self];
    
    [self p_trackerWithEventName:@"wallet_perfect_userinfo_pop_show" params:@{}];
}

- (void)p_gotoCompletePage {
    
    NSString *completeType = self.orderResponse.userInfo.completeType;
    if ([completeType isEqualToString:@"lynx"]) {
        NSString *completeLynxUrl = self.orderResponse.userInfo.completeLynxUrl;
        CJPayLogAssert(Check_ValidString(completeLynxUrl), @"complete_lynx_url为空");
        
        [CJPayDeskUtil openLynxPageBySchema:completeLynxUrl completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
        }];
        return;
    }
    
    if ([completeType isEqualToString:@"h5"]) {
        NSString *completeUrl = self.orderResponse.userInfo.completeUrl;
        CJPayLogAssert(Check_ValidString(completeUrl), @"complete_url为空");
        
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self toUrl:completeUrl];
        return;
    }
    
    CJPayLogAssert(NO, @"complete_type类型错误");
}

- (NSString *)getCompleteUserInfoUrl {
    return [NSString stringWithFormat:
        @"%@/usercenter/member?app_id=%@&merchant_id=%@&source=sdk",
            CJString([CJPayBaseRequest bdpayH5DeskServerHostString]),
            CJString(self.orderResponse.merchant.appId),
            CJString(self.orderResponse.merchant.merchantId)
    ];
}

- (void)p_startWithdrawWithContext:(CJPayFrontCashierContext *)context isBindCardAndPay:(BOOL)isBindCardAndPay completion:(void (^)(CJPayManagerResultType, CJPayBDOrderResultResponse * _Nullable))completion {
    __block CJPayBalanceWithdrawController *withdrawController = [CJPayBalanceWithdrawController new];
    withdrawController.isBindCardAndPay = isBindCardAndPay;
    [withdrawController startWithdrawWithContext:context completion:^(CJPayManagerResultType type, CJPayBDOrderResultResponse * _Nullable response) {
        withdrawController = nil;
        CJ_CALL_BLOCK(completion, type, response);
    }];
}

//提现记录
- (void)withDrawRecordClick {
    
    [self p_trackerWithEventName:@"wallet_tixian_balatixian_record_click" params:@{}];
    
    NSString *withdrawRecordUrl = [NSString stringWithFormat:@"%@/cashdesk_withdraw/yue_recordList",[CJPayBaseRequest bdpayH5DeskServerHostString]];
    NSMutableDictionary *params = [@{
        @"app_id": CJString(self.orderResponse.merchant.appId),
        @"merchant_id": CJString(self.orderResponse.merchant.merchantId),
        @"title" : @"提现记录"
    } mutableCopy];
    
    if (Check_ValidString(self.larkUnionStr)) {
        [params cj_setObject:CJString(self.larkUnionStr) forKey:@"lark_union_gateway_strategy"];
    }
    [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self toUrl:withdrawRecordUrl params:[params copy]];
}

- (void)back {
    [super back];
    CJ_CALL_BLOCK(self.completion, nil, CJPayOrderStatusCancel);
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *baseParams = [[self p_baseTrackerParams] mutableCopy];
    
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

- (NSDictionary *)p_baseTrackerParams {
    NSString *tixianAmount = CJString([self.mainView.amountView getAmountValue]);
    tixianAmount = (tixianAmount.length == 0) ? @"0" : tixianAmount;
    NSInteger Amount = [tixianAmount intValue];
    Amount *= 100; // 单位 元 => 分
    tixianAmount = [NSString stringWithFormat:@"%ld", Amount];
    
    NSDictionary *bindCardTrackerBaseParams = [[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams];
    return @{
        @"app_id": CJString(self.orderResponse.merchant.appId),
        @"merchant_id": CJString(self.orderResponse.merchant.merchantId),
        @"is_chaselight": @"1",
        @"twoelements_verify_status": @"0",
        @"type": @"可变金额",
        @"balance_amount": CJString(self.orderResponse.userInfo.balanceAmount),
        @"tixian_amount": tixianAmount,
        @"account_type": @"银行卡",
        @"version": @"普通",
        @"caijing_source": @"提现收银台",
        @"is_bankcard": CJString(self.orderResponse.preTradeInfoWrapper.trackInfo.bankCardStatus),
        @"needidentify" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"needidentify"]),
        @"haspass" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"haspass"])
    };
}

#pragma mark - CJPayBaseLoadingProtocol
- (void)startLoading {
    [self.view endEditing:YES];
    [CJPayLoadingManager.defaultService startLoading:CJPayLoadingTypeDouyinLoading vc:self];
}

- (void)stopLoading {
    [CJPayLoadingManager.defaultService stopLoading];
}

- (BOOL)cjAllowTransition {
    return YES;
}

#pragma mark - keyboard delegate

- (void)keyboardWillHide {
    if (!self.mainView.amountView.withDrawAmountField.textField.isFirstResponder) {
        return;
    }
    self.staticConfirmBtn.hidden = YES;
    [self p_trackerWithEventName:@"wallet_tixian_keyboard_hide" params:@{}];

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
    if (!self.mainView.amountView.withDrawAmountField.textField.isFirstResponder) {
        return;
    }
    [self p_trackerWithEventName:@"wallet_tixian_keyboard_show" params:@{}];
    
    CJPayDouyinKeyboard *keyboardView = self.mainView.amountView.withDrawAmountField.safeKeyBoard;
    
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
    self.staticConfirmBtn.hidden = YES;
}

- (void)appDidInBackground {
    [self.view endEditing:YES];
}

- (void)appWillEnterForeground {
    [self.mainView.amountView becomeFirstResponder];
}

@end

