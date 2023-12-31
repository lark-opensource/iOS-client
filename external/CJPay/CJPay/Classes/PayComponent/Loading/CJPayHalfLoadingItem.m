//
//  CJPayHalfLoadingItem.m
//  Pods
//
//  Created by 易培淮 on 2021/8/17.
//

#import "CJPayHalfLoadingItem.h"
#import "CJPayAccountInsuranceTipView.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayCurrentTheme.h"
#import "CJPayUIMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "UIViewController+CJTransition.h"
#import "CJPayAlertController.h"

@interface CJPayHalfLoadingItem ()

@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;
@property (nonatomic, strong) CJPayWindow *loadingWindow;

@end

@implementation CJPayHalfLoadingItem

@synthesize delegate = _delegate;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    if (CJ_Pad) {
        if (@available(iOS 13.0, *)) {
            self.modalInPresentation = YES;
        }
    }
}

- (void)startAnimation {
    [self.imageView cj_loadGifAndInfinityLoop:@"cj_loading_gif" duration:1.3];
}

- (UIViewController *)cj_customTopVC {
    if (self.originNavigationController) {
        return [self.originNavigationController.viewControllers lastObject];
    } else if (self.topVc) {
        return self.topVc;
    } else {
        return self;
    }
}

#pragma mark - CJPayAdvanceLoadingProtocol
- (void)stopLoading {
    [self p_stopLoading];
}

- (void)stopLoadingWithState:(CJPayLoadingQueryState)state {
    [self stopLoading];
}

- (void)startLoading {
    self.title = [self loadingTitle];
    [self p_startLoading];
}

- (void)startLoadingWithValidateTimer:(BOOL)isNeedValiteTimer {
    [self startLoading];
}

- (void)startLoadingWithTitle:(NSString *)title {
    self.title = CJString(title);
    [self p_startLoading];
}

- (void)startLoadingWithVc:(UIViewController *)vc {
    [self p_startLoading];
}

- (void)startLoadingWithVc:(UIViewController *)vc title:(NSString *)title {
    self.title = CJString(title);
    [self p_startLoading];
}

+ (CJPayLoadingType )loadingType {
    return CJPayLoadingTypeHalfLoading;
}

- (void)addLoadingCount {
    if (self.delegate && [self.delegate respondsToSelector:@selector(addLoadingCount:)]) {
        [self.delegate addLoadingCount:[[self class] loadingType]];
    }
}

- (void)resetLoadingCount {
    if (self.delegate && [self.delegate respondsToSelector:@selector(resetLoadingCount:)]) {
        [self.delegate resetLoadingCount:[[self class] loadingType]];
    }
}

#pragma mark - Private Method
- (void)p_setupUI {
    [self hideBackButton];
    self.imageView.backgroundColor = [UIColor cj_skeletonScreenColor];
    [self.contentView addSubview:self.imageView];

    CJPayMasMaker(self.imageView, {
        make.top.mas_equalTo(self.navigationBar.mas_bottom).offset(([self containerHeight] - 60) * 5 / 21); // 兼容刘海屏与非刘海屏
        make.centerX.mas_equalTo(self);
        make.size.mas_equalTo(CGSizeMake(60, 60));
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

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self p_refreshUI];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    if (_loadingWindow) {
        self.loadingWindow.hidden = YES;
        [self.loadingWindow removeFromSuperview];
        self.loadingWindow = nil;
    }
}

- (BOOL)cjNeedAnimation {
    return NO;
}

- (void)p_startLoading {
    [self.timerManager startTimer:[CJPaySettingsManager shared].currentSettings.loadingConfig.halfLoadingTimeOut ?: 16];
    [self addLoadingCount];
    [self p_push];
    [self startAnimation];
    self.view.userInteractionEnabled = NO;
}

- (void)p_stopLoading {
    [self.imageView stopAnimation];
    [self.timerManager stopTimer];
    self.view.userInteractionEnabled = YES;
    [self dismissViewControllerAnimated:NO completion:nil];
    [self resetLoadingCount];
    if (_loadingWindow) {
        self.loadingWindow.hidden = YES;
        [self.loadingWindow removeFromSuperview];
        self.loadingWindow = nil;
    }
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

- (void)p_refreshUI {
    if (self.containerHeight != self.containerView.cj_height) {
        self.view.cj_height = self.containerHeight;
        CJPayMasReMaker(self.containerView, {
            make.left.right.bottom.equalTo(self.view);
            make.height.mas_equalTo([self containerHeight]);
        });
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }
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

- (CGFloat)containerHeight {
    CGFloat height = CJ_HALF_SCREEN_HEIGHT_LOW;
    UIViewController *topVC = [UIViewController cj_topViewController];
    if ([topVC isKindOfClass:[CJPayHalfPageBaseViewController class]]) {
        CGFloat loadingShowheight = ((CJPayHalfPageBaseViewController *)topVC).loadingShowheight;
        height = loadingShowheight > CGFLOAT_MIN ? loadingShowheight : ((CJPayHalfPageBaseViewController *)topVC).containerHeight;
    }
    return height;
}

#pragma mark - Getter
- (UIView *)getLoadingView {
    return self.containerView;
}

- (NSString *)loadingTitle {
    return CJPayLocalizedStr(@"支付");
}

- (BDImageView *)imageView {
    if (!_imageView) {
        _imageView = [BDImageView new];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _imageView;
}

- (CJPayTimerManager *)timerManager {
    if (!_timerManager) {
        _timerManager = [CJPayTimerManager new];
        @CJWeakify(self)
        _timerManager.timeOutBlock = ^{
            @CJStrongify(self)
            [self stopLoading];
            NSString *viewControllerListStr = [NSString stringWithFormat:@"%@", self.topVc.navigationController.viewControllers];
            [CJMonitor trackService:@"wallet_rd_half_loading_timeout"
                           category:@{@"type": [self loadingTitle]}
                              extra:@{@"vcs": CJString(viewControllerListStr)}];
        };
    }
    return _timerManager;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
    }
    return _safeGuardTipView;
}

@end
