//
//  CJPayDouyinStyleHalfLoadingItem.m
//  CJPay
//
//  Created by 孔伊宁 on 2022/8/16.
//

#import "CJPayHalfLoadingItem.h"
#import "CJPayDouyinStyleHalfLoadingItem.h"
#import "CJPayAccountInsuranceTipView.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayCurrentTheme.h"
#import "CJPayUIMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPaySDKMacro.h"
#import "UIViewController+CJTransition.h"
#import "CJPayAlertController.h"

@interface CJPayDouyinStyleHalfLoadingItem ()

@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayWindow *loadingWindow;
@property (nonatomic, strong) BDImageView *loadPreGifView;
@property (nonatomic, strong) BDImageView *loadCompleteGifView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayLoadingStyleInfo *loadingStyleInfo;
@property (nonatomic, assign) BOOL isCompactStyle;
@property (nonatomic, assign) CGFloat loadingAddedContainerHeight;

@end

@implementation CJPayDouyinStyleHalfLoadingItem

@synthesize delegate = _delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    @CJWeakify(self)
    self.timerManager.timeOutBlock = ^{
        @CJStrongify(self)
        NSString *viewControllerListStr = [NSString stringWithFormat:@"%@", self.topVc.navigationController.viewControllers];
        [CJMonitor trackService:@"wallet_rd_half_loading_timeout"
                       category:@{@"type": [self loadingTitle]}
                          extra:@{@"vcs": CJString(viewControllerListStr)}];
        [self stopLoading];
        // [self resetLoadingCount];
    };
    if (CJ_Pad) {
        if (@available(iOS 13.0, *)) {
            self.modalInPresentation = YES;
        }
    }
}

- (void)p_setupUI {
    [self hideBackButton];
    
    UIViewController *topVC = [UIViewController cj_topViewController];
    if ([topVC isKindOfClass:[CJPayHalfPageBaseViewController class]]) {
        CGFloat loadingShowheight = ((CJPayHalfPageBaseViewController *)topVC).loadingShowheight;
        self.isCompactStyle = loadingShowheight > CGFLOAT_MIN;
        if (self.isCompactStyle) {
            self.loadingAddedContainerHeight = ((CJPayHalfPageBaseViewController *)topVC).containerHeight - loadingShowheight;
            self.title = @"";
        }
    }
    
    self.loadPreGifView.backgroundColor = [UIColor clearColor];
    [self.contentView addSubview:self.loadPreGifView];
    [self.contentView addSubview:self.loadCompleteGifView];
    [self.contentView addSubview:self.titleLabel];

    self.loadPreGifView.hidden = YES;
    self.loadCompleteGifView.hidden = YES;
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.loadPreGifView.mas_bottom).offset(15);
        make.centerX.equalTo(self.contentView);
        make.height.mas_equalTo(22);
    });
    
    CJPayMasMaker(self.loadPreGifView, {
        make.top.mas_equalTo(self.navigationBar.mas_bottom).offset(([self containerHeight] - 60 - (self.isCompactStyle ? (self.loadingAddedContainerHeight+200) : 0)) * 5 / 21); // 兼容刘海屏与非刘海屏
        make.centerX.mas_equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(82, 82));
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            make.bottom.greaterThanOrEqualTo(self.safeGuardTipView.mas_top).offset(-20).priorityHigh();
        }
    });
    CJPayMasMaker(self.loadCompleteGifView, {
        make.top.mas_equalTo(self.navigationBar.mas_bottom).offset(([self containerHeight] - 60 - (self.isCompactStyle?(self.loadingAddedContainerHeight+200):0)) * 5 / 21); // 兼容刘海屏与非刘海屏
        make.centerX.mas_equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(82, 82));
        if ([CJPayAccountInsuranceTipView shouldShow]) {
            make.bottom.greaterThanOrEqualTo(self.safeGuardTipView.mas_top).offset(-20).priorityHigh();
        }
    });
    
    if ([CJPayAccountInsuranceTipView shouldShow]) {
        [self.contentView addSubview:self.safeGuardTipView];
        CJPayMasMaker(self.safeGuardTipView, {
            make.bottom.equalTo(self.contentView).offset(-16 - CJ_TabBarSafeBottomMargin);
            make.centerX.equalTo(self.contentView);
            make.height.mas_equalTo(16);
        });
    }
}

- (void)p_remakeLayout {
    if (self.loadPreGifView.superview == self.contentView) {
        CJPayMasReMaker(self.loadPreGifView, {
            make.top.mas_equalTo(self.navigationBar.mas_bottom).offset(([self containerHeight] - 60 - (self.isCompactStyle ? (self.loadingAddedContainerHeight+200) : 0)) * 5 / 21); // 兼容刘海屏与非刘海屏
            make.centerX.mas_equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(82, 82));
            if ([CJPayAccountInsuranceTipView shouldShow] && self.safeGuardTipView.superview == self.contentView) {
                make.bottom.greaterThanOrEqualTo(self.safeGuardTipView.mas_top).offset(-20).priorityHigh();
            }
        });
    }
    
    if (self.loadCompleteGifView.superview == self.contentView) {
        CJPayMasReMaker(self.loadCompleteGifView, {
            make.top.mas_equalTo(self.navigationBar.mas_bottom).offset(([self containerHeight] - 60 - (self.isCompactStyle?(self.loadingAddedContainerHeight+200):0)) * 5 / 21); // 兼容刘海屏与非刘海屏
            make.centerX.mas_equalTo(self.contentView);
            make.size.mas_equalTo(CGSizeMake(82, 82));
            if ([CJPayAccountInsuranceTipView shouldShow] && self.safeGuardTipView.superview == self.contentView) {
                make.bottom.greaterThanOrEqualTo(self.safeGuardTipView.mas_top).offset(-20).priorityHigh();
            }
        });
    }
}

- (void)startLoading {
    if (!self.isCompactStyle) {
        self.title = [self loadingTitle];
    } else {
        self.title = @"";
    }
    
    [self p_remakeLayout];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self.timerManager startTimer:[CJPaySettingsManager shared].currentSettings.loadingConfig.halfLoadingTimeOut ?: 16];
    [self addLoadingCount];
    [self p_push];
    [self startAnimation];
    self.titleLabel.text = CJPayDYPayLoadingTitle;
    self.view.userInteractionEnabled = NO;
}

- (void)startLoadingWithValidateTimer:(BOOL)isNeedValiteTimer {
    if (!self.isCompactStyle) {
        self.title = [self loadingTitle];
    } else {
        self.title = @"";
    }
    
    if (!isNeedValiteTimer) {
        [self startLoading];
        return;
    }
    
    CJPayLoadingShowInfo *preShowInfo = [CJPayLoadingManager defaultService].loadingStyleInfo.preShowInfo;
    NSInteger preShowMinTime = preShowInfo.minTime;
    NSString *preShowText = preShowInfo.text;
    
    [self p_remakeLayout];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    [self.timerManager startTimer:[CJPaySettingsManager shared].currentSettings.loadingConfig.halfLoadingTimeOut ?: 16];
    [self addLoadingCount];
    [self p_push];
    [self startAnimation];
    self.view.userInteractionEnabled = NO;
    
    NSString *loadingTitle = Check_ValidString(preShowText) ? preShowText : CJPayDYPayLoadingTitle;
    self.titleLabel.text = CJString(loadingTitle);
    if (preShowMinTime <= 0) {
        [self p_preShowTimerTrigger];
        return;
    }
    
    CJPayTimerManager *preShowTimer = [CJPayLoadingManager defaultService].preShowTimerManger;
    [preShowTimer startTimer:preShowMinTime / 1000.0];
    @CJWeakify(preShowTimer)
    preShowTimer.timeOutBlock = ^{
        @CJStrongify(preShowTimer)
        [preShowTimer stopTimer];
        [self p_preShowTimerTrigger];
    };
}

- (void)p_preShowTimerTrigger {
    CJPayLoadingShowInfo *payingShowInfo = [CJPayLoadingManager defaultService].loadingStyleInfo.payingShowInfo;
    NSInteger payingShowMinTime = payingShowInfo.minTime;
    NSString *payingShowText = payingShowInfo.text;
    
    BOOL isLoadingTitleDowngrade = [CJPayLoadingManager defaultService].isLoadingTitleDowngrade;
    NSString *loadingTitle = !isLoadingTitleDowngrade && Check_ValidString(payingShowText) ? payingShowText : CJPayDYPayLoadingTitle;
    self.titleLabel.text = CJString(loadingTitle);
    if (payingShowMinTime <= 0) {
        return;
    }
    
    CJPayTimerManager *payingShowTimer = [CJPayLoadingManager defaultService].payingShowTimerManger;
    [payingShowTimer startTimer:payingShowMinTime / 1000.0];
    @CJWeakify(payingShowTimer)
    payingShowTimer.timeOutBlock = ^{
        @CJStrongify(payingShowTimer)
        [payingShowTimer stopTimer];
    };
}

- (void)stopLoading {
    [self.timerManager stopTimer];
    [self dismiss];
}

- (void)stopLoadingWithState:(CJPayLoadingQueryState)state {
    CJPayTimerManager *preShowTimer = [CJPayLoadingManager defaultService].preShowTimerManger;
    CJPayTimerManager *payingShowTimer = [CJPayLoadingManager defaultService].payingShowTimerManger;
    if ([preShowTimer isTimerValid]) {
        [preShowTimer appendTimeoutBlock:^{
            [self stopLoadingWithState:state];
        }];
        return;
    }
    
    if ([payingShowTimer isTimerValid]) {
        [payingShowTimer appendTimeoutBlock:^{
            [self stopLoading];
        }];
        return;
    }
    
    [self stopLoading];
}

- (void)p_push {
    UIViewController *topVc = [UIViewController cj_topViewController];
    self.topVc = topVc;
    self.originNavigationController = topVc.navigationController;
    if (CJ_Pad || [CJPaySettingsManager shared].currentSettings.loadingConfig.enableHalfLoadingUseWindow) {
        [self presentWithNavigationControllerFrom:self.loadingWindow.rootViewController useMask:NO completion:nil];
    } else {
        if (topVc.navigationController != self.navigationController || !self.navigationController) {
            CJPayNavigationController *naviController = [self presentWithNavigationControllerFrom:topVc useMask:NO completion:nil];
            naviController.cjpadPreferHeight = 620.5f;
        } else {
            [self.navigationController pushViewController:self animated:NO];
        }
    }
}

- (void)startAnimation {
    self.loadPreGifView.hidden = NO;
    self.loadCompleteGifView.hidden = YES;
    [self.loadPreGifView cj_loadGifAndOnceLoopWithURL:[self preLoadGifUrl] duration:0.2];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.loadPreGifView cj_loadGifAndInfinityLoopWithURL:[self repeatGifUrl] duration:0.2];
    });
}

- (NSString *)loadingTitle {
    return CJPayDYPayTitleMessage;
}

+ (CJPayLoadingType)loadingType {
    return CJPayLoadingTypeDouyinStyleHalfLoading;
}

- (void)dismiss {
    [self.loadPreGifView stopAnimation];
    [self.loadCompleteGifView stopAnimation];
    self.view.userInteractionEnabled = YES;
    [self dismissViewControllerAnimated:NO completion:nil];
    [self resetLoadingCount];
    if (_loadingWindow) {
        self.loadingWindow.hidden = YES;
        [self.loadingWindow removeFromSuperview];
        self.loadingWindow = nil;
    }
}

- (BOOL)cjNeedAnimation {
    return NO;
}

- (NSString *)preLoadGifUrl {
    return [CJPaySettingsManager shared].currentSettings.securityLoadingConfig.breatheStyleLoadingConfig.panelPreGif;
}

- (NSString *)repeatGifUrl {
    return [CJPaySettingsManager shared].currentSettings.securityLoadingConfig.breatheStyleLoadingConfig.panelRepeatGif;
}

#pragma mark - lazy init

- (BOOL)isCompactStyle {
    _isCompactStyle = NO;
    UIViewController *topVC = [UIViewController cj_topViewController];
    if ([topVC isKindOfClass:[CJPayHalfPageBaseViewController class]]) {
        CGFloat loadingShowheight = ((CJPayHalfPageBaseViewController *)topVC).loadingShowheight;
        _isCompactStyle = loadingShowheight > CGFLOAT_MIN;
    }
    return _isCompactStyle;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

- (BDImageView *)loadPreGifView {
    if (!_loadPreGifView) {
        _loadPreGifView = [BDImageView new];
        _loadPreGifView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _loadPreGifView;
}

- (BDImageView *)loadCompleteGifView {
    if (!_loadCompleteGifView) {
        _loadCompleteGifView = [BDImageView new];
        _loadCompleteGifView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _loadCompleteGifView;
}

- (CJPayWindow *)loadingWindow {
    if (!_loadingWindow) {
        _loadingWindow = [[CJPayWindow alloc] init];
        _loadingWindow.backgroundColor = UIColor.clearColor;
        _loadingWindow.rootViewController = [UIViewController new];
    }
    _loadingWindow.frame = self.originNavigationController.cj_window.frame;
    if (@available(iOS 13.0, *)) {
        _loadingWindow.windowScene = self.originNavigationController.cj_window.windowScene;
    } else {
        // Fallback on earlier versions
    }
    _loadingWindow.hidden = NO;
    return _loadingWindow;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:16];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (CJPayLoadingStyleInfo *)loadingStyleInfo {
    if (!_loadingStyleInfo) {
        _loadingStyleInfo = [CJPayLoadingManager defaultService].loadingStyleInfo;
    }
    return _loadingStyleInfo;
}

@end

