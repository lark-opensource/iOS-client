//
// Created by 张海阳 on 2020/3/11.
//

#import <BDWebImage/BDWebImage.h>
#import "CJPayRechargeResultViewController.h"
#import "CJPayRechargeResultMainView.h"
#import "CJPayRechargeResultPayInfoView.h"
#import "CJPayLoopView.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBDTradeInfo.h"
#import "CJPayDiscountBanner.h"
#import "CJPayHomeVCProtocol.h"
#import "CJPayLineUtil.h"
#import "CJPayStyleButton.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayPrivacyMethodUtil.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPayBalanceResultPromotionView.h"
#import "CJPayBannerResponse.h"
#import "CJPayQueryBannerRequest.h"
#import "CJPayBindCardManager.h"
#import "CJPayBDOrderResultResponse.h"

@interface CJPayRechargeResultViewController () <CJPayLoopViewDelegate>

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) UIImageView *bgImageView;

@property (nonatomic, strong) CJPayRechargeResultMainView *mainView;
@property (nonatomic, strong) CJPayRechargeResultPayInfoView *payInfoView;
@property (nonatomic, strong) CJPayLoopView *loopView;
@property (nonatomic, strong) CJPayBalanceResultPromotionView *promotionView;

@property (nonatomic, strong) CJPayButton *completeButton;
@property (nonatomic, strong) UILabel *serviceTipsLabel;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) CJPayBannerResponse *bannerResponse;

@end


@implementation CJPayRechargeResultViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        _isFirstAppear = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self p_setupUI];
    [self p_makeConstraints];
    [self p_updatePayInfo];
}

- (void)back {
    [super back];
    if (self.closeAction) {
        self.closeAction();
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!self.isFirstAppear) {
        return;
    }
    
    self.isFirstAppear = NO;
    [self p_queryBanner:5];
}

- (void)p_setupUI {
    [self.view addSubview:self.bgImageView];
    [self.view sendSubviewToBack:self.bgImageView];
    self.navigationBar.title = CJPayLocalizedStr(@"充值结果");
    [self.navigationBar setBackgroundColor:[UIColor clearColor]];
    
    self.scrollView = [UIScrollView new];
    self.scrollView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.serviceTipsLabel];

    self.contentView = [UIView new];
    [self.scrollView addSubview:self.contentView];

    [self.contentView addSubview:self.mainView];
    [self.contentView addSubview:self.payInfoView];
    
    [self.view addSubview:self.completeButton];
    
    self.serviceTipsLabel.textColor = [self cjLocalTheme].withdrawServiceTextColor;
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.contentView addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.centerX.width.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-16-CJ_TabBarSafeBottomMargin);
            make.height.mas_equalTo(18);
        });
        self.serviceTipsLabel.hidden = YES;
    }
}

- (void)p_makeConstraints {
    CJPayMasMaker(self.scrollView, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view).offset([self navigationHeight]);
    });
    
    CJPayMasMaker(self.contentView, {
        make.edges.equalTo(self.scrollView);
        make.size.equalTo(self.scrollView);
    });
    
    CJPayMasMaker(self.mainView, {
        make.leading.top.trailing.equalTo(self.mainView.superview);
        make.height.mas_equalTo(180);
    });
    
    CJPayMasMaker(self.payInfoView, {
        make.leading.trailing.equalTo(self.payInfoView.superview);
        make.top.equalTo(self.mainView.mas_bottom);
    });
    
    CJPayMasMaker(self.completeButton, {
        make.bottom.equalTo(self.view).offset(-72-CJ_TabBarSafeBottomMargin);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(160);
        make.height.mas_equalTo(42);
    });
    
    CJPayMasMaker(self.serviceTipsLabel, {
        make.bottom.equalTo(self.view).offset(-CJ_TabBarSafeBottomMargin - 16);
        make.centerX.equalTo(self.view);
    });
    
    CJPayMasMaker(self.bgImageView, {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(360);
    });
}

- (void)p_updatePayInfo {
    CJPayBDTradeInfo *tradeInfo = self.tradeInfo;
    NSMutableArray *payInfoViewDataSource = [NSMutableArray arrayWithArray:@[
        [self p_payInfoModel:^(CJPayInvestResultPayInfoViewRowData *data) {
            data.title = CJPayLocalizedStr(@"充值方式");
            NSString *bankName = CJString(tradeInfo.bankName);
            NSString *cardTailStr = CJString(tradeInfo.bankCodeMask);
            if (tradeInfo.bankCodeMask.length >= 4) {
                cardTailStr = [tradeInfo.bankCodeMask substringFromIndex:tradeInfo.bankCodeMask.length - 4];
            }
            data.detail = [NSString stringWithFormat:@"%@(%@)", bankName, cardTailStr];
            data.iconUrlStr = tradeInfo.iconUrl;
        }],
        [self p_payInfoModel:^(CJPayInvestResultPayInfoViewRowData *data) {
            if (tradeInfo.tradeStatus == CJPayOrderStatusSuccess) {
                data.title = CJPayLocalizedStr(@"到账时间");
            } else {
                data.title = CJPayLocalizedStr(@"充值时间");
            }
            data.detail = tradeInfo.formattedCreateTime;
        }]
    ]];
    [self.payInfoView reloadWith:payInfoViewDataSource];
}

- (void)p_queryBanner:(NSInteger)retryCount {
    @CJWeakify(self)
    [self p_queryBannerResponse:retryCount - 1 completion:^(NSError *error, CJPayBannerResponse *bannerResponse) {
        @CJStrongify(self)
        self.bannerResponse = bannerResponse;
        [self p_updatePromotionView];
        [self p_updateBanners];
    }];
}

- (void)p_queryBannerResponse:(NSInteger)retryCount completion:(void(^)(NSError *error, CJPayBannerResponse *bannerResponse))completionBlock {
    
    NSMutableDictionary *bizParam = @{
        @"is_last_one": [NSNumber numberWithBool:retryCount == 0],
        @"resource_no": @"PS202302071155541234530011",
        @"source": @"recharge_wallet_balance"
    }.mutableCopy;
    
    if (Check_ValidString(self.memberBizOrderNo)) {
        [bizParam cj_setObject:self.memberBizOrderNo forKey:@"bind_order_no"];
        [bizParam cj_setObject:@"PP20230207192844058200001" forKey:@"lottery_place_no"];
    }
    @CJWeakify(self)
    [CJPayQueryBannerRequest startWithAppId:self.merchant.appId merchantId:self.merchant.merchantId bizParam:bizParam completion:^(NSError * _Nullable error, CJPayBannerResponse * _Nonnull bannerResponse) {
        @CJStrongify(self)
        if (!self) {
            return;
        }
        if ((!bannerResponse.isSuccess || bannerResponse.bannerList.count < 1) && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self p_queryBanner:retryCount];
            });
            return;
        }
        
        CJ_CALL_BLOCK(completionBlock, error, bannerResponse);
    }];
}

- (CJPayInvestResultPayInfoViewRowData *)p_payInfoModel:(void (^)(CJPayInvestResultPayInfoViewRowData *))modelSettingBlock {
    CJPayInvestResultPayInfoViewRowData *rowData = [CJPayInvestResultPayInfoViewRowData new];
    CJ_CALL_BLOCK(modelSettingBlock, rowData);
    return rowData;
}

- (void)p_updatePromotionView {
    CJPayBannerResponse *bannerResponse = self.bannerResponse;
    if (!Check_ValidArray(bannerResponse.promotionModels)) {
        return;
    }
    [self p_trackerWithEventName:@"wallet_recharge_pay_finish_marketing_show" params:@{
        @"plan_no": CJString(bannerResponse.planNo),
        @"material_no": CJString(bannerResponse.materialNo),
        @"resource_no": CJString(bannerResponse.resourceNo),
        @"biztype": CJString(bannerResponse.bizType)
    }];
    [self.contentView addSubview:self.promotionView];
    [self.promotionView updateWithPromotionModel:[bannerResponse.promotionModels cj_objectAtIndex:0]];
    CJPayMasMaker(self.promotionView, {
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
        make.top.equalTo(self.payInfoView.mas_bottom).offset(8);
        make.height.mas_equalTo(101);
    });
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    NSDictionary *bindCardTrackerBaseParams = [[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams];
    NSMutableDictionary *baseParams = [@{
        @"app_id": CJString(self.merchant.appId),
        @"merchant_id": CJString(self.merchant.merchantId),
        @"is_chaselight": @"1",
        @"twoelements_verify_status": @"0",
        @"type": @"可变金额",
        @"balance_amount": CJString(self.response.userInfo.balanceAmount),
        @"tixian_amount": @(self.response.tradeInfo.tradeAmount).stringValue,
        @"account_type": @"银行卡",
        @"version": @"普通",
        @"is_bankcard" : CJString([self.preOrderTrackInfo cj_stringValueForKey:@"is_bankcard"]),
        @"needidentify" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"needidentify"]),
        @"haspass" : CJString([bindCardTrackerBaseParams cj_stringValueForKey:@"haspass"])
    } mutableCopy];
    
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

- (void)p_updateBanners {
    NSMutableArray <UIView *> *array = [NSMutableArray new];
    NSMutableArray <NSNumber *> *durArray = [NSMutableArray new];
    NSArray<CJPayDiscountBanner *> *banners = self.bannerResponse.bannerList;
    if (!Check_ValidArray(banners)) {
        return;
    }
    [self.contentView addSubview:self.loopView];
    MASConstraintMaker *make = [self.loopView cj_makeConstraint];
    make.left.equalTo(self.contentView).offset(16);
    make.right.equalTo(self.contentView).offset(-16);
    make.width.mas_equalTo(self.loopView.mas_height).multipliedBy(375 / 88);
    if (Check_ValidArray(self.bannerResponse.promotionModels)) {
        make.top.equalTo(self.promotionView.mas_bottom).offset(12);
    } else {
        make.top.equalTo(self.payInfoView.mas_bottom).offset(8);
    }
    [make install];

    [banners enumerateObjectsUsingBlock:^(CJPayDiscountBanner *obj, NSUInteger idx, BOOL *stop) {
        UIImageView *imageView = [UIImageView new];
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        imageView.layer.cornerRadius = 4;
        imageView.tag = idx;
        [imageView cj_setImageWithURL:[NSURL URLWithString:obj.picUrl]];
        imageView.userInteractionEnabled = YES;
        [imageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_bannerClick:)]];
        [array addObject:imageView];
        [durArray addObject:obj.stayTime ? @(obj.stayTime.doubleValue) : @(1)];
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.loopView updateSubViews:array durations:durArray startAutoScroll:YES];
    });
}

- (void)p_bannerClick:(UITapGestureRecognizer *)tapGestureRecognizer {
    CJ_DelayEnableView(tapGestureRecognizer.view);

    CJPayDiscountBanner *banner = [self.bannerResponse.bannerList cj_objectAtIndex:tapGestureRecognizer.view.tag];
    NSString *gotoType = banner.gotoType;
    NSString *urlString = banner.jumpUrl;

    if ([gotoType isEqualToString:@"0"]) {
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self toUrl:urlString];
    } else if ([gotoType isEqualToString:@"1"]) {
        [[CJPayWebViewUtil sharedUtil] openCJScheme:urlString fromVC:self useModal:YES];
    } else {
        CJPayLogAssert(NO, @"未指定banner跳转类型");
    }
}

- (CJPayRechargeResultMainView *)mainView {
    if (!_mainView) {
        _mainView = [CJPayRechargeResultMainView new];
        _mainView.backgroundColor = UIColor.clearColor;
        //金额格式化
        NSString *number = [CJPayCommonUtil getMoneyFormatStringFromDouble:((double)self.tradeInfo.tradeAmount / 100) formatString:nil];
         _mainView.fund = number;
        [_mainView updateWithTradeInfo:self.tradeInfo];
    }
    return _mainView;
}

- (CJPayRechargeResultPayInfoView *)payInfoView {
    if (!_payInfoView) {
        _payInfoView = [CJPayRechargeResultPayInfoView new];
        _payInfoView.backgroundColor = UIColor.clearColor;
    }
    return _payInfoView;
}

- (CJPayButton *)completeButton {
    if (!_completeButton) {
        _completeButton = [CJPayButton new];
        [_completeButton addTarget:self action:@selector(completeButtonClick) forControlEvents:UIControlEventTouchUpInside];
        [_completeButton setTitleColor:self.cjLocalTheme.rechargeLinkTextColor ?: [CJPayLocalThemeStyle defaultThemeStyle].rechargeLinkTextColor forState:UIControlStateNormal];
        [_completeButton setTitle:CJPayLocalizedStr(@"完成") forState:UIControlStateNormal];
        [_completeButton setBackgroundColor:self.cjLocalTheme.rechargeCompletionButtonBgColor];
        _completeButton.layer.cornerRadius = 4;
        _completeButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
    }
    return _completeButton;
}

- (UILabel *)serviceTipsLabel {
    if (!_serviceTipsLabel) {
        _serviceTipsLabel = [UILabel new];
        _serviceTipsLabel.text = CJPayLocalizedStr(@"本服务由合众易宝提供");
        _serviceTipsLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _serviceTipsLabel;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.hidden = YES;
    }
    return _safeGuardTipView;
}

- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] init];
        NSDictionary *rechargeWithdrawConfig = [CJPaySettingsManager shared].currentSettings.rechargeWithdrawConfig;
        NSString *themeString = @"";
        if ([self cj_currentThemeMode] == CJPayThemeModeTypeDark) {
            themeString = @"dark";
        } else {
            themeString = @"light";
        }
        NSString *resultPageBg = [[rechargeWithdrawConfig cj_dictionaryValueForKey:themeString] cj_stringValueForKey:@"result_page_bg"];
        if (Check_ValidString(resultPageBg)) {
            [_bgImageView cj_setImageWithURL:[NSURL URLWithString:resultPageBg]];
        }
    }
    return _bgImageView;
}

- (CJPayBalanceResultPromotionView *)promotionView {
    if (!_promotionView) {
        _promotionView = [CJPayBalanceResultPromotionView new];
    }
    return _promotionView;
}

- (CJPayLoopView *)loopView {
    if (!_loopView) {
        _loopView = [CJPayLoopView new];
        _loopView.delegate = self;
        _loopView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _loopView;
}

- (void)completeButtonClick {
    [self back];
}

#pragma mark - CJPayLoopViewDelegate
- (void)loopView:(CJPayLoopView *)loopView bannerAppearAtIndex:(NSUInteger)index atPage:(NSUInteger)pageNum {

}

- (BOOL)cjAllowTransition {
    return YES;
}

@end
