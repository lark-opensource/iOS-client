//
//  CAKSwipeInteractionController.m
//  CreativeAlbumKit
//
//  Created by yuanchang on 2020/12/9.
//

#import "CAKSwipeInteractionController.h"
#import "CAKStatusBarControllerUtil.h"
#import <CreativeKit/ACCMacros.h>

static UIWindow *evilWindow;

@interface CAKForcedStatusBarEvilWindow : UIWindow

@end

@implementation CAKForcedStatusBarEvilWindow

@end

@interface CAKStatusBarEvilController : UIViewController

- (instancetype)initWith:(UIViewController *)viewController;
- (void)setStatusBarHidden:(BOOL)hidden style:(UIStatusBarStyle)style;

@end

@interface CAKSwipeInteractionController (StatusBar)

- (void)lockCurrentStatusBar;
- (void)unlockCurrentStatusBar;

@end

@implementation CAKSwipeInteractionController (StatusBar)

- (void)lockCurrentStatusBar
{
     if (![CAKSwipeInteractionController viewControllerBasedStatusBarAppearanceEnabled]) {
           return;
       }
       
       if (evilWindow) {
           return;
       }
       
       evilWindow = [[CAKForcedStatusBarEvilWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
       evilWindow.userInteractionEnabled = NO;
       evilWindow.rootViewController = [CAKStatusBarEvilController new];
       evilWindow.windowLevel = UIWindowLevelAlert + 1;
       evilWindow.hidden = NO;
}

- (void)unlockCurrentStatusBar
{
     if (![CAKSwipeInteractionController viewControllerBasedStatusBarAppearanceEnabled]) {
           return;
       }
       
       NSParameterAssert(evilWindow);
       evilWindow.hidden = YES;
       evilWindow = nil;
}

+ (BOOL)viewControllerBasedStatusBarAppearanceEnabled
{
    static BOOL value;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        value = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] ?: @YES boolValue];
    });
    
    return value;
}

@end

@interface CAKEvilStatusBarInfo: NSObject

@property (nonatomic, assign) UIStatusBarStyle style;
@property (nonatomic, assign) BOOL hidden;

@end

@implementation CAKEvilStatusBarInfo

- (instancetype)initWith:(UIViewController *)viewController
{
    self = [super init];
    if (self) {
        if (viewController) {
            _hidden = [CAKStatusBarControllerUtil effectiveStatusBarControllerFrom:viewController for:CAKStatusBarControllerFindHidden].prefersStatusBarHidden;
            _style = [CAKStatusBarControllerUtil effectiveStatusBarControllerFrom:viewController for:CAKStatusBarControllerFindStyle].preferredStatusBarStyle;
        } else {
            _hidden = [CAKStatusBarControllerUtil currentStatusBarControllerForType:CAKStatusBarControllerFindHidden].cak_statusBarHidden;
            _style = [CAKStatusBarControllerUtil currentStatusBarControllerForType:CAKStatusBarControllerFindStyle].cak_statusBarStyle;
        }
    }
    return self;
}

@end

@interface CAKStatusBarEvilController ()
@property (nonatomic, strong) CAKEvilStatusBarInfo *statusBarInfo;
@end

@implementation CAKStatusBarEvilController

- (instancetype)initWith:(UIViewController *)viewController {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        CAKEvilStatusBarInfo *info = [[CAKEvilStatusBarInfo alloc] initWith:viewController];
        _statusBarInfo = info;
    }
    return self;
}

- (instancetype)init {
    return [self initWith:nil];
}

- (void)setStatusBarHidden:(BOOL)hidden style:(UIStatusBarStyle)style {
    self.statusBarInfo.hidden = hidden;
    self.statusBarInfo.style = style;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return self.statusBarInfo.style;
}

- (BOOL)prefersStatusBarHidden {
    return self.statusBarInfo.hidden;
}

@end



@interface CAKSwipeInteractionController() <UIGestureRecognizerDelegate>

@property (nonatomic, strong) id<UIViewControllerContextTransitioning> transitionContext;
@property (nonatomic, strong) UIView *toViewSnapshot;
@property (nonatomic, strong) UIView *blackMaskView;
@property (nonatomic, assign) CGRect fromVCFrame;

@end

@implementation CAKSwipeInteractionController

- (instancetype)init {
    self = [super init];
    if (self) {
        _interactionInProgress = NO;
        _shouldCompleteTransition = NO;
    }
    return self;
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    self.transitionContext = transitionContext;
    UIViewController *fromViewController = [transitionContext
                                            viewControllerForKey:UITransitionContextFromViewControllerKey
                                            ];
    self.fromVCFrame = fromViewController.view.frame;
    UIViewController *toViewController = [transitionContext
                                          viewControllerForKey:UITransitionContextToViewControllerKey];
    self.toViewSnapshot = [toViewController.view snapshotViewAfterScreenUpdates:NO];
    self.toViewSnapshot.transform = CGAffineTransformMakeScale(0.94, 0.94);
    
    [[self.transitionContext containerView] insertSubview:self.toViewSnapshot belowSubview:fromViewController.view];
    
    self.blackMaskView = [[UIView alloc] initWithFrame:[self.transitionContext containerView].bounds];
    self.blackMaskView.backgroundColor = [UIColor blackColor];
    self.blackMaskView.alpha = 0.95;
    [[self.transitionContext containerView] insertSubview:self.blackMaskView aboveSubview:self.toViewSnapshot];

    CGRect frame = [transitionContext
                    finalFrameForViewController:toViewController];
    frame.origin.y = [self _originYForViewController];
    if (frame.origin.y < 0) {
        frame.origin.y = 0;
    }
    if (![UIDevice acc_isIPhoneX]) {
        toViewController.view.frame = frame;
    }

}

- (void)wireToViewController:(UIViewController *)viewController {
    
    self.viewController = viewController;
    [self prepareGestureRecognizerInView:viewController.view];
}

- (void)prepareGestureRecognizerInView:(UIView *)view {
    
    UIPanGestureRecognizer *g = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    g.delegate = self;
    [view addGestureRecognizer:g];
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
    
    CGPoint translation = [gestureRecognizer translationInView:gestureRecognizer.view.superview];
    CGFloat progress = translation.y / gestureRecognizer.view.superview.frame.size.height;

    progress = MIN(1.0,(MAX(0.0, progress)));
    
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:
            self.interactionInProgress = YES;
            [self lockCurrentStatusBar];
            [self.viewController dismissViewControllerAnimated:YES completion:nil];
            break;
        case UIGestureRecognizerStateChanged:
            self.shouldCompleteTransition = progress > 0.5;
            [self updateInteractiveTransition:progress];
            break;
        case UIGestureRecognizerStateCancelled:
            self.interactionInProgress = NO;
            [self cancelInteractiveTransition];
            break;
        case UIGestureRecognizerStateEnded:
            if ([gestureRecognizer velocityInView:gestureRecognizer.view].y > 500) {
                self.interactionInProgress = NO;
                [self finishInteractiveTransition];
                if ([self.delegate respondsToSelector:@selector(didCompleteTransitionWithPanProgress:)]) {
                    [self.delegate didCompleteTransitionWithPanProgress:progress];
                }
            } else {
                self.interactionInProgress = NO;
                if (!self.shouldCompleteTransition) {
                    [self cancelInteractiveTransition];
                } else {
                    [self finishInteractiveTransition];
                    if ([self.delegate respondsToSelector:@selector(didCompleteTransitionWithPanProgress:)]) {
                        [self.delegate didCompleteTransitionWithPanProgress:progress];
                    }
                }
            }
            break;
        default:
            break;
    }
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    
    
    UIView *fromView = [_transitionContext viewForKey:UITransitionContextFromViewKey];
    
    CGFloat originY = [UIScreen mainScreen].bounds.size.height - fromView.bounds.size.height;
    fromView.frame = CGRectMake(0, originY + percentComplete * fromView.bounds.size.height, fromView.bounds.size.width, fromView.bounds.size.height);
    self.toViewSnapshot.transform = CGAffineTransformMakeScale((0.94 + 0.04 * percentComplete), (0.94 + 0.06 * percentComplete));
    self.blackMaskView.alpha = 0.95 * (1 - percentComplete);
    
    [self.transitionContext updateInteractiveTransition:percentComplete];
}

- (void)cancelInteractiveTransition {
    
    [UIView animateWithDuration:0.2 animations:^{
        
        UIView *fromView = [self->_transitionContext viewForKey:UITransitionContextFromViewKey];
        if (CGRectEqualToRect(self.fromVCFrame, CGRectZero)) {
            CGFloat originY = [self _originYForViewController];
            CGFloat minY = ACC_STATUS_BAR_HEIGHT;
            if (originY < minY) {
                originY = minY;
            }
            fromView.frame = CGRectMake(0, originY, fromView.bounds.size.width, fromView.bounds.size.height);
        } else {
            fromView.frame = self.fromVCFrame;
        }
        self.toViewSnapshot.transform = CGAffineTransformMakeScale(0.94, 0.94);
        self.blackMaskView.alpha = 0.95;
        
    } completion:^(BOOL finished) {
        self.fromVCFrame = CGRectZero;
        [self.transitionContext cancelInteractiveTransition];
        [self.transitionContext completeTransition:NO];
        self.transitionContext = nil;
        
        [self unlockCurrentStatusBar];
    }];
}

- (void)finishInteractiveTransition {
    
    [UIView animateWithDuration:0.2 animations:^{
        UIView *fromView = [self->_transitionContext viewForKey:UITransitionContextFromViewKey];
        CGFloat originY = [self _originYForViewController];
        fromView.frame = CGRectMake(0, originY + [UIScreen mainScreen].bounds.size.height, fromView.bounds.size.width, fromView.bounds.size.height);
        self.toViewSnapshot.transform = CGAffineTransformIdentity;
        self.blackMaskView.alpha = 0;
        
        [self unlockCurrentStatusBar];
        
    } completion:^(BOOL finished) {
        self.fromVCFrame = CGRectZero;
        [self.transitionContext finishInteractiveTransition];
        [self.transitionContext completeTransition:YES];
        UIViewController *toVC = [self.transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        self.transitionContext = nil;
        [toVC viewWillAppear:NO];
        [toVC viewDidAppear:NO];
    }];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.forbidTransitionGes) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    
    if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
        UIScrollView *scrollView = (UIScrollView *)otherGestureRecognizer.view;
        if (self.forbidSimultaneousScrollViewPanGesture) {
            return NO;
        }
        if (scrollView.contentOffset.y <= 0) {
            if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
                UIPanGestureRecognizer *panGes = (UIPanGestureRecognizer *)gestureRecognizer;
                CGPoint velocity = [panGes velocityInView:panGes.view];
                if (velocity.y > 0) {
                    scrollView.bounces = NO;
                } else {
                    scrollView.bounces = YES;
                }
            } else {
                scrollView.bounces = NO;
            }
            return YES;
        } else {
            scrollView.bounces = YES;
            return NO;
        }
    }
    return NO;
}

- (CGFloat)_originYForViewController {
    if ([UIDevice acc_isIPhoneX]) {
        return 40;
    } else {
        return ACC_STATUS_BAR_HEIGHT - ACC_STATUS_BAR_NORMAL_HEIGHT;
    }
}


@end
