//
//  BDPayWithDrawResultViewController.m
//  CJPay
//
//  Created by 徐波 on 2020/4/3.
//

#import "CJPayWithDrawResultViewController.h"

#import "CJPayTracker.h"
#import "CJPayWithDrawResultHeaderView.h"
#import "CJPayWithDrawResultArrivingView.h"
#import "CJPayBaseRequest.h"
#import "CJPayWithDrawResultViewModel.h"
#import "CJPayWebViewUtil.h"
#import "CJPayMerchantInfo.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPayLoopView.h"
#import "UIViewController+CJTransition.h"
#import "CJPayFullPageBaseViewController+Biz.h"
#import <TTReachability/TTReachability.h>
#import "CJPayBDOrderResultRequest.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayQueryBannerRequest.h"
#import "CJPayBannerResponse.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayLoadingManager.h"
#import "CJPayBindCardManager.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPayBalanceResultPromotionView.h"

@interface CJPayWithDrawResultViewController () <CJPayLoopViewDelegate>
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;

@property (nonatomic, strong) CJPayWithDrawResultHeaderView *headerView;
@property (nonatomic, strong) CJPayWithDrawResultArrivingView *arrivingView;
@property (nonatomic, strong) CJPayWithDrawResultViewModel *viewModel;

@property (nonatomic, strong) CJPayLoopView *loopView;
@property (nonatomic, strong) CJPayIndicatorView *indicatorView;
@property (nonatomic, strong) CJPayButton *completeButton;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) UIImageView *bgImageView;

@property (nonatomic, strong) UIView *bottomBackView;

@property (nonatomic, copy) NSString *tradeStatusDescString;
@property (nonatomic, strong) CJPayBalanceResultPromotionView *promotionView;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, strong) CJPayBannerResponse *bannerResponse;

@property (nonatomic, assign) int orderNum;

@end

@implementation CJPayWithDrawResultViewController

+ (void)requestDataWithMerchantInfo:(CJPayMerchantInfo *)merchant
                            tradeNo:(NSString *)tradeNo
                        processInfo:(CJPayProcessInfo *)processInfo
                         completion:(void (^)(NSError *error, CJPayBDOrderResultResponse *response))completionBlock {
    [CJPayBDOrderResultRequest startWithAppId:CJString(merchant.appId) merchantId:CJString(merchant.merchantId) tradeNo:CJString(tradeNo) processInfo:processInfo completion:^(NSError * _Nonnull error, CJPayBDOrderResultResponse * _Nonnull response) {
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _isFirstAppear = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self p_setupUI];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.isFirstAppear) {
        if (!self.error && !self.response) {
            [self.navigationBar setBackgroundColor:[UIColor whiteColor]];
            [self showNoNetworkView];
        } else {
            [self.navigationBar setBackgroundColor:[UIColor clearColor]];
            [self updateDataWithError:self.error response:self.response];
            [self p_queryBanner:5];
        }
        self.isFirstAppear = NO;
    }
    
    [self.loopView startAutoScroll];
}

- (BOOL)cjAllowTransition {
    return YES;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.loopView stopAutoScroll];
}

- (void)setMerchant:(CJPayMerchantInfo *)merchant {
    _merchant = merchant;
    self.viewModel.appID = merchant.appId;
    self.viewModel.merchantID = merchant.merchantId;
}

- (void)updateDataWithError:(NSError *)error
                   response:(CJPayBDOrderResultResponse *)response {
    
    [self p_trackerWithEventName:@"wallet_tixian_progress_imp"
                          params:@{@"status": [self getStatusName:response.tradeInfo.tradeStatusString],
                                   @"reason_type": CJString(response.tradeInfo.failMsg)}];
    
    if (error != nil || !response) {
        [self.navigationBar setBackgroundColor:[UIColor whiteColor]];
        [self showNoNetworkView];
        return;
    }
    
    if (![response isSuccess]) {
        [self.navigationBar setBackgroundColor:[UIColor whiteColor]];
        [self showSystemBusyView];
        return;
    }
    
    [self.navigationBar setBackgroundColor:[UIColor clearColor]];

    [self hideNoNetworkView];
    [self hideSystemBusyView];
    
    self.headerView.hidden = NO;
    self.arrivingView.hidden = NO;
    
    self.viewModel.withdrawResultPageDescDict = self.withdrawResultPageDescDict;
    [self.viewModel updateWithResponse:response];
    self.viewModel.preOrderTrackInfo = self.preOrderTrackInfo;
}

- (void)reloadCurrentView
{
    [self hideNoNetworkView];
    [self hideSystemBusyView];
    [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeTopLoading vc:self];
    if (self.merchant && self.processInfo) {
        [CJPayWithDrawResultViewController requestDataWithMerchantInfo:self.merchant
                                                               tradeNo:self.tradeNo
                                                           processInfo:self.processInfo
                                                            completion:^(NSError *error, CJPayBDOrderResultResponse *resultResponse) {
            [[CJPayLoadingManager defaultService] stopLoading];
            [self updateDataWithError:error response:resultResponse];
        }];
    }
}

- (void)back {
    [super back];
    if (self.closeAction) {
        self.closeAction();
    }
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
        @"resource_no": @"PS202103122118021971343009",
        @"source": @"withdraw_wallet_balance"
    }.mutableCopy;
    
    if (Check_ValidString(self.memberBizOrderNo)) {
        [bizParam cj_setObject:self.memberBizOrderNo forKey:@"bind_order_no"];
        [bizParam cj_setObject:@"PP20230207192844058200001" forKey:@"lottery_place_no"];
    }
    @CJWeakify(self)
    [CJPayQueryBannerRequest startWithAppId:self.merchant.appId merchantId:self.merchant.merchantId bizParam:bizParam completion:^(NSError * _Nullable error, CJPayBannerResponse * _Nonnull bannerResponse) {
        
        if (!weak_self) {
            return;
        } else if ((!bannerResponse.isSuccess || bannerResponse.bannerList.count < 1) && retryCount > 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weak_self p_queryBanner:retryCount];
            });
            return;
        } else {
            if (completionBlock) {
                completionBlock(error, bannerResponse);
            }
        }
    }];
}

- (void)p_updatePromotionView {
    CJPayBannerResponse *bannerResponse = self.bannerResponse;
    if (!Check_ValidArray(bannerResponse.promotionModels)) {
        return;
    }
    [self p_trackerWithEventName:@"wallet_tixian_pay_finish_marketing_show" params:@{
        @"plan_no": CJString(bannerResponse.planNo),
        @"material_no": CJString(bannerResponse.materialNo),
        @"resource_no": CJString(bannerResponse.resourceNo),
        @"biztype": CJString(bannerResponse.bizType)
    }];
    [self.scrollContentView addSubview:self.promotionView];
    [self.promotionView updateWithPromotionModel:[bannerResponse.promotionModels cj_objectAtIndex:0]];
    CJPayMasMaker(self.promotionView, {
        make.left.equalTo(self.scrollContentView).offset(16);
        make.right.equalTo(self.scrollContentView).offset(-16);
        make.top.equalTo(self.arrivingView.mas_bottom).offset(28);
        make.height.mas_equalTo(101);
    });
}

- (void)p_updateBanners {
    NSMutableArray <UIView *> *array = [NSMutableArray new];
    NSMutableArray <NSNumber *> *durArray = [NSMutableArray new];
    NSArray<CJPayDiscountBanner *> *banners = self.bannerResponse.bannerList;
    if (!Check_ValidArray(banners)) {
        return;
    }
    MASConstraintMaker *make = [self.loopView cj_makeConstraint];
    make.left.equalTo(self.scrollContentView).offset(16);
    make.right.equalTo(self.scrollContentView).offset(-16);
    make.width.mas_equalTo(self.loopView.mas_height).multipliedBy(375 / 88);
    if (Check_ValidArray(self.bannerResponse.promotionModels)) {
        make.top.equalTo(self.promotionView.mas_bottom).offset(12);
    } else {
        make.top.equalTo(self.arrivingView.mas_bottom).offset(28);
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

- (void)p_bannerClick:(UITapGestureRecognizer *)sender {
    CJ_DelayEnableView(sender.view);

    NSInteger index = sender.view.tag;
    CJPayDiscountBanner *banner = [self.bannerResponse.bannerList cj_objectAtIndex:index];
    
    [self p_trackerWithEventName:@"wallet_tixian_progress_banner_click" params:@{
        @"status": [self p_getStatusName:self.response.tradeInfo.tradeStatusString],
        @"banner_url": CJString(banner.picUrl),
        @"banner_no": CJString(banner.resourceNo),
        @"place_no": CJString(self.bannerResponse.placeNo),
        @"is_first": self.orderNum == 0 ? @"1" : @"0",
        @"frame_order": @((self.orderNum % self.bannerResponse.bannerList.count) + 1).stringValue,
        @"frame_num": @((self.orderNum / self.bannerResponse.bannerList.count) + 1).stringValue,
        @"jump_url": CJString(banner.jumpUrl)
    }];
    
    CJPayLogInfo(@"wallet_tixian_progress_banner_click:\ntag: %d, order_num: %d", (int)index, self.orderNum);

    if (!Check_ValidString(banner.jumpUrl)) {
        return;
    }

    if ([banner.gotoType isEqualToString:@"0"]) {
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:[self.loopView cj_responseViewController] toUrl:banner.jumpUrl];
    } else if ([banner.gotoType isEqualToString:@"1"]) {
        [[CJPayWebViewUtil sharedUtil] openCJScheme:banner.jumpUrl fromVC:[self.loopView cj_responseViewController] useModal:YES];
    } else {
        [CJMonitor trackService:@"wallet_rd_tixian_banner_cannot_open" category:@{@"is_set_type": @"0", @"support": @"0"} extra:@{}];
        CJPayLogAssert(NO, @"未指定banner跳转类型");
    }
}

- (NSString *)p_getStatusName:(NSString *)status {
    NSMutableDictionary *statusMap = [NSMutableDictionary dictionaryWithDictionary:@{
        @"TIMEOUT" : @"提现失败",
        @"REVIEWING" : @"审核中",
        @"PROCESSING" : @"处理中",
        @"SUCCESS" : @"到账成功"
    }];
    NSString *statusName = [statusMap cj_stringValueForKey:@"status"];
    return CJString(statusName);
}

#pragma mark - Views

- (UIView *)bottomBackView {
    if (!_bottomBackView) {
        _bottomBackView = [UIView new];
        _bottomBackView.backgroundColor = [CJPayLocalThemeStyle defaultThemeStyle].withdrawArrivingViewBottomLineColor;
    }
    return _bottomBackView;
}

- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [UIScrollView new];
    }
    return _scrollView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [[UIView alloc] init];
    }
    return _scrollContentView;
}

- (CJPayWithDrawResultHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [[CJPayWithDrawResultHeaderView alloc] init];
        _headerView.translatesAutoresizingMaskIntoConstraints = NO;
        @CJWeakify(self)
        _headerView.didTapReasonBlock = ^{
            @CJStrongify(self);
            [CJTracker event:@"wallet_tixian_progress_reason" params:@{}];
            
            NSString *urlString = [NSString stringWithFormat:@"%@/withdraw/faq?type=withdraw&merchant_id=%@&app_id=%@",
                                   [CJPayBaseRequest bdpayH5DeskServerHostString],
                                   CJString(self.merchant.merchantId),
                                   CJString(self.merchant.appId)];
            [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self toUrl:urlString];
        };
        
    }
    
    return _headerView;
}

- (CJPayWithDrawResultArrivingView *)arrivingView {
    if (!_arrivingView) {
        _arrivingView = [[CJPayWithDrawResultArrivingView alloc] init];
        _arrivingView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _arrivingView;
}

- (CJPayWithDrawResultViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [[CJPayWithDrawResultViewModel alloc] init];
        _viewModel.headerView = self.headerView;
        _viewModel.bootomView = self.arrivingView;
    }
    return _viewModel;
}

- (CJPayLoopView *)loopView {
    if (!_loopView) {
        _loopView = [CJPayLoopView new];
        _loopView.indicatorDelegate = self.indicatorView;
        _loopView.delegate = self;
        _loopView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _loopView;
}

- (CJPayIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [CJPayIndicatorView new];
        _indicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        _indicatorView.cj_size = CGSizeMake(CJ_SCREEN_WIDTH, 6);
        _indicatorView.spacing = 8;
    }
    return _indicatorView;
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

- (CJPayBalanceResultPromotionView *)promotionView {
    if (!_promotionView) {
        _promotionView = [CJPayBalanceResultPromotionView new];
    }
    return _promotionView;
}


#pragma mark - Helpers

- (void)p_setupUI {
    [self setNavTitle:CJPayLocalizedStr(@"提现结果")];
    [self.navigationBar setBackgroundColor:[UIColor clearColor]];

    [self.view addSubview:self.scrollView];
    [self.scrollView addSubview:self.scrollContentView];
    [self.view addSubview:self.bgImageView];
    [self.view sendSubviewToBack:self.bgImageView];
    
    CJPayMasMaker(self.scrollView, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view).offset([self navigationHeight]);
    });
    
    CJPayMasMaker(self.scrollContentView, {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.scrollView);
        make.height.greaterThanOrEqualTo(self.scrollView);
    });

    [self.scrollContentView addSubview:self.headerView];
    [self.scrollContentView addSubview:self.arrivingView];
    [self.scrollContentView addSubview:self.loopView];
    [self.scrollContentView addSubview:self.indicatorView];
    [self.scrollContentView addSubview:self.completeButton];
    
    if (@available(iOS 11.0, *)) {
        self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    } else {
        // Fallback on earlier versions
    }

    self.headerView.hidden = YES;
    self.arrivingView.hidden = YES;
    
    CJPayMasMaker(self.headerView, {
        make.top.width.equalTo(self.scrollContentView);
        make.height.mas_equalTo(180);
    });
    
    CJPayMasMaker(self.arrivingView, {
        make.left.right.equalTo(self.view);
        make.top.mas_equalTo(self.headerView.mas_bottom).mas_offset(23);
    });
    
    CJPayMasMaker(self.indicatorView, {
        make.bottom.mas_equalTo(self.loopView.mas_bottom).mas_offset(-8);
        make.left.right.mas_equalTo(0);
        make.height.mas_equalTo(6);
    });
    
    CJPayMasMaker(self.completeButton, {
        make.bottom.equalTo(self.view).offset(-72-CJ_TabBarSafeBottomMargin);
        make.centerX.equalTo(self.view);
        make.width.mas_equalTo(160);
        make.height.mas_equalTo(42);
    });
    
    CJPayMasMaker(self.bgImageView, {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo(360);
    });
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.scrollContentView addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.height.mas_equalTo(18);
            make.bottom.equalTo(self.scrollContentView).offset(-16-CJ_TabBarSafeBottomMargin);
            make.centerX.equalTo(self.scrollContentView);
            make.top.greaterThanOrEqualTo(self.loopView.mas_bottom).offset(16);
        });
    }
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.hidden = YES;
    }
    return _safeGuardTipView;
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

- (NSString *)getStatusName:(NSString *)status {
    NSMutableDictionary *statusMap = [NSMutableDictionary dictionaryWithDictionary:@{
        @"TIMEOUT" : @"提现失败",
        @"REVIEWING" : @"审核中",
        @"PROCESSING" : @"处理中",
        @"SUCCESS" : @"到账成功"
    }];
    
    NSString *statusName = [statusMap cj_stringValueForKey:CJString(status)];
    return CJString(statusName);
}

- (void)completeButtonClick {
    [self back];
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

#pragma mark - CJPayLoopViewDelegate

- (void)loopView:(CJPayLoopView *)loopView bannerAppearAtIndex:(NSUInteger)index atPage:(NSUInteger)pageNum {
    if (self.bannerResponse.bannerList.count < 1) {
        return;
    }
    int viewCount = (int)self.bannerResponse.bannerList.count;
    self.orderNum = viewCount * (int)pageNum + (int)index;
    CJPayDiscountBanner *banner = [self.bannerResponse.bannerList cj_objectAtIndex:index];
    
    [self p_trackerWithEventName:@"wallet_tixian_progress_banner_imp" params:@{
        @"status": [self p_getStatusName:self.response.tradeInfo.tradeStatusString],
        @"banner_url": CJString(banner.picUrl),
        @"banner_no": CJString(banner.resourceNo),
        @"place_no": CJString(self.bannerResponse.placeNo),
        @"is_first": self.orderNum == 0 ? @"1" : @"0",
        @"frame_order": @(index + 1).stringValue,
        @"frame_num": @(pageNum + 1).stringValue,
        @"jump_url": CJString(banner.jumpUrl)
    }];
    
    CJPayLogInfo(@"wallet_tixian_progress_banner_imp:\ntag: %d, order_num: %d", (int)index, self.orderNum);
}


@end
