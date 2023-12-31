//
//  OPAlertContainerController.m
//  EEMicroAppSDK
//
//  Created by yi on 2021/3/19.
//

#import "OPAlertContainerController.h"
#import <objc/runtime.h>

@interface UIView (OPAlertContainerController)

@property (nonatomic, assign) UIEdgeInsets opa_viewEdgeInsets;

@property (nonatomic, strong, getter=superview) UIView *opa_bindSuperview;

@end

@implementation UIView (OPAlertContainerController)

- (void)setOpa_viewEdgeInsets:(UIEdgeInsets)opa_viewEdgeInsets {
    objc_setAssociatedObject(self, @selector(opa_viewEdgeInsets), [NSValue valueWithUIEdgeInsets:opa_viewEdgeInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)opa_viewEdgeInsets {
    NSValue *value = objc_getAssociatedObject(self, @selector(opa_viewEdgeInsets));
    return value ? value.UIEdgeInsetsValue : UIEdgeInsetsZero;
}

- (void)setOpa_bindSuperview:(UIView *)bindSuperview {
    if ([bindSuperview isKindOfClass:UIView.class] && self.superview != bindSuperview) {
        [self removeFromSuperview];
        [bindSuperview addSubview:self];
    }
}

@end

@interface OPAlertContainerController ()
@property (nonatomic, strong, readwrite) UIView *containerBackgroundView;
@property (nonatomic, assign, readwrite) BOOL appeared;
@property (nonatomic, assign) CGFloat alertWidth;    // AlertView 宽度
@property (nonatomic, assign) CGFloat alertHeight;   // AlertView 宽度
@property (nonatomic, copy) void (^doPresentAnimation)(OPAlertContainerController *alert, void(^completion)(BOOL finished));   // 自定义入场动画，动画完成后调用completion
@property (nonatomic, copy) void (^doDismissAnimation)(OPAlertContainerController *alert, void(^completion)(BOOL finished));   // 自定义出场动画，动画完成后调用completion
@property (nonatomic, strong, readwrite) UIView *containerView;
@property (nonatomic, strong, readwrite) UIView<OPAlertContentViewProtocol> *alertView;

@end

@implementation OPAlertContainerController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.modalPresentationStyle = UIModalPresentationCustom;
        self.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [self setupViews];
        [self setupAnimations];
    }
    return self;
}

- (void)setupViews {
    self.containerView = [[UIControl alloc] init];
    [(UIControl *)self.containerView addTarget:self action:@selector(onBackgroundTap) forControlEvents:UIControlEventTouchUpInside];

    self.containerBackgroundView = [[UIView alloc] init];
    self.containerBackgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:76.f/255.f];
}

- (void)setupAnimations {
    self.doPresentAnimation = ^(OPAlertContainerController *alert, void (^completion)(BOOL finished)) {
        alert.containerBackgroundView.alpha = 0;
        alert.containerView.alpha = 0;

        alert.containerView.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
        [UIView animateWithDuration:0.2 animations:^{
            alert.containerBackgroundView.alpha = 1;
            alert.containerView.alpha = 1;
            alert.containerView.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (completion) {
                completion(finished);
            }
        }];
    };

    self.doDismissAnimation = ^(OPAlertContainerController *alert, void (^completion)(BOOL finished)) {
        [UIView animateWithDuration:0.2 animations:^{
            alert.containerBackgroundView.alpha = 0;
            alert.containerView.alpha = 0;
        } completion:^(BOOL finished) {
            alert.containerBackgroundView.alpha = 1;
            alert.containerView.alpha = 1;
            alert.containerView.transform = CGAffineTransformIdentity;
            if (completion) {
                completion(finished);
            }
        }];
    };

}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGRect frame = self.view.frame;
    self.view.frame = CGRectMake(frame.origin.x, frame.origin.y, CGSizeZero.width, CGSizeZero.height);
    self.view.backgroundColor = [UIColor clearColor];
}

- (BOOL)shouldAutorotate {
    return NO;     // 禁止屏幕旋转
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self showInWindow:self.appeared?NO:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeFromWindow:animated];

}

// 适配iPad分屏/转屏，在viewWillTransitionToSize中刷新布局
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateView];
    } completion:nil];
}

#pragma mark - Events

- (void)onBackgroundTap {
    [self dismissViewController];
    [self.containerView.window endEditing:YES];
    if (self.tapBackgroud) {
        self.tapBackgroud();
    }
}

- (void)showInWindow:(BOOL)animated {
    [self buildViewHierarchy];
    [self updateView];

    if (animated && self.doPresentAnimation) {
        self.doPresentAnimation(self, ^(BOOL finished) {
        });
    }

    self.containerView.accessibilityViewIsModal = YES;
    if(self.canBecomeFirstResponder) [self becomeFirstResponder];
    self.appeared = YES;
}

- (void)removeFromWindow:(BOOL)animated {
    [self.containerView.window endEditing:YES];     // Deal with the warning: rejected resignFirstResponder when being removed from hierarchy
    if (animated && self.doDismissAnimation) {
        self.doDismissAnimation(self, ^(BOOL finished) {
            [self.containerView removeFromSuperview];
            [self.containerBackgroundView removeFromSuperview];
        });
    }else {
        [self.containerView removeFromSuperview];
        [self.containerBackgroundView removeFromSuperview];
    }
}

- (void)dismissViewController {
    [self dismissViewControllerWithAnimated:YES completion:nil];
}

- (void)dismissViewControllerWithAnimated: (BOOL)animated completion: (void (^ __nullable)(void))completion {
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:animated completion:completion];
    }else {
        if (self.navigationController) {
            NSMutableArray *childViewControllers = self.navigationController.childViewControllers.mutableCopy;
            [childViewControllers removeObject:self];
            [self.navigationController setViewControllers:childViewControllers animated:animated];
        }else {
            [self willMoveToParentViewController:nil];
            [self.view removeFromSuperview];
            [self removeFromParentViewController];
        }
        if (completion) {
            completion();
        }
    }
}

- (void)buildViewHierarchy {
    UIWindow *targetWindow = self.presentingViewController.view.window;
    self.containerBackgroundView.opa_bindSuperview = targetWindow;
    self.alertView.opa_bindSuperview = self.containerView;

    self.containerView.opa_bindSuperview = targetWindow;
    [targetWindow bringSubviewToFront:self.containerView];
}

- (void)updateView {
    self.containerView.frame = self.containerView.superview.bounds;
    self.containerBackgroundView.frame = self.containerView.frame;

    UIEdgeInsets layoutInsets = self.containerView.window.safeAreaInsets;
    CGPoint point = CGPointMake((self.containerView.frame.size.width - self.alertWidth) / 2, layoutInsets.top + (self.containerView.frame.size.height - layoutInsets.top - layoutInsets.bottom - self.alertHeight)/2);

    CGRect frame = self.alertView.frame;
    frame.size = CGSizeMake(self.alertWidth, self.alertHeight);
    frame.origin = point;
    self.alertView.frame = frame;

    [self.alertView showAlertInView:self.alertView.superview?:self.containerView];
}

- (void)updateAlertView:(UIView<OPAlertContentViewProtocol> *)view size:(CGSize)size
{
    self.alertView = view;
    self.alertWidth = size.width;
    self.alertHeight = size.height;
    self.alertView.layer.cornerRadius = 8;
    self.alertView.layer.masksToBounds = YES;

}

#pragma mark - Utils

- (void)setContainerBackgroundView:(UIView *)containerBackgroundView {
    if (_containerBackgroundView != containerBackgroundView) {
        [_containerBackgroundView removeFromSuperview];
        _containerBackgroundView = containerBackgroundView;
    }
}

@end
