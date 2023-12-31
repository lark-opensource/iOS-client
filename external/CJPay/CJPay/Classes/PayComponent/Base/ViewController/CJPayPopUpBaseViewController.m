//
//  CJPayPopUpBaseViewController.m
//  Pods
//
//  Created by 尚怀军 on 2021/3/4.
//

#import "CJPayPopUpBaseViewController.h"
#import "CJPayUIMacro.h"
#import "CJPaySDKMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPayNavigationBarView.h"

@interface CJPayPopUpBaseViewController ()

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, copy) void(^completionBlock)(void);
@property (nonatomic, strong) UIView *backColorView;

@end

@implementation CJPayPopUpBaseViewController

- (CJPayNavigationController *)presentWithNavigationControllerFrom:(UIViewController *)fromVC useMask:(BOOL)useMask completion:(void (^)(void))completion {
    
    CJPayNavigationController *nav = [CJPayNavigationController instanceForRootVC:self];
    // TODO:
    //  check bottomView使用场景
    if (CJ_Pad) {
        nav.modalPresentationStyle = UIModalPresentationFormSheet;
    } else {
        nav.modalPresentationStyle = self.cjShouldShowBottomView ? UIModalPresentationOverFullScreen : UIModalPresentationFullScreen;
    }
    nav.view.backgroundColor = useMask ? [UIColor cj_maskColor] : UIColor.clearColor;
    if (useMask) {
        self.backColorView.backgroundColor = [UIColor clearColor];
    }
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

- (instancetype)init
{
    self = [super init];
    if (self) {
        _isFirstAppear = YES;
        [self showMask:YES];
    }
    return self;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (CJ_Pad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)close {
    [self dismissSelfWithCompletionBlock:nil];
}

- (void)setupUI {
    self.navigationBar.hidden = YES;
    self.containerView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.backColorView];
    [self.view addSubview:self.containerView];
    
    CJPayMasMaker(self.backColorView, {
        make.edges.equalTo(self.view);
    });
    
    CJPayMasMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
        make.height.mas_equalTo(206);
    });
}

- (void)showMask:(BOOL)show {
    self.backColorView.backgroundColor = show ? [UIColor cj_maskColor] : [UIColor clearColor];
}

- (BOOL)isShowMask {
    return [self.backColorView isShowMask];
}

- (void)dismissSelfWithCompletionBlock:(void(^)(void))completionBlock {
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        BOOL isUseTransitionCoordinator = [CJPaySettingsManager shared].currentSettings.rdOptimizationConfig.isPopupVCUseCoordinatorPop;
        if (isUseTransitionCoordinator) {
            [self.navigationController popViewControllerAnimated:YES];
            // 使用转场协调器来保证pop转场结束后再调用completionBlock，避免转场时序错乱
            if (self.transitionCoordinator) {
                [CJTracker event:@"wallet_rd_popup_dismiss" params:@{
                    @"type" : @"transitionCoordinator",
                    @"status" : @"enter"
                }];
                [self.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                    [CJTracker event:@"wallet_rd_popup_dismiss" params:@{
                        @"type": @"transitionCoordinator",
                        @"status" : @"exit"
                    }];
                    CJ_CALL_BLOCK(completionBlock);
                }];
            } else {
                [CJTracker event:@"wallet_rd_popup_dismiss" params:@{
                    @"type": @"transitionCoordinator_normal",
                    @"status" : @"exit"
                }];
                CJ_CALL_BLOCK(completionBlock);
            }
        } else {
            [CJPayCommonUtil cj_catransactionAction:^{
                [self.navigationController popViewControllerAnimated:YES];
            } completion:completionBlock];
        }
    } else {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:completionBlock];
    }
}

- (BOOL)cjShouldShowBottomView {
    return YES;
}

- (BOOL)cjNeedAnimation {
    return YES;
}

- (CJPayBaseVCType)vcType {
    return CJPayBaseVCTypePopUp;
}

- (CGFloat)maskAlpha {
    return 0.34;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.clipsToBounds = YES;
        _containerView.layer.cornerRadius = 2;
    }
    return _containerView;
}

- (UIView *)backColorView {
    if (!_backColorView) {
        _backColorView = [UIView new];
    }
    return _backColorView;
}

@end
