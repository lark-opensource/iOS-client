//
//  CJPayBDResultPageViewController.m
//  CJPay-BDPay
//
//  Created by wangxinhua on 2020/9/18.
//

#import "CJPayBDResultPageViewController.h"
#import "CJPayResultPageView.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayNameModel.h"
#import "CJPayKVContext.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPayPayBannerRequest.h"
#import "CJPayPayBannerResponse.h"
#import "CJPayTracker.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPaySettingsManager.h"
#import "CJPayUIMacro.h"
#import "CJPayResultPageInfoModel.h"

@interface CJPayBDResultPageViewController ()<CJPayResultPageViewDelegate>

@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *stateLabel;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) CJPayResultPageView *resultView;
@property (nonatomic, strong) CJPayBDCreateOrderResponse *createOrderResponse;
@property (nonatomic, assign) CJPayStateType stateType;
@property (nonatomic, strong) UIButton *successBtn;
@property (nonatomic, strong) CJPayPayBannerResponse *tmpBannerResponse;

@property (nonatomic, assign) BOOL isHasShowResult;

@end

@implementation CJPayBDResultPageViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.exitAnimationType = HalfVCEntranceTypeFromBottom;
    }
    return self;
}

#pragma mark - Lifecycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.isHasShowResult) {
        [self p_showResult];
        [self p_setupUI];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setNavTitle];
    self.navigationBar.backBtn.hidden = YES;
    [self p_trackWhenViewDidLoad];
    self.createOrderResponse = self.verifyManager.response;
}

#pragma mark - private view

- (void)p_setupUI {
    [self.contentView addSubview:self.bgImageView];
    [self.contentView addSubview:self.resultView];
    [self.contentView addSubview:self.iconView];
    [self.contentView addSubview:self.stateLabel];
    [self.contentView addSubview:self.amountLabel];
    [self.navigationBar addSubview:self.successBtn];
    
    CJPayMasMaker(self.resultView, {
        make.top.equalTo(self.amountLabel.mas_bottom);
        make.left.right.bottom.equalTo(self.contentView);
    });
    CJPayMasMaker(self.bgImageView, {
        make.top.equalTo(self).offset(-50);
        make.left.right.equalTo(self);
        make.height.mas_equalTo(CJ_SCREEN_WIDTH * 360 / 375);
    });
    CJPayMasMaker(self.iconView, {
        make.top.equalTo(self).offset(-10);
        make.centerX.equalTo(self);
        make.height.width.mas_equalTo(32);
    });
    CJPayMasMaker(self.stateLabel, {
        make.top.equalTo(self.iconView.mas_bottom).offset(10);
        make.centerX.equalTo(self);
        make.left.right.equalTo(self);
    });
    CJPayMasMaker(self.amountLabel, {
        make.top.equalTo(self.stateLabel.mas_bottom).offset(12);
        make.centerX.equalTo(self);
        make.left.right.equalTo(self);
    });
    CJPayMasMaker(self.successBtn, {
        make.top.bottom.right.equalTo(self.navigationBar);
        make.width.mas_equalTo(66);
    });
    [self p_updateSafeGuardState];
}

- (void)p_queryBanner:(NSInteger)retryCount {
    @CJWeakify(self)
    [CJPayPayBannerRequest startRequestWithAppId:self.createOrderResponse.merchant.appId outTradeNo:self.createOrderResponse.intergratedTradeIdentify merchantId:self.createOrderResponse.merchant.intergratedMerchantId uid:self.createOrderResponse.userInfo.uid amount:self.createOrderResponse.tradeInfo.tradeAmount completion:^(NSError * _Nullable error, CJPayPayBannerResponse * _Nonnull bannerResponse) {
        @CJStrongify(self)
        if ([bannerResponse.status isEqualToString:@"SUCCESS"]) {
            if ([bannerResponse.code isEqualToString:@"PP000000"]) {//停止轮训，刷新页面
                [self.resultView updateBannerContentWithModel:[bannerResponse.dynamicComponents cj_objectAtIndex:0] benefitStr:bannerResponse.benefitInfo];
                self.resultView.resultPageType = CJPayResultPageTypeBanner;
                [self p_pageShowEvent:bannerResponse.dynamicComponents];
            } else if (retryCount > 0) {//继续轮训
                if ([bannerResponse.code isEqualToString:@"PP100066"]) {
                    self.tmpBannerResponse = bannerResponse;
                }
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    @CJStrongify(self)
                    [self p_queryBanner:retryCount - 1];
                });
            } else if (retryCount == 0) {
                if ([bannerResponse.code isEqualToString:@"PP100066"]) {
                    [self.resultView updateBannerContentWithModel:[bannerResponse.dynamicComponents cj_objectAtIndex:0] benefitStr:bannerResponse.benefitInfo];
                    [self p_pageShowEvent:bannerResponse.dynamicComponents];
                } else if (self.tmpBannerResponse) {
                    [self.resultView updateBannerContentWithModel:[self.tmpBannerResponse.dynamicComponents cj_objectAtIndex:0] benefitStr:self.tmpBannerResponse.benefitInfo];
                    [self p_pageShowEvent:self.tmpBannerResponse.dynamicComponents];
                } else {
                    [self p_pageShowEvent:@[]];
                }
            }
        } else {
            [self p_pageShowEvent:@[]];
        }
    }];
}

- (BOOL)p_isCombinePay {
    return [self.resultResponse.tradeInfo.payType isEqualToString:@"combinepay"];
}

- (BOOL)p_isShowSignDetail {
    return self.resultResponse.contentList.count > 0;
}

- (void)p_setNavTitle {
    NSString *cashierTitle = [CJPayBrandPromoteABTestManager shared].model.cashierTitle;
    NSString *quickPayCashierTitle = [CJPayBrandPromoteABTestManager shared].model.oneKeyQuickCashierTitle;
    if (self.verifyManager.isOneKeyQuickPay) {
        if (Check_ValidString(quickPayCashierTitle)) {
            [self setTitle:CJPayLocalizedStr(quickPayCashierTitle)];
        } else {
            CJPayNameModel *nameModel = [CJPayKVContext kv_valueForKey:CJPayDeskTitleKVKey];
            [self setTitle:CJPayLocalizedStr(nameModel.payName) ?: CJPayLocalizedStr(@"极速支付")];
        }
    } else {
        if (Check_ValidString(cashierTitle)) {
            [self setTitle:CJPayLocalizedStr(cashierTitle)];
        } else {
            CJPayNameModel *nameModel = [CJPayKVContext kv_valueForKey:CJPayDeskTitleKVKey];
            [self setTitle:CJPayLocalizedStr(nameModel.payName) ?: CJPayLocalizedStr(@"支付")];
        }
    }
    
    if (self.isPaymentForOuterApp) {
        // 设置文字版(图片)抖音支付，先注释
//        [self setTitle:@""];
//        [self.navigationBar setTitleImage:@"cj_nav_title_image"];
    }
}

- (void)p_trackWhenViewDidLoad {
    NSString *result = @"处理中";
    if (!self.resultResponse) { // 网络异常
        result = @"失败";
    } else if (![self.resultResponse isSuccess]) {
        result = @"处理中";
    } else {
        switch (self.resultResponse.tradeInfo.tradeStatus) {
            case CJPayOrderStatusTimeout:
                result = @"超时";
                break;
            case CJPayOrderStatusSuccess:
                result = @"成功";
                break;
            case CJPayOrderStatusProcess:
                result = @"处理中";
                break;
            case CJPayOrderStatusFail:
                result = @"失败";
                break;
            default:
                result = @"处理中";
                break;
        }
    }
    NSString *isSkipPwdGuideStr = [self.resultResponse.resultPageGuideInfoModel.guideType isEqualToString:@"nopwd_guide"] ? @"1" : @"0";
    NSString *isFaceGuideStr = self.resultResponse.bioPaymentInfo.showGuide ? @"1" : @"0";
    NSString *finishImpEventName = self.verifyManager.isOneKeyQuickPay ? @"wallet_cashier_fastpay_finish_page_imp": @"wallet_cashier_pay_finish_page_imp";
    [self p_trackWithEventName:finishImpEventName
                        params:@{@"result": CJString(result),
                                 @"is_pswd_guide": CJString(isSkipPwdGuideStr),
                                 @"is_face_guide": CJString(isFaceGuideStr)
                            }];
}

- (void)p_pageShowEvent:(NSArray<CJPayDynamicComponents> *)dynamicComponents {
    NSMutableDictionary *params = [NSMutableDictionary new];
    __block NSString *dynamicComponentsStr = @"";
    [dynamicComponents enumerateObjectsUsingBlock:^(CJPayDynamicComponents * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dynamicComponentsStr = dynamicComponentsStr.length > 0 ? [dynamicComponentsStr stringByAppendingFormat:@",%@" , CJString(obj.name)] : [dynamicComponentsStr stringByAppendingString:CJString(obj.name)];
    }];
    dynamicComponentsStr = dynamicComponentsStr.length > 0 ? [dynamicComponentsStr stringByAppendingFormat:@",%@" , CJString(self.resultResponse.resultConfig.bottomGuideInfo.text)] : [dynamicComponentsStr stringByAppendingString:CJString(self.resultResponse.resultConfig.bottomGuideInfo.text)];
    [params cj_setObject:[[[dynamicComponents cj_objectAtIndex:0] toDictionary] cj_toStr] forKey:@"dynamic_data"];
    [params cj_setObject:CJString(dynamicComponentsStr) forKey:@"dynamic_components"];
    [params cj_setObject:@"native支付结果页" forKey:@"project"];
    [self p_trackWithEventName:@"wallet_cashier_result_page_imp"
                        params:params];
}

- (void)p_setSuccessState {
    self.navigationBar.titleLabel.hidden = YES;
    
    self.navigationBar.backgroundColor = [UIColor cj_f8f8f8ff];
    self.contentView.backgroundColor = [UIColor cj_f8f8f8ff];
    
    [self.bgImageView cj_setImageWithURL:[NSURL URLWithString:CJString( self.resultResponse.resultConfig.bgImageURL)]];
    [self.iconView cj_setImageWithURL:[NSURL URLWithString:CJString(self.resultResponse.resultConfig.iconUrl)]];
    self.stateView.backgroundColor = [UIColor cj_f8f8f8ff];
    
    NSString *resultDesc = self.resultResponse.resultConfig.resultDesc;
    self.stateLabel.text = Check_ValidString(resultDesc) ? resultDesc : CJPayLocalizedStr(@"支付成功");
    self.amountLabel.attributedText = [self p_titleAttributedStrWithFrontStr:@"" latterStr:[NSString stringWithFormat:@"%.2f", [@(self.resultResponse.tradeInfo.payAmount).stringValue floatValue] * 0.01]];
    self.successBtn.hidden = ![self.resultResponse.resultConfig.successBtnPosition isEqualToString:@"top"];
    [self.successBtn cj_setBtnTitle:self.resultResponse.resultConfig.successBtnDesc ?: CJPayLocalizedStr(@"返回")];
    
}

- (void)p_setNewStyleShowModelWithType:(CJPayStateType)type {
    CJPayStateShowModel *showModel = [CJPayStateShowModel new];
    showModel.iconBackgroundColor = [UIColor clearColor];
    switch (type) {
        case CJPayStateTypeSuccess: {
            showModel.titleAttributedStr = [[NSMutableAttributedString alloc] initWithString:CJPayLocalizedStr(@"支付成功") attributes:@{
                NSFontAttributeName: [UIFont cj_fontOfSize:16],
                NSForegroundColorAttributeName: [UIColor cj_161823WithAlpha:0.5]
            }];
            showModel.iconName = [CJPaySettingsManager shared].currentSettings.securityLoadingConfig.breatheStyleLoadingConfig.panelCompleteSuccessGif;
            [self.stateView updateShowConfigsWithType:CJPayStateTypeSuccess model:showModel];
            break;
        }
        default:
            break;
    }
}

- (void)p_showResult {
    self.isHasShowResult = YES;
    [self p_setStateType];
    self.stateView.isPaymentForOuterApp = self.isPaymentForOuterApp;
    [self showState:self.stateType];
    
    //电商安全感新样式需要展示新样式结果页，且不需要手动关闭
    if (self.isShowNewStyle) {
        [self p_closeActionAfterTime:1];
        return;
    }
    
    [self p_closeActionAfterTime:[self.resultResponse closeAfterTime]];
}

- (void)p_setStateType {
    CJPayStateType stateType = CJPayStateTypeWaiting;
    if (!self.resultResponse) { // 网络异常
        stateType = CJPayStateTypeNetException;
    } else if (![self.resultResponse isSuccess]) {
        stateType = CJPayStateTypeWaiting;
    } else if (self.isShowNewStyle) { //电商收银台安全感Loading结果页新样式
        switch (self.resultResponse.tradeInfo.tradeStatus) {
            case CJPayOrderStatusSuccess:
                stateType = CJPayStateTypeSuccess;
                [self p_setNewStyleShowModelWithType:CJPayStateTypeSuccess];
                self.resultView.resultPageType = [self p_resultPageType];
                [self p_updateStateViewUIWithResultPageType:self.resultView.resultPageType];
                break;
            default:
                break;
        }
    } else {
        switch (self.resultResponse.tradeInfo.tradeStatus) {
            case CJPayOrderStatusTimeout:
                stateType = CJPayStateTypeTimeOut;
                break;
            case CJPayOrderStatusSuccess:
                stateType = CJPayStateTypeSuccess;
                [self p_setSuccessState];
                self.resultView.resultPageType = [self p_resultPageType];
                [self p_updateStateViewUIWithResultPageType:self.resultView.resultPageType];
                break;
            case CJPayOrderStatusProcess:
                stateType = CJPayStateTypeWaiting;
                self.resultView.resultPageType = [self p_resultPageType];
                [self p_updateStateViewUIWithResultPageType:self.resultView.resultPageType];
                break;
            case CJPayOrderStatusFail:
                stateType = CJPayStateTypeFailure;
                self.resultView.resultPageType = [self p_resultPageType];
                [self p_updateStateViewUIWithResultPageType:self.resultView.resultPageType];
                break;
            default:
                break;
        }
    }
    self.stateType = stateType;
}

- (void)p_updateStateViewUIWithResultPageType:(CJPayResultPageType)type {
    if ([self p_isCombinePay] || type & CJPayResultPageTypeSignDYPay) {
        CJPayMasUpdate(self.stateView, {
            make.top.mas_equalTo(self.contentView).offset(60);
        });
        [self.contentView setNeedsLayout];
        return;
    }
}
    
- (CJPayResultPageType)p_resultPageType {
    CJPayResultPageType pageType = CJPayResultPageTypeNone;
    
    if (self.isPaymentForOuterApp) {
        pageType = CJPayResultPageTypeOuterPay;
    }
    
    if ([self p_isCombinePay]) {
        pageType = pageType | CJPayResultPageTypeCombinePay;
    }
    
    if ([self p_isShowSignDetail]) {
        pageType = pageType | CJPayResultPageTypeSignDYPay;
    }
    return pageType;
}

- (void)p_updateSafeGuardState {
    CJPayResultPageType resultPageType = self.resultView.resultPageType;
    if (self.stateType == CJPayStateTypeTimeOut ||
        self.stateType == CJPayStateTypeWaiting) {
        [self.resultView hideSafeGuard];
    }
}

- (NSMutableAttributedString *)p_titleAttributedStrWithFrontStr:(NSString *)frontStr latterStr:(NSString *)latterStr {
    NSDictionary *frontAttributes = @{NSFontAttributeName : [UIFont cj_denoiseBoldFontOfSize:28]};
    NSDictionary *latterAttributes = @{NSFontAttributeName : [UIFont cj_denoiseBoldFontOfSize:40]};
    NSMutableAttributedString *frontAttr = [[NSMutableAttributedString alloc] initWithString:@"￥" attributes:frontAttributes];
    [frontAttr addAttribute:NSBaselineOffsetAttributeName value:@(-1.5) range:NSMakeRange(0, frontAttr.length)];
    [frontAttr addAttribute:NSKernAttributeName value:@(-4) range:NSMakeRange(0,1)];
    NSMutableAttributedString *latterAttr = [[NSMutableAttributedString alloc] initWithString:latterStr attributes:latterAttributes];
    [latterAttr addAttribute:NSBaselineOffsetAttributeName value:@(-1.5) range:NSMakeRange(0, latterStr.length)];
    NSMutableAttributedString *titleAttributedStr = [[NSMutableAttributedString alloc] initWithString:CJString(frontStr) attributes:frontAttributes];
    [titleAttributedStr appendAttributedString:frontAttr];
    [titleAttributedStr appendAttributedString:latterAttr];
    return titleAttributedStr;
}

- (BOOL)p_isShowBanner {
    return !self.resultResponse.bioPaymentInfo.showGuide && !self.isForceCloseBuyAgain && !self.isPaymentForOuterApp && self.stateType == CJPayStateTypeSuccess;
}

- (void)p_closeActionAfterTime:(int)time {
    if([self p_isShowBanner]) {
        [self p_queryBanner:20];//轮询10s，每次间隔0.5s
    }
    if (time < 0) { // 小于0的话，不关闭结果页，让用户手动关闭
        return;
    }
    @CJWeakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self);
        [self back];
    });
}

- (NSDictionary *)p_commonTrackParamWithBizParam:(NSDictionary *)params {
    NSMutableDictionary *mutableDic = [[CJPayCommonTrackUtil getBDPayCommonParamsWithResponse:self.createOrderResponse showConfig:self.verifyManager.defaultConfig] mutableCopy];
    [mutableDic addEntriesFromDictionary:params];
    return [mutableDic copy];
}

- (void)p_superClose {
    [super back];
}

#pragma mark - override method

- (void)back {
    [self p_superClose];
    NSString *finishClickEventName = self.verifyManager.isOneKeyQuickPay ? @"wallet_cashier_fastpay_finish_page_icon_click": @"wallet_cashier_pay_finish_page_icon_click";
    [self p_trackWithEventName:finishClickEventName
                        params:[self p_commonTrackParamWithBizParam:@{@"icon_name" : @"返回"}]];
}

- (void)stateButtonClick:(NSString *)buttonName {
    if (Check_ValidString(buttonName)) {
        NSString *finishClickEventName = self.verifyManager.isOneKeyQuickPay ? @"wallet_cashier_fastpay_finish_page_icon_click" : @"wallet_cashier_pay_finish_page_icon_click";
        [self p_trackWithEventName:finishClickEventName
                            params:[self p_commonTrackParamWithBizParam:@{@"icon_name" : CJString(buttonName)}]];
    }
    
    [self p_superClose];
}

#pragma mark - lazy views

- (CJPayResultPageView *)resultView {
    if (!_resultView) {
        _resultView = [[CJPayResultPageView alloc] initWithResultResponse:self.resultResponse createOrderResponse:self.createOrderResponse];
        _resultView.delegate = self;
    }
    return _resultView;
}

- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [UIImageView new];
    }
    return _bgImageView;
}

- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [UIImageView new];
    }
    return _iconView;
}

- (UILabel *)stateLabel {
    if (!_stateLabel) {
        _stateLabel = [[UILabel alloc] init];
        _stateLabel.font = [UIFont cj_fontOfSize:16];
        _stateLabel.textColor = [UIColor cj_161823ff];
        _stateLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _stateLabel;
}

- (UILabel *)amountLabel {
    if (!_amountLabel) {
        _amountLabel = [[UILabel alloc] init];
        _amountLabel.textColor = [UIColor cj_161823ff];
        _amountLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _amountLabel;
}

- (UIButton *)successBtn {
    if (!_successBtn) {
        _successBtn = [CJPayButton new];
        [_successBtn setTitle:CJPayLocalizedStr(@"返回") forState:UIControlStateNormal];
        [_successBtn setTitleColor:[UIColor cj_161823WithAlpha:0.75] forState:UIControlStateNormal];
        _successBtn.titleLabel.font = [UIFont cj_fontOfSize:15];
        [_successBtn addTarget:self action:@selector(p_tapTopButton:) forControlEvents:UIControlEventTouchUpInside];
        _successBtn.hidden = YES;
    }
    return _successBtn;
}

- (void)p_tapTopButton:(UIButton *)button {
    [self stateButtonClick:button.titleLabel.text];
}

#pragma mark - Tracker

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    [self.verifyManager.verifyManagerQueen trackCashierWithEventName:eventName params:params];
}

@end
