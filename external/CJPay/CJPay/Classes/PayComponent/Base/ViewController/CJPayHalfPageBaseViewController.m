//
//  CJPayHalfPageBaseViewController.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/17.
//

#import "CJPayHalfPageBaseViewController.h"
#import "CJPayTransitionManager.h"
#import "CJPayUIMacro.h"
#import "UIViewController+CJTransition.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "UIViewController+CJPay.h"
#import "CJPayDataSecurityModel.h"

typedef void(^AnimationCompletionBlock)(BOOL);
CGFloat animationTime = 0.25;

@interface CJPayHalfPageBaseViewController()

@property (nonatomic, strong) UIView *backColorView;
@property (nonatomic, copy) AnimationCompletionBlock transCompletionBlock;
@property (nonatomic, assign) BOOL hasClosed;
@property (nonatomic, strong) UIImageView *loadingContainerView; // loading覆盖视图，用于解决loading消失与转场衔接问题


@end

@implementation CJPayHalfPageBaseViewController

- (CJPayNavigationController *)presentWithNavigationControllerFrom:(UIViewController *)fromVC useMask:(BOOL)useMask completion:(void (^)(void))completion {
    
    CJPayNavigationController *nav = [CJPayNavigationController instanceForRootVC:self];
    if (self.animationType != HalfVCEntranceTypeFromRight) {
        [self useCloseBackBtn];
    }
    nav.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet : UIModalPresentationCustom;
    nav.view.backgroundColor = useMask ? [UIColor cj_maskColor] : UIColor.clearColor;
    dispatch_async(dispatch_get_main_queue(), ^{
        CJPayLogInfo(@"presentViewController: fromVC = %@, newVC = %@", fromVC ? fromVC : [UIViewController cj_foundTopViewControllerFrom:fromVC], nav);
        if (fromVC) {
            [fromVC presentViewController:nav animated:self.cjNeedAnimation completion:completion];
        } else {
            [[UIViewController cj_foundTopViewControllerFrom:fromVC] presentViewController:nav animated:self.cjNeedAnimation completion:completion];
        }
    });
    return nav;
}

- (CGFloat)loadingShowheight {
    return 0.f;
}

- (CGFloat)containerHeight {
    return CJ_HALF_SCREEN_HEIGHT_LOW;
}

- (void)useCloseBackBtn {
    self.navigationBar.isCloseBackImage = YES;
    [self.navigationBar setLeftImage:[UIImage cj_imageWithName:@"cj_close_denoise_icon"]];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.exitAnimationType = HalfVCEntranceTypeNoSetting;
        self.animationType = HalfVCEntranceTypeNone;
        self.isSupportClickMaskBack = NO;
        _clipToHalfPageBounds = YES;
    }
    return self;
}

- (BOOL)cjAllowTransition {
    return NO;
}

- (BOOL)cjNeedAnimation {
    return YES;
}

- (BOOL)cjShouldShowBottomView {
    return YES;
}

- (CJPayBaseVCType)vcType {
    return CJPayBaseVCTypeHalf;
}

- (void)showMask:(BOOL)show {
    if (show) {
        self.backColorView.backgroundColor = [UIColor cj_maskColor];
    } else {
        self.backColorView.backgroundColor = UIColor.clearColor;
    }
}

- (BOOL)isShowMask {
    return [self.backColorView isShowMask];
}

- (CGFloat)maskAlpha {
    return 0.34;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.accessibilityViewIsModal = YES;
    self.navigationBar.backgroundColor = [UIColor clearColor];
    self.navigationBar.viewType = CJPayViewTypeDenoise;
    [self p_initUI];
}

- (void)p_initUI {
    if (CJ_Pad) {
        self.animationType = HalfVCEntranceTypeNone;
        self.exitAnimationType = HalfVCEntranceTypeNone;
        [self.navigationBar hideBottomLine];
        
        self.view.backgroundColor = UIColor.whiteColor;
        self.containerView.backgroundColor = UIColor.whiteColor;
        self.contentView.backgroundColor = UIColor.whiteColor;

        [self.view addSubview:self.containerView];
        [self.containerView addSubview:self.navigationBar];
        [self.containerView addSubview:self.contentView];
        CJPayMasMaker(self.containerView, {
            make.edges.equalTo(self.view);
        });
        CJPayMasMaker(self.navigationBar, {
            make.left.right.top.equalTo(self.containerView);
            make.height.mas_equalTo(60);
        });
        CJPayMasMaker(self.contentView, {
            make.left.right.equalTo(self.containerView);
            make.top.equalTo(self.navigationBar.mas_bottom);
            if (@available(iOS 11.0, *)) {
                make.bottom.equalTo(self.containerView).offset(-self.containerView.safeAreaInsets.bottom);
            } else {
                make.bottom.equalTo(self.containerView);
            }
        });
    } else {
        self.backColorView.alpha = 1;
        self.containerView.backgroundColor = UIColor.whiteColor;
        self.contentView.backgroundColor = UIColor.whiteColor;

        [self.view addSubview:self.backColorView];
        [self.view addSubview:self.containerView];
        [self.view addSubview:self.topView];

        [self.navigationBar removeStatusBarPlaceView];
        
        [self.containerView addSubview:self.navigationBar];
        [self.containerView addSubview:self.contentView];
        
        CJPayMasMaker(self.containerView, {
            make.left.right.bottom.equalTo(self.view);
            make.height.mas_equalTo([self containerHeight]);
        });
        
        CJPayMasMaker(self.navigationBar, {
            make.left.right.top.equalTo(self.containerView);
            make.height.mas_equalTo(50);
        });
        CJPayMasMaker(self.topView, {
            make.left.top.right.equalTo(self.view);
            make.bottom.equalTo(self.view).offset(-[self containerHeight]);
        });
        CJPayMasMaker(self.contentView, {
            make.left.right.bottom.equalTo(self.containerView);
            make.height.equalTo(self.containerView).offset(-50);
        });
        CJPayMasMaker(self.backColorView, {
            make.edges.equalTo(self.view);
        });
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [self.navigationBar cj_clipTopCorner:8];
    if (self.clipToHalfPageBounds) {
        [self.containerView cj_clipTopCorner:8];
    }
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    [self setNavTitle:title];
}

- (void)tapTopView {
    CJ_DelayEnableView(self.topView);
    if (self.isSupportClickMaskBack) {
        [self back];
    }
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)close {
    @CJWeakify(self)
    [self closeWithAnimation:YES comletion:^(BOOL finish) {
        @CJStrongify(self);
        CJ_CALL_BLOCK(self.closeActionCompletionBlock, finish);
    }];
}

#pragma mark 控制展示的样式
- (void)hideBackButton {
    self.navigationBar.backBtn.hidden = YES;
    self.navigationBar.userInteractionEnabled = NO;
}

- (void)showBackButton {
    self.navigationBar.backBtn.hidden = NO;
    self.navigationBar.userInteractionEnabled = YES;
}

- (void)closeWithAnimation:(BOOL)animated comletion:(nullable AnimationCompletionBlock)completion {
    self.transCompletionBlock = completion;
    if (self.hasClosed) {
        CJPayLogError(@"注意重复调用close");
        CJ_CALL_BLOCK(self.transCompletionBlock, NO);
        return;
    }
    self.hasClosed = YES;
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        [CJPayCommonUtil cj_catransactionAction:^{
            [self.navigationController popViewControllerAnimated:animated];
        } completion:^{
            CJ_CALL_BLOCK(self.transCompletionBlock, YES);
        }];
    } else {
        UIViewController *curVC = self.presentingViewController;
        BOOL needAnimated = CJ_Pad ?: animated;
        [curVC dismissViewControllerAnimated:needAnimated completion:^{
            CJ_CALL_BLOCK(self.transCompletionBlock, YES);
        }];
    }
}

- (void)addLoadingViewInTopLevel:(UIImageView *)loadingImageView {
    if (!loadingImageView) {
        return;
    }
    
    UIViewController *lastVC = self.navigationController.viewControllers.lastObject;
    if (lastVC == self && !self.loadingContainerView) {
        self.loadingContainerView = loadingImageView;
        [self.containerView addSubview:self.loadingContainerView];
        CJPayMasMaker(self.loadingContainerView, {
            make.left.right.bottom.equalTo(self.containerView);
        });
        [self.containerView setNeedsLayout];
        [self.containerView layoutIfNeeded];

        self.loadingContainerView.userInteractionEnabled = YES;        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapLoadingContainerView)];
        [self.loadingContainerView addGestureRecognizer:tapGesture];
    }
}

- (void)tapLoadingContainerView {
    __block NSString *trackNaviVCs = @"";
    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        trackNaviVCs = [trackNaviVCs stringByAppendingString:[NSString stringWithFormat:@"%@,", CJString([obj cj_trackerName])]];
    }];
    [CJTracker event:@"wallet_rd_click_halfpage_loadingContainerView"
              params:@{@"page_name": CJString([self cj_trackerName]),
                       @"navi_vcs": CJString(trackNaviVCs)
                     }];
    
    if (!self.loadingContainerView.superview) {
        return;
    }
    [self.loadingContainerView removeFromSuperview];
    self.loadingContainerView = nil;
}

- (UIColor *)getHalfPageBGColor {
    return self.contentView.backgroundColor == UIColor.clearColor ? self.containerView.backgroundColor : self.contentView.backgroundColor;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
    }
    return _containerView;
}

- (UIView *)contentView {
    if (!_contentView) {
        _contentView = [UIView new];
    }
    return _contentView;
}

- (UIView *)backColorView {
    if (!_backColorView) {
        _backColorView = [UIView new];
        _backColorView.backgroundColor = UIColor.clearColor;
        _backColorView.alpha = 0;
    }
    return _backColorView;
}

- (UIView *)topView {
    if (!_topView) {
        _topView = [[UIView alloc] init];
        _topView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapTopView)];
        tapGesture.cancelsTouchesInView = NO;
        [_topView addGestureRecognizer:tapGesture];
    }
    return _topView;
}

@end
