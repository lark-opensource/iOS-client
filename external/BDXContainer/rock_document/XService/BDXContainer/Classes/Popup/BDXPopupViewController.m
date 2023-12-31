//
//  BDXPopupViewController.m
//  BulletX-Pods-Aweme
//
//  Created by bill on 2020/9/21.
//

#import "BDXPopupViewController.h"
#import "BDXContainerUtil.h"
#import "BDXPopupContainerService.h"
#import "BDXPopupSchemaParam.h"
#import "BDXPopupViewController+Gesture.h"
#import "BDXPopupViewController+Private.h"
#import "BDXView.h"

#import <BDXBridgeKit/BDXBridgeEvent.h>
#import <BDXBridgeKit/BDXBridgeEventCenter.h>
#import <BDXServiceCenter/BDXPageContainerProtocol.h>
#import <BulletX/BulletXLog.h>

#import <ByteDanceKit/BTDResponder.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>
#import <Masonry/View+MASAdditions.h>

@interface BDXPopupViewController () <BDXContainerLifecycleProtocol>

@property(nonatomic) UIView *maskView;
@property(nonatomic) CGFloat alpha;

@property(nonatomic) BOOL destroyed;
@property(nonatomic, assign) BOOL isContainerReady;
@property(nonatomic, assign) BOOL hasExecuteOnShow;
@property(nonatomic, assign) BOOL isAppearing;

@property(nonatomic, assign) UIStatusBarStyle statusBarStyle;
@property(nonatomic, assign) UIStatusBarStyle originStatusBarStyle;

@property(nonatomic, strong) UIColor *originStatusBarBackgroundColor;
@property(nonatomic, strong) UIView *statusBarBackgroundView;

@end

@implementation BDXPopupViewController

@synthesize hybridInBackground;
@synthesize hybridAppeared;
@synthesize context;
@synthesize containerLifecycleDelegate = _containerLifecycleDelegate;

+ (UIWindow *)mainAppWindow
{
    id<UIApplicationDelegate> appDelegate = [UIApplication sharedApplication].delegate;
    if ([appDelegate respondsToSelector:@selector(window)] && appDelegate.window != nil) {
        return appDelegate.window;
    } else {
        return [UIApplication sharedApplication].keyWindow;
    }
}

+ (nullable BDXPopupViewController *)createWithConfiguration:(BDXPopupSchemaParam *)config context:(BDXContext *)context completion:(nullable void (^)(BDXPopupViewController *vc))completion
{
    UIViewController *top = nil;
    if (config.preferViewController) {
        top = config.preferViewController;
    } else {
        top = [BTDResponder topViewController];
        if (!top) {
            BulletXLog_TAG(@"BDXPopupViewController", @"showWithConfiguration, top is nil, will get new top");
            UIWindow *window = [self mainAppWindow];
            if (window.rootViewController) {
                top = [BTDResponder topViewControllerForController:window.rootViewController];
                BulletXLog_TAG(@"BDXPopupViewController", @"showWithConfiguration, top is null, did get new top = %@", top);
            } else {
                BulletXLog_TAG(@"BDXPopupViewController", @"showWithConfiguration, top is null, "
                                                          @"window.rootViewController is nil");
            }
        }
    }

    BDXPopupViewController *vc = [[self alloc] init];
    vc.context = context;
    if ([top conformsToProtocol:@protocol(BDXPageContainerProtocol)]) {
        UIViewController<BDXPageContainerProtocol> *preferBulletXVC = (UIViewController<BDXPageContainerProtocol> *)top;
        [preferBulletXVC addChildViewController:vc];
        __auto_type view = vc.view;
        view.frame = preferBulletXVC.view.bounds;
        if (!preferBulletXVC.shouldAutomaticallyForwardAppearanceMethods && preferBulletXVC.hybridAppeared) {
            [vc beginAppearanceTransition:YES animated:NO];
        }
        [preferBulletXVC.view addSubview:view];
        [vc didMoveToParentViewController:preferBulletXVC];
        if (!preferBulletXVC.shouldAutomaticallyForwardAppearanceMethods && preferBulletXVC.hybridAppeared) {
            [view layoutIfNeeded]; // use layoutIfNeeded to guarantee layout setup in
                                   // setupUI works
            [vc endAppearanceTransition];
        }
        [vc createItem:config completion:completion];

        // should disable pan gesture.
        id popGestureDelegate = preferBulletXVC.navigationController.interactivePopGestureRecognizer.delegate;
        if (popGestureDelegate) {
            UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:popGestureDelegate action:nil];
            [preferBulletXVC.view addGestureRecognizer:pan];
        }
    } else {
        __auto_type nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.navigationBarHidden = YES;
        nav.modalPresentationStyle = UIModalPresentationOverFullScreen;
        nav.modalPresentationCapturesStatusBarAppearance = YES;

        if (top.navigationController) {
            [top.navigationController presentViewController:nav animated:NO completion:^(void) {
                [vc createItem:config completion:completion];
            }];
        } else {
            [top presentViewController:nav animated:NO completion:^(void) {
                [vc createItem:config completion:completion];
            }];
        }
    }

    return vc;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.hybridAppeared = NO;
        self.hybridInBackground = NO;
    }
    return self;
}

- (BOOL)close:(nullable NSDictionary *)params
{
    return [self close:params completion:nil];
}

- (BOOL)close:(nullable NSDictionary *)params completion:(nullable dispatch_block_t)completion
{
    id<BDXPopupContainerServiceProtocol> serviceProtocal = BDXSERVICE(BDXPopupContainerServiceProtocol, nil);
    if ([serviceProtocal isKindOfClass:BDXPopupContainerService.class]) {
        BDXPopupContainerService *service = (BDXPopupContainerService *)serviceProtocal;
        return [service closePopup:self.containerID animated:YES params:params completion:completion];
    }
    return NO;
}

- (void)createItem:(BDXPopupSchemaParam *)config completion:(nullable void (^)(BDXPopupViewController *vc))completion
{
    id<BDXMonitorProtocol> lifeCycleTracker = [self.context getObjForKey:@"lifeCycleTracker"];
    [lifeCycleTracker trackLifeCycleWithEvent:@"popup_will_create_item"];

    self.config = config;
    self.isContainerReady = NO;
    self.hasExecuteOnShow = NO;
    self.isAppearing = NO;
    self.animationCompleted = NO;

    BDXView *view = [[BDXView alloc] initWithFrame:CGRectZero];
    view.bdxContentMode = BDXViewContentModeFixedSize;
    view.backgroundColor = UIColor.clearColor;
    view.containerLifecycleDelegate = self;
    [view loadWithParam:self.config context:self.context];
    self.viewContainer = view;

    [self attachToView:self.view];
    if (config.type == BDXPopupTypeDialog) {
        self.alpha = 0;
    }
    if (completion) {
        completion(self);
    }
}

- (void)sendPopupCloseEvent:(NSString *)containerID params:(NSDictionary *)params
{
    if (containerID) {
        NSMutableDictionary *eventParams = [NSMutableDictionary dictionaryWithDictionary:@{@"containerID": containerID}];
        if (params) {
            [eventParams addEntriesFromDictionary:params];
        }

        BDXBridgeEvent *event = [BDXBridgeEvent eventWithEventName:@"onPopupClose" params:[eventParams copy]];
        [[BDXBridgeEventCenter sharedCenter] publishEvent:event];
    }
}

- (void)hide
{
    self.maskView.alpha = 0;
    if (self.config.dragByGesture) {
        __auto_type targetFrame = self.viewContainer.frame;
        targetFrame.origin.y = self.initialFrame.origin.y;
        self.frame = targetFrame;
    } else {
        self.frame = self.initialFrame;
    }
    if (self.config.type == BDXPopupTypeDialog) {
        self.alpha = 0;
    }
    [self handleViewDidDisappear];
    self.isAppearing = NO;
}

- (void)show
{
    self.frame = self.finalFrame;
    self.alpha = 1;
    [self handleViewDidAppear];
    self.isAppearing = YES;
}

- (void)removeSelf:(nullable NSDictionary *)params
{
    @weakify(self);
    dispatch_block_t completionBlockWrapper = ^{
        @strongify(self);
        [self sendPopupCloseEvent:self.containerID params:params];
        __auto_type top = [BDXContainerUtil topBDXViewController];
        if (top && top.hybridAppeared && !top.hybridInBackground) {
            [top handleViewDidAppear];
        }
    };

    __auto_type nav = self.navigationController;
    if (nav.viewControllers.firstObject == self) {
        if (nav.viewControllers.count == 1) {
            [nav dismissViewControllerAnimated:NO completion:completionBlockWrapper];
        } else {
            NSMutableArray *tmpVCs = nav.viewControllers.mutableCopy;
            [tmpVCs removeObject:self];
            
            [nav setViewControllers:tmpVCs animated:NO];
        }
    } else if (nav.topViewController == self) {
        [nav popViewControllerAnimated:NO];
        completionBlockWrapper();
    } else if (self.parentViewController) {
        UIViewController<BDXPageContainerProtocol> *bulletVC = nil;
        if ([self.parentViewController conformsToProtocol:@protocol(BDXPageContainerProtocol)]) {
            bulletVC = (UIViewController<BDXPageContainerProtocol> *)self.parentViewController;
        }
        __auto_type parent = self.parentViewController;
        if (!parent.shouldAutomaticallyForwardAppearanceMethods) {
            [self beginAppearanceTransition:NO animated:NO];
        }
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        if (!parent.shouldAutomaticallyForwardAppearanceMethods) {
            [self endAppearanceTransition];
        }

        if (bulletVC) {
            id popGestureDelegate = bulletVC.navigationController.interactivePopGestureRecognizer.delegate;
            if (popGestureDelegate) {
                [bulletVC.view removeGestureRecognizer:bulletVC.view.gestureRecognizers.lastObject];
            }
        }
        completionBlockWrapper();
    } else {
        [self dismissViewControllerAnimated:NO completion:completionBlockWrapper];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initGesture];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleResignActive) name:UIApplicationWillResignActiveNotification object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleKeyboardWillShowOrChangeFrameNotification:) name:UIKeyboardWillShowNotification object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleKeyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];

    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(handleKeyboardWillShowOrChangeFrameNotification:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)handleBecomeActive
{
    BulletXLog(@"lynx_test_bullet: %@, handleBecomeActive", self.config.viewTag);
    self.hybridInBackground = NO;
    if ([BDXContainerUtil topBDXViewController] == self) {
        [self handleViewDidAppear];
    }
}

- (void)handleResignActive
{
    BulletXLog(@"lynx_test_bullet: %@, handleResignActive", self.config.viewTag);
    self.hybridInBackground = YES;
    if ([BDXContainerUtil topBDXViewController] == self) {
        [self handleViewDidDisappear];
    }
}

- (void)handleKeyboardWillShowOrChangeFrameNotification:(NSNotification *)notification
{
    if (!self.view.window) {
        return;
    }

    __auto_type request = self.config;
    __auto_type keyboardOffset = request.keyboardOffset;
    // keyboardOffset 与 BDXPopupTypeDialog 强关联
    if (request.type != BDXPopupTypeDialog || keyboardOffset == nil) {
        return;
    }

    __auto_type userInfo = notification.userInfo;
    __auto_type frame = [(NSValue *)[userInfo btd_objectForKey:UIKeyboardFrameEndUserInfoKey default:nil] CGRectValue];

    __auto_type screenHeight = CGRectGetHeight(UIScreen.mainScreen.bounds);
    if (CGRectGetMinY(frame) >= screenHeight) {
        return;
    }

    __auto_type duration = [userInfo btd_doubleValueForKey:UIKeyboardAnimationDurationUserInfoKey];
    UIViewAnimationCurve curve = [userInfo btd_integerValueForKey:UIKeyboardAnimationCurveUserInfoKey];
    __auto_type coordinateSpace = UIScreen.mainScreen.coordinateSpace;
    __auto_type frameInView = [coordinateSpace convertRect:frame toCoordinateSpace:self.view];

    __auto_type final = [self adjustedFrameWithKeyboardFrame:frameInView];

    @weakify(self);
    [UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
        @strongify(self);
        self.frame = final;
    } completion:nil];
}

- (void)handleKeyboardWillHideNotification:(NSNotification *)notification
{
    if (!self.view.window) {
        return;
    }

    __auto_type keyboardOffset = self.config.keyboardOffset;
    // keyboardOffset 与 BDXPopupTypeDialog 强关联
    if (self.config.type != BDXPopupTypeDialog || keyboardOffset == nil) {
        return;
    }

    __auto_type final = [self adjustedFrameWithKeyboardFrame:CGRectZero];

    __auto_type userInfo = notification.userInfo;
    __auto_type duration = [userInfo btd_doubleValueForKey:UIKeyboardAnimationDurationUserInfoKey];
    UIViewAnimationCurve curve = [userInfo btd_integerValueForKey:UIKeyboardAnimationCurveUserInfoKey];

    @weakify(self);
    [UIView animateWithDuration:duration delay:0 options:(curve << 16) animations:^{
        @strongify(self);
        self.frame = final;
    } completion:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    BulletXLog(@"lynx_test_bullet: %@, viewDidAppear", self.config.viewTag);
    self.hybridAppeared = YES;
    [super viewDidAppear:animated];
    self.originStatusBarStyle = [UIApplication sharedApplication].statusBarStyle;

    // handle under ios13 status bar color
    if (!@available(iOS 13.0, *)) {
        UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
        if ([statusBar respondsToSelector:@selector(backgroundColor)]) {
            self.originStatusBarBackgroundColor = [statusBar backgroundColor];
        }
    }

    [self handleViewDidAppear];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self __resetStatusBarStyle];
}

- (void)viewDidDisappear:(BOOL)animated
{
    BulletXLog(@"lynx_test_bullet: %@, viewDidDisappear", self.config.viewTag);
    self.hybridAppeared = NO;
    [super viewDidDisappear:animated];
    [self handleViewDidDisappear];
}

- (void)handleViewDidAppear
{
    if (self.isContainerReady) {
        [self.viewContainer handleViewDidAppear];
    }
    self.hasExecuteOnShow = YES;
    [self __updateStatusBarStatusWithConfig:self.config];
}

- (void)handleViewDidDisappear
{
    if (self.isContainerReady) {
        [self.viewContainer handleViewDidDisappear];
    }
}

- (void)__updateStatusBarStatusWithConfig:(BDXPopupSchemaParam *)config
{
    self.statusBarStyle = config.statusFontMode;
    [[UIApplication sharedApplication] setStatusBarStyle:self.statusBarStyle animated:YES];
    [self setNeedsStatusBarAppearanceUpdate];
    [self setStatusBarBackgroundColor:config.statusBarColor];
}

- (void)__resetStatusBarStyle
{
    // only config status bar style globaly need to reset style
    [[UIApplication sharedApplication] setStatusBarStyle:self.originStatusBarStyle animated:YES];
    if (@available(iOS 13.0, *)) {
        [self.statusBarBackgroundView removeFromSuperview];
        self.statusBarBackgroundView = nil;
    } else {
        if (self.originStatusBarBackgroundColor) {
            [self setStatusBarBackgroundColor:self.originStatusBarBackgroundColor];
        } else {
            [self setStatusBarBackgroundColor:UIColor.clearColor];
        }
    }
}

- (void)setStatusBarBackgroundColor:(UIColor *)color
{
    if (!color) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        if (!self.statusBarBackgroundView) {
            UIView *statusBar = [[UIView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.windowScene.statusBarManager.statusBarFrame];
            [[UIApplication sharedApplication].keyWindow addSubview:statusBar];
            statusBar.backgroundColor = color;
            self.statusBarBackgroundView = statusBar;
        } else {
            self.statusBarBackgroundView.backgroundColor = color;
        }
    } else {
        UIView *statusBar = [[[UIApplication sharedApplication] valueForKey:@"statusBarWindow"] valueForKey:@"statusBar"];
        if ([statusBar respondsToSelector:@selector(setBackgroundColor:)]) {
            statusBar.backgroundColor = color;
        }
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarStyle;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)allowCloseByGesture:(BOOL)allow
{
    self.config.closeByGesture = allow;
}

- (UIView *)maskView
{
    if (!_maskView) {
        UIView *mask = [UIView new];
        if (self.config.maskColorString) {
            mask.backgroundColor = [UIColor btd_colorWithHexString:self.config.maskColorString];
        } else {
            mask.backgroundColor = [UIColor clearColor];
        }
        _maskView = mask;
    }
    return _maskView;
}

- (void)attachToView:(UIView *)superview
{
    __auto_type config = self.config;
    if (self.maskView) {
        [superview addSubview:self.maskView];
        [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.maskView.superview);
        }];
    }

    if (config.closeByMask) {
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapOnMask)];
        [self.maskView addGestureRecognizer:tap];
    }

    [superview addSubview:self.viewContainer];
    [self updateLayout];
}

- (void)handleTapOnMask
{
    if (self.config.maskCanCloseUntilLoaded && !self.animationCompleted) {
        return;
    }

    if (self.config.closeByMask) {
        NSDictionary *params = @{@"reason": @(BDXPopupCloseReasonByTapMask)};
        self.userInteractionEnabled = NO;
        @weakify(self);
        [self close:params completion:^{
            @strongify(self);
            self.userInteractionEnabled = YES;
        }];
    }
}

- (void)setUserInteractionEnabled:(BOOL)enabled
{
    self.viewContainer.userInteractionEnabled = enabled;
}

- (void)setAlpha:(CGFloat)alpha
{
    _maskView.alpha = alpha;
    self.viewContainer.alpha = alpha;
}

- (NSString *)containerID
{
    if (!self.destroyed) {
        return self.viewContainer.containerID;
    }
    return nil;
}

- (BDXEngineType)viewType
{
    if (!self.destroyed) {
        return self.viewContainer.viewType;
    }
    return nil;
}

- (void)setFrame:(CGRect)frame
{
    self.viewContainer.frame = frame;
}

- (void)updateLayout
{
    UIView *superview = self.viewContainer.superview;
    __auto_type request = self.config;
    __auto_type superviewWidth = superview.bounds.size.width;
    __auto_type superviewHeight = superview.bounds.size.height;
    if (fabs(superviewWidth - 0) <= 0.001) {
        //        BulletXLog_TAG(@"BDXPopupViewController-updateLayout", @"superView's width =
        //        0，set to screen width");
        superviewWidth = [UIScreen mainScreen].bounds.size.width;
    }
    if (fabs(superviewHeight - 0) <= 0.001) {
        //        BulletXLog_TAG(@"BDXPopupViewController-updateLayout", @"superView's height
        //        = 0，set to screen height");
        superviewHeight = [UIScreen mainScreen].bounds.size.height;
    }
    __auto_type width = request.width != nil ? request.width.doubleValue : superviewWidth * request.widthPercent / 100.0;
    __auto_type height = 0;

    if (request.type == BDXPopupTypeBottomIn || request.type == BDXPopupTypeRightIn) {
        width = superviewWidth;
    }

    if (request.aspectRatio != nil) {
        height = request.aspectRatio.doubleValue * width;
    } else {
        height = request.height != nil ? request.height.doubleValue : superviewHeight * request.heightPercent / 100.0;
    }
    double dragHeight = request.dragHeight != nil ? request.dragHeight.doubleValue : superviewHeight * request.dragHeightPercent / 100.0;

    if (request.type == BDXPopupTypeBottomIn) {
        self.initialFrame = CGRectMake(0, superviewHeight, width, height);
        self.finalFrame = CGRectMake(0, superviewHeight - height, width, height);
        self.dragHeightFrame = CGRectMake(0, superviewHeight - dragHeight, width, dragHeight);
        if (dragHeight <= height) {
            self.config.dragByGesture = NO;
        }
    } else if (request.type == BDXPopupTypeRightIn) {
        __auto_type y = superviewHeight - height;
        self.initialFrame = CGRectMake(width, y, width, height);
        self.finalFrame = CGRectMake(0, y, width, height);
    } else if (request.type == BDXPopupTypeDialog) {
        __auto_type x = (superviewWidth - width) / 2.0;
        __auto_type y = 0.0;
        if (request.topOffset == nil && request.bottomOffset == nil) {
            y = (superviewHeight - height) / 2.0;
        } else if (request.topOffset != nil) {
            y = request.topOffset.doubleValue;
        } else if (request.bottomOffset != nil) {
            y = superviewHeight - request.bottomOffset.doubleValue - height;
        }
        __auto_type frame = CGRectMake(x, y, width, height);
        self.initialFrame = frame;
        self.finalFrame = frame;
    }
    //    BulletXLog_TAG(@"BDXPopupViewController-updateLayout", @"self.initialFrame is:%@,
    //    self.finalFrame is:%@", [NSValue valueWithCGRect:self.initialFrame],
    //    [NSValue valueWithCGRect:self.finalFrame]);
    self.frame = self.initialFrame;
}

- (CGRect)adjustedFrameWithKeyboardFrame:(CGRect)keyboardFrame
{
    __auto_type request = self.config;
    __auto_type keyboardOffset = request.keyboardOffset;
    __auto_type currentFrame = self.finalFrame;
    if (request.type == BDXPopupTypeDialog && keyboardOffset == nil) {
        return currentFrame;
    }

    __auto_type final = currentFrame;
    if (request.type != BDXPopupTypeDialog) {
        keyboardOffset = @0;
    }
    if (!CGRectEqualToRect(keyboardFrame, CGRectZero)) {
        final.origin.y = CGRectGetMinY(keyboardFrame) - keyboardOffset.doubleValue - CGRectGetHeight(final);
    }
    return final;
}

- (void)destroy
{
    [self.viewContainer removeFromSuperview];
    [_maskView removeFromSuperview];
    self.viewContainer = nil;
    self.destroyed = YES;
}

- (void)load
{
    [self.viewContainer loadWithParam:self.config context:self.context];
}

- (void)reloadWithContext:(BDXContext *)context
{
    [self.viewContainer reloadWithContext:context];
}

- (void)container:(id<BDXContainerProtocol>)container didFinishLoadWithURL:(NSString *_Nullable)url
{
    self.isContainerReady = true;
    if (self.hasExecuteOnShow && !self.hybridInBackground) {
        [self handleViewDidAppear];
    }
}

- (void)container:(id<BDXContainerProtocol>)container didChangeIntrinsicContentSize:(CGSize)size
{
    // 这个时候contentview(lynxview/webview)才layout完成，这个时候去设置下圆角
    if (self.config.radius) {
        UIView *view = self.viewContainer.kitView;
        if (view) {
            double radius = self.config.radius.doubleValue;
            UIRectCorner corner = self.config.type == BDXPopupTypeDialog ? UIRectCornerAllCorners : UIRectCornerTopLeft | UIRectCornerTopRight;
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
            CAShapeLayer *layer = [[CAShapeLayer alloc] init];
            layer.frame = view.bounds;
            layer.path = path.CGPath;
            view.layer.mask = layer;
        }
    }
}

- (id<BDXMonitorProtocol>)lifeCycleTracker
{
    id<BDXMonitorProtocol> lifeCycleTracker = [self.context getObjForKey:@"lifeCycleTracker"];
    if (!lifeCycleTracker) {
        // every bdxview has its own tracker , thus init tracker manually.
        Class monitorClass = BDXSERVICE_CLASS(BDXMonitorProtocol, nil);
        lifeCycleTracker = [[monitorClass alloc] init];
        [self.context registerStrongObj:lifeCycleTracker forKey:@"lifeCycleTracker"];
    }

    return lifeCycleTracker;
}

- (void)resize:(CGRect)frame
{
    self.frame = frame;
    [self.viewContainer layoutSubviews];
}

- (void)resizeWithAnimation:(CGRect)frame completion:(nullable dispatch_block_t)completion
{
    [UIView animateWithDuration:.3 animations:^{
        [self resize:frame];
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

@end
