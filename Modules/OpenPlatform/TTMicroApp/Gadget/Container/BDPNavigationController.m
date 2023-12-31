//
//  BDPNavigationController.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/16.
//

#import "BDPAppContainerController.h"
#import "BDPAppPage.h"
#import "BDPAppPageAnimatedTransitioning.h"
#import "BDPAppPageController.h"
#import "BDPAppRouteManager.h"
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPDeviceManager.h>
#import "BDPNavigationController.h"
#import <OPFoundation/BDPResponderHelper.h>
#import "BDPTaskManager.h"
#import <OPFoundation/BDPUtils.h>
#import "BDPWebViewComponent.h"

#import "BDPAppPage+BDPNavBarAutoChange.h"
#import <OPFoundation/NSObject+BDPExtension.h>
#import <OPFoundation/UIImage+BDPExtension.h>
#import "UINavigationBar+Navigation.h"
#import <OPFoundation/UIView+BDPExtension.h>
#import <OPFoundation/UIView+BDPLayout.h>
#import "UIViewController+Navigation.h"
#import <ECOInfra/NSString+BDPExtension.h>
#import <Masonry/Masonry.h>

#import <OPSDK/OPSDK-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/EEFeatureGating.h>
#import <OPFoundation/BDPMonitorEvent.h>
#import "BDPXScreenManager.h"

static const CGFloat kTitleViewLoadingSize = 16;
static const CGFloat kTitleViewLoadingSpacing = 8;
static const CGFloat kTitleViewMaxWidth = 160;
static const CGFloat kNavHomeButtonLeftSpacing = 10;
static const CGFloat kTitleFontSize = 17;
static NSString *const kTitleViewLoadingAnimationKey = @"BDPNavigationTitleViewLoading";

// 导航栏自定义titleView中的子组件，所对应的tag
typedef NS_ENUM(NSInteger, BDPNavTitleViewSubTag) {
    BDPNavTitleViewTagLoadingParent = 1000, // Loading动画的父UIView
    BDPNavTitleViewTagLoading, // Loaidng动画
    BDPNavTitleViewTagTitle, // 标题对应的UIView
};

// 导航栏UIBarButtonItem，所对应的tag
typedef NS_ENUM(NSInteger, BDPNavBarButtonTag) {
    BDPNavBarButtonTagHome = 1000, // 返回首页按钮
};

@interface BDPNavigationController () <UINavigationControllerDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL isPopGestureEnabled;
@property (nonatomic, strong) BDPAppPageAnimatedTransitioning *transitioning;
@property (nonatomic, strong) UIPercentDrivenInteractiveTransition *interactive;

@property (nonatomic, weak, nullable) OPContainerContext *containerContext;

@property (nonatomic, strong) UIColor *systemBackgroundColor;

@end

@implementation BDPNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
                       barBackgroundHidden:(BOOL)barBackgroundHidden
                          containerContext:(OPContainerContext *)containerContext
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.delegate = self;
        self.isPopGestureEnabled = YES;
        self.containerContext = containerContext;
        // 在导航栏不透明的情况下隐藏导航栏背景
        self.navigationBar.shadowImage = [UIImage new];
        self.navigationBar.translucent = NO;
        self.barBackgroundHidden = barBackgroundHidden;
        if (barBackgroundHidden) {
            rootViewController.bdp_shouldFakeNavigationBarBG = YES;
        }
        
        [self setupObserver];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    return [self initWithRootViewController:rootViewController barBackgroundHidden:NO containerContext:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.systemBackgroundColor = self.view.backgroundColor;
    
    // BugFix - 兼容抖音对导航栏 Hook 导致的导航栏背景色设置失效
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([BDPXScreenManager isXScreenMode:self.containerContext.uniqueID]) {
        self.view.backgroundColor = [UIColor clearColor];
    } else {
        self.view.backgroundColor = self.systemBackgroundColor;
    }
    
    [self refreshOrientation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // BugFix - 兼容抖音对导航栏 Hook 导致的侧滑返回 Bug，确保滑动返回手势不会被覆盖
    // 抖音强制对所有 [UINavigationController* DidAppear] 进行了 Hook，增加了自己的手势，导致边缘滑动返回手势会失效
    if (self.view.gestureRecognizers.count > 1) {
        [self.view.gestureRecognizers.lastObject requireGestureRecognizerToFail:self.view.gestureRecognizers.firstObject];
    }
}

- (void)dealloc
{
    BDPDebugNSLog(@"BDPNavigationController dealloc");
    //下面的宏是将一个数组中的对象，分散到主线程的runloop中进行释放，避免集中释放造成卡顿
    NSArray<UIViewController *> *vcs = [self viewControllers];
    RELEASE_ARRAY_ELEMENTS_SEPARATE_MAIN_THREADS_DELAY_SECS(vcs, 0.2);
}

- (BDPAppPageAnimatedTransitioning *)transitioning
{
    if (!_transitioning) {
        _transitioning = [[BDPAppPageAnimatedTransitioning alloc] init];
    }
    return _transitioning;
}

- (void)useCustomAnimation
{
    [self.interactivePopGestureRecognizer removeTarget:nil action:NULL]; // remove all target
    [self.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopGestureRecognizer:)];
}


#pragma mark - Notification Observer
/*-----------------------------------------------*/
//         Notification Observer - 通知
/*-----------------------------------------------*/
- (void)setupObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(UIWindowHidden:)
                                                 name:UIWindowDidBecomeHiddenNotification
                                               object:nil];
    
}

- (void)UIWindowHidden:(NSNotification *)notification
{
    [[UIApplication sharedApplication] setStatusBarHidden:[self prefersStatusBarHidden] withAnimation:[self preferredStatusBarUpdateAnimation]];
    [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle] animated:[self preferredStatusBarUpdateAnimation]];
}

#pragma mark - Navigation Route
/*------------------------------------------*/
//          Navigation Route - 路由
/*------------------------------------------*/

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self __pushViewController:viewController animated:animated needAppRoute:animated];
}

- (void)pushViewControllerWithAppRoute:(UIViewController *)viewController animated:(BOOL)animated
{
    // 这个方法目前没有地方使用，因为加了 popViewControllerWithAppRouteAnimated 这个方法，也就对应的添加一个push方法。
    [self __pushViewController:viewController animated:animated needAppRoute:YES];
}

- (void)__pushViewController:(UIViewController *)viewController animated:(BOOL)animated needAppRoute:(BOOL)appRoute
{
    //push twice with the same viewcontroller is forbidden. http://t.wtturl.cn/eq2reQC/
    if (self.topViewController == viewController) {
        NSString * errorLog  = [NSString stringWithFormat:@"push same viewController instance will throw NSException:%@", viewController];
        NSAssert(self.topViewController != viewController, errorLog);
        BDPLogError(errorLog);
        return;
    }
    [super pushViewController:viewController animated:animated];
    if (![viewController isKindOfClass:[BDPAppPageController class]] || ([viewController isKindOfClass:[BDPAppPageController class]] && appRoute)) {
        if (self.navigationRouteDelegate && [self.navigationRouteDelegate respondsToSelector:@selector(navigation:didPushViewController:)]) {
            [self.navigationRouteDelegate navigation:self didPushViewController:viewController];
        }
    }
    if (self.barBackgroundHidden) {
        viewController.bdp_shouldFakeNavigationBarBG = YES;
    }
}

- (void)setViewControllers:(NSArray<UIViewController *> *)viewControllers animated:(BOOL)animated
{
    [super setViewControllers:viewControllers animated:animated];
    if (self.barBackgroundHidden) {
        for (UIViewController *vc in viewControllers) {
            vc.bdp_shouldFakeNavigationBarBG = YES;
        }
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    return [self __popViewControllerAnimated:animated needAppRoute:animated];
}

- (UIViewController *)popViewControllerWithAppRouteAnimated:(BOOL)animated
{
    // 之所以会添加一个这个强制发送AppRoute的消息方法，是因为调试发现 并不是所有的系统pop方法都需要发送AppRoute
    // 从关于，设置等界面返回时，系统的Transitioning动画 可能是为了解决某些恶心的问题，会先把q当前界面pop 在立刻 push出来，肉眼是看不到的。
    // 我在做动画的时候也遇到了类似恶心的问题。也是使用相同方法解决 @see BDPTabBarPageControoler viewWillAppear:
    return [self __popViewControllerAnimated:animated needAppRoute:YES];
}

- (UIViewController *)__popViewControllerAnimated:(BOOL)animated needAppRoute:(BOOL)appRoute
{
    UIViewController *destVC = self.viewControllers[MAX((NSInteger)self.viewControllers.count - 2, 0)];
    UIViewController *popVC = [super popViewControllerAnimated:animated];
    if ((popVC && ![popVC isKindOfClass:[BDPAppPageController class]]) || ([popVC isKindOfClass:[BDPAppPageController class]] && appRoute)) {
        // 手势返回也会触发PopViewControllerAnimated，非手势返回走如下方法，手势真正返回则会走interactionGesturePopViewController
        if (!self.topViewController.transitionCoordinator.isInteractive) {
            if (self.navigationRouteDelegate && [self.navigationRouteDelegate respondsToSelector:@selector(navigation:didPopViewController:willShowViewController:)]) {
                [self.navigationRouteDelegate navigation:self didPopViewController:@[popVC] willShowViewController:destVC];
            }
        }
    };
    return popVC;
}

- (NSArray<UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSArray<UIViewController *> *popVCs = [super popToViewController:viewController animated:animated];
    if (self.navigationRouteDelegate && [self.navigationRouteDelegate respondsToSelector:@selector(navigation:didPopViewController:willShowViewController:)]) {
        [self.navigationRouteDelegate navigation:self didPopViewController:popVCs willShowViewController:viewController];
    }
    return popVCs;
}

- (NSArray<UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated
{
    UIViewController *destVC = self.viewControllers.firstObject;
    NSArray<UIViewController *> *popVCs = [super popToRootViewControllerAnimated:animated];
    if (animated) {
        if (self.navigationRouteDelegate && [self.navigationRouteDelegate respondsToSelector:@selector(navigation:didPopViewController:willShowViewController:)]) {
            [self.navigationRouteDelegate navigation:self didPopViewController:popVCs willShowViewController:destVC];
        }        
    }
    return popVCs;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // 导航栏处理
    self.navigationBar.translucent = NO;
    if (self.barBackgroundHidden) {
        viewController.bdp_shouldFakeNavigationBarBG = YES;
    }

    // 状态栏处理
    [self updateStatusBarStyle:animated];
    [self updateStatusBarHidden:animated];
    [self setNeedsStatusBarAppearanceUpdate];
    
    // 手势滑动处理
    [self interactionGesturePopViewController:navigationController willShowViewController:viewController];
    
    // 非手势展示时处理转屏
    if (!self.topViewController.transitionCoordinator.isInteractive) {
        [self refreshOrientation];
    }
}

- (void)interactionGesturePopViewController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController
{
    // 手势返回触发navigationPopViewController事件
    // iOS9内存泄漏问题 - notifyWhenInteractionEndsUsingBlock会持有内部变量，需要__weak处理
    id<UIViewControllerTransitionCoordinator> coordinator = navigationController.topViewController.transitionCoordinator;
    __weak UIViewController *willShowViewController = [coordinator viewControllerForKey:UITransitionContextToViewControllerKey];
    __weak UIViewController *willPopViewController = [coordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
    __weak UIViewController *currentViewController = viewController;
    
    WeakSelf;
    void (^handler)(id<UIViewControllerTransitionCoordinatorContext> context) = ^(id<UIViewControllerTransitionCoordinatorContext> context) {
        // 手势取消则不做处理
        if ([context isCancelled]) {
            return;
        }
        if (willShowViewController == currentViewController) {
            StrongSelfIfNilReturn;
            [self refreshOrientation];
            if (self.navigationRouteDelegate && [self.navigationRouteDelegate respondsToSelector:@selector(navigation:didPopViewController:willShowViewController:)]) {
                [self.navigationRouteDelegate navigation:self didPopViewController:@[willPopViewController] willShowViewController:willShowViewController];
            }
        }
    };
    
    [coordinator notifyWhenInteractionChangesUsingBlock:handler];
}

#pragma mark - Navigation Gesture

- (void)setNavigationPopGestureEnabled:(BOOL)enabled
{
    self.isPopGestureEnabled = enabled;
}

/// 自定义的返回手势。
- (void)handlePopGestureRecognizer:(UIScreenEdgePanGestureRecognizer *)gesture
{
    CGFloat progress = [gesture translationInView:self.view].x / self.view.bounds.size.width;
    progress = MIN(1.0, MAX(0.0, progress));//把这个百分比限制在0~1之间
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan:
            self.interactive = [[UIPercentDrivenInteractiveTransition alloc] init];
            [self popViewControllerAnimated:YES];
            break;
        case UIGestureRecognizerStateChanged:
        {
            [self.interactive updateInteractiveTransition:progress];
            break;
        }
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGFloat velocity = [gesture velocityInView:self.view].x;
            if (progress > 0.25 || velocity >= 80) {
                [self.interactive finishInteractiveTransition];
            } else {
                [self.interactive cancelInteractiveTransition];
            }
            self.interactive = nil;
        }
        default:
            break;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    [self.topViewController.view endEditing:YES];
    // 判断导航控制器不能响应左滑返回事件的条件：
    // 1) 子视图控制器个数<=1
    // 2) 最上面视图控制器中webView支持手势返回。避免webview组件非首页横滑返回会退出小程序的问题
    if (self.viewControllers.count <= 1 || [self canGoBackForWebView]) {
        return NO;
    }
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return gestureRecognizer == self.interactivePopGestureRecognizer;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer
{
    UIView *superView = otherGestureRecognizer.view.superview;
    while (superView) {
        if ([superView isKindOfClass:[WKWebView class]]) {
            static NSString *className = nil;
            if (!className) {
                // private class UIWebTouchEventsGestureRecognizer
                className = @"UIWebTouchEventsGestureRecognizer";//[NSString bdp_stringFromBase64String:@"VUlXZWJUb3VjaEV2ZW50c0dlc3R1cmVSZWNvZ25pemVy"];
            }
            if ([NSStringFromClass(otherGestureRecognizer.class) isEqualToString:className]) {
                return YES;
            }
            break;
        }
        superView = superView.superview;
    }

    return NO;
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    // 状态栏需要在DidShowVC里重置，才能保证设置成功
    // DidShow改变状态栏样式动画必须设置为NO，避免系统重置样式与设置样式冲突导致的闪烁
    [self updateStatusBarStyle:NO];
    
    self.interactivePopGestureRecognizer.delaysTouchesBegan = YES;
    self.interactivePopGestureRecognizer.delegate = self;
    self.interactivePopGestureRecognizer.enabled = self.isPopGestureEnabled;

    if ([viewController isKindOfClass:[BDPAppPageController class]]) {
        BDPAppPageController *vc = (BDPAppPageController *)viewController;
        __weak typeof(vc) weakVC = vc;
        vc.canGoBackChangedBlock = ^(BOOL canGoBack) {
            __strong typeof(weakVC) vc = weakVC;
            // 跳转h5页面后，如果发生了h5页面切换，则显示返回按钮
            [vc updateViewControllerStyle:NO];
        };
    }
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    return self.interactive;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC
{
    if ([fromVC isKindOfClass:[BDPAppPageController class]] && [toVC isKindOfClass:[BDPAppPageController class]]) {
        // 小程序 app page之间的跳转使用自定义的动画， 其他情况用默认的。
        self.transitioning.operation = operation;
        return self.transitioning;
    }
    return nil;
}

#pragma mark - NavigationBar Style
/*------------------------------------------*/
//       NavigationBar Style - 导航栏
/*------------------------------------------*/
- (void)setNavigationBarHidden:(BOOL)navigationBarHidden
{
    if(self.containerContext && self.containerContext.apprearenceConfig.forceNavigationBarHidden) {
        // 适配强制无导航模式，强制隐藏导航栏，任何条件都不允许开启
        [super setNavigationBarHidden:YES];
    } else {
        [super setNavigationBarHidden:navigationBarHidden];
    }
    self.navigationBar.translucent = NO;
}

- (void)setNavigationBarHidden:(BOOL)hidden animated:(BOOL)animated
{
    if(self.containerContext && self.containerContext.apprearenceConfig.forceNavigationBarHidden) {
        // 适配强制无导航模式，强制隐藏导航栏，任何条件都不允许开启
        [super setNavigationBarHidden:YES animated:animated];
    } else {
        [super setNavigationBarHidden:hidden animated:animated];
    }
    self.navigationBar.translucent = NO;
}

- (void)setNavigationBarBackgroundColor:(UIColor *)color
{
    self.navigationBar.barTintColor = color;
}

- (void)setNavigationBarTitleTextAttributes:(NSDictionary<NSAttributedStringKey, id> *)titleTextAttributes viewController:(UIViewController *)viewController;
{
    UIView *titleView = viewController.navigationItem.titleView;
    BDPNavigationTitleLabel *titleLabel = [viewController.navigationItem.titleView viewWithTag:BDPNavTitleViewTagTitle];
    NSMutableAttributedString *copyTitle = [[NSMutableAttributedString alloc] initWithAttributedString:titleLabel.attributedText];
    [copyTitle setAttributes:titleTextAttributes
                       range:(NSRange){0, titleLabel.attributedText.length}];
    
    // 标题宽度通过boundingRect计算，为了让计算值准确，需添加一个默认字体属性
    // 默认字体与系统title对齐
    if (![titleTextAttributes objectForKey:NSFontAttributeName]) {
        [copyTitle addAttribute:NSFontAttributeName
                          value:[UIFont boldSystemFontOfSize:kTitleFontSize]
                          range:(NSRange){0, titleLabel.attributedText.length}];
    }
    
    titleLabel.attributedText = copyTitle;
    [titleLabel adjustLabelSize:[self getMaxLabelWidthForVC:viewController]];
    titleView.bdp_width = titleLabel.bdp_width;
}

- (void)setBarBackgroundHidden:(BOOL)barBackgroundHidden
{
    _barBackgroundHidden = barBackgroundHidden;
    UIView *bg = [self.navigationBar bdp_getBackgroundView];
    bg.hidden = barBackgroundHidden;
}

/// 显示或隐藏导航栏的loading载入动画，默认隐藏
/// @param showed 是否展示loading
/// @param viewController NavigationBar相对应的VC
- (void)setNavigationBarLoading:(BOOL)showed viewController:(UIViewController *)viewController
{
    UIView *titleView = viewController.navigationItem.titleView;
    UIView *loadingParentView = [titleView viewWithTag:BDPNavTitleViewTagLoadingParent];
    UIImageView *loadingView = [loadingParentView viewWithTag:BDPNavTitleViewTagLoading];
    
    /// loadingView不存在，需要实例化
    if (!loadingView) {
        if (!showed) {  // 不展示loading，符合预期，无需操作
            return;
        }
        // loading图标颜色与工具栏颜色对齐
        BDPAppPageController *appVC = (BDPAppPageController*)viewController;
        BOOL reverse = [appVC.appPage bap_navBarItemColorShouldReverse];
        NSString *textStyle = [appVC.pageConfig.window navigationBarTextStyleWithReverse:reverse];
        BDPToolBarViewStyle toolBarStyle = [textStyle isEqualToString:@"black"] ? BDPToolBarViewStyleLight : BDPToolBarViewStyleDark;
        if (self.containerContext.uniqueID.isAppSupportDarkMode) {
            if ([textStyle isEqualToString:@"black"]) {
                toolBarStyle = BDPToolBarViewStyleLight;
            } else if ([textStyle isEqualToString:@"white"]) {
                toolBarStyle = BDPToolBarViewStyleDark;
            } else {
                // 缺省颜色按照 Light Mode
                toolBarStyle = BDPToolBarViewStyleLight;
            }
        }
        NSString *imageName = (toolBarStyle == BDPToolBarViewStyleLight) ? @"icon_navigation_loading_black" : @"icon_navigation_loading_white";
        
        loadingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil]];
        [loadingParentView addSubview:loadingView];
        [loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(loadingParentView);
            make.trailing.mas_equalTo(loadingParentView);
            make.size.mas_equalTo(CGSizeMake(kTitleViewLoadingSize, kTitleViewLoadingSize));
        }];
        loadingView.hidden = YES;
        loadingView.tag = BDPNavTitleViewTagLoading;
    }
    /// 显示loading且没有loading正在显示，则需要显示loading
    if (showed && ![loadingView.layer animationForKey:kTitleViewLoadingAnimationKey]) {
        loadingView.hidden = NO;
        [self setLoadingAnimationRotation:loadingView];
    } else if (!showed) {   // 不显示loading
        loadingView.hidden = YES;
        [loadingView.layer removeAllAnimations];
    } else {    // 显示loading且loading正在展示，符合预期，无需操作
        return;
    }
}

- (void)setLoadingAnimationRotation:(UIImageView *)loadingView
{
    CABasicAnimation *rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = [NSNumber numberWithFloat:0];
    rotation.toValue = [NSNumber numberWithFloat:(2 * M_PI)];
    rotation.duration = 1.0f;
    rotation.repeatCount = HUGE_VALF;
    [loadingView.layer removeAllAnimations];
    loadingView.layer.shouldRasterize = YES;
    loadingView.layer.allowsEdgeAntialiasing = YES;
    [loadingView.layer addAnimation:rotation forKey:kTitleViewLoadingAnimationKey];
}

#pragma mark - NavigationBar Item
/*------------------------------------------*/
//      NavigationBar Item - 导航栏组件
/*------------------------------------------*/
- (void)initNavigationTitleView:(UIViewController *)viewController
{
    // 标题对应的UIView
    BDPNavigationTitleLabel *titleLabel = [[BDPNavigationTitleLabel alloc] init];
    titleLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:@"default"
                                                                       attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:kTitleFontSize]}];
    [titleLabel adjustLabelSize:[self getMaxLabelWidthForVC:viewController]];
    titleLabel.tag = BDPNavTitleViewTagTitle;
    
    // loadingParentView
    CGFloat loadingSpacingWidth = kTitleViewLoadingSize + kTitleViewLoadingSpacing;
    UIView *loadingParentView = [[UIView alloc] initWithFrame:CGRectMake(-loadingSpacingWidth, 0, kTitleViewLoadingSize, titleLabel.bdp_height)];
    loadingParentView.tag = BDPNavTitleViewTagLoadingParent;
    
    // titleView
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, titleLabel.bdp_width, titleLabel.bdp_height)];
    [titleView addSubview:loadingParentView];
    [titleView addSubview:titleLabel];

    viewController.navigationItem.titleView = titleView;
}

- (void)setNavigationItemTitle:(NSString *)title viewController:(UIViewController *)viewController
{
    if (!viewController.navigationItem.titleView) {
        [self initNavigationTitleView:viewController];
    }
    
    UIView *titleView = viewController.navigationItem.titleView;
    BDPNavigationTitleLabel *titleLabel = [titleView viewWithTag:BDPNavTitleViewTagTitle];
    NSMutableAttributedString *copyTitle = [titleLabel.attributedText mutableCopy];
    // 一定要设置带长度的字符串，否则copyTitle会转为空object，丢失字体属性
    [copyTitle.mutableString setString:(title.length > 0) ? title : @" "];
    titleLabel.attributedText = copyTitle;
    [titleLabel adjustLabelSize:[self getMaxLabelWidthForVC:viewController]];
    titleView.bdp_width = titleLabel.bdp_width;
    
    // 如果导航栏中的载入图标未隐藏且未旋转，则重设旋转动画
    UIView *loadingParentView = [viewController.navigationItem.titleView viewWithTag:BDPNavTitleViewTagLoadingParent];
    UIImageView *loading = [loadingParentView viewWithTag:BDPNavTitleViewTagLoading];
    if (!loading.hidden && ![loading.layer animationForKey:kTitleViewLoadingAnimationKey]) {
        [self setLoadingAnimationRotation:loading];
    }
}

- (void)setNavigationItemTintColor:(UIColor *)color viewController:(UIViewController *)viewController
{
    BDPAppContainerController *appVc = [BDPResponderHelper findParentViewControllerFor:self class:[BDPAppContainerController class]];
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:appVc.uniqueID];
    
    if (self.viewControllers.count > 1 || (self.viewControllers.count == 1 && [self canGoBackForWebView]) ) {
        // 使用自定义返回按钮时，原有返回按钮会自动隐藏，此时不能手动设置hidesBackButton为YES，否则iOS9导航栏上会出现"..."的蓝点诡异Bug
        UIImage *backImage = [UIImage imageNamed:@"tma_navi_back" inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil];
        UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:backImage
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(backButtonOnClicked:)];
        backItem.accessibilityIdentifier = OPNavigationBarItemConsts.backButtonKey;
        // 导航栏左组件
        if ([viewController respondsToSelector:@selector(navigationLeftItems:)]) {
            // 获取左组件数组，nil保护
            NSMutableArray<UIBarButtonItem *> *mutableArray = [[(UIViewController<BDPNavigationControllerItemProtocol> *)viewController navigationLeftItems:self] mutableCopy] ?: [[NSMutableArray alloc] init];
            // backItem默认加入数组头
            [mutableArray insertObject:backItem atIndex:0];
            viewController.navigationItem.leftBarButtonItems = [mutableArray copy];
        } else {
            viewController.navigationItem.leftBarButtonItem = backItem;
        }
        viewController.navigationItem.hidesBackButton = NO;
        
        // 设置按钮颜色
        for (UIBarButtonItem *item in viewController.navigationItem.leftBarButtonItems) {
            if ([item.customView isKindOfClass:[UIButton class]]) {
                item.customView.tintColor = color;
            } else {
                item.tintColor = color;
            }
        }
        
        // 导航栏右组件
        if ([viewController respondsToSelector:@selector(navigationRightItems:)]) {
            // 获取右组件数组
            NSMutableArray<UIBarButtonItem *> *mutableArray = [[(UIViewController<BDPNavigationControllerItemProtocol> *)viewController navigationRightItems:self] mutableCopy] ?: [[NSMutableArray alloc] init];
            viewController.navigationItem.rightBarButtonItems = [mutableArray copy];
        }
    } else if (task.showGoHomeButton
               && [viewController isKindOfClass:[BDPAppPageController class]]
               && ![task.config isTabPage:task.currentPage.path]) {
        BDPAppPageController *appPageVC = (BDPAppPageController*)viewController;
        if (appPageVC.canShowHomeButton) {
            // 当页面栈只有一个页面，且页面不是首页或tab页时，才可以显示返回首页按钮
            UIImage *homeImage = [UIImage imageNamed:@"tma_navi_home" inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil];
            homeImage = [homeImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            // 需要让首页按钮对齐ui设计图的左方距离，但ios11后的UIBarButtonItem间距比较难调整
            // 目前采用修改按钮宽度的方案实现
            UIButton *homeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 32 + 2 * kNavHomeButtonLeftSpacing, 32)];
            homeButton.tintColor = color;
            [homeButton setImage:homeImage forState:UIControlStateNormal];
            [homeButton addTarget:self action:@selector(homeButtonOnClicked) forControlEvents:UIControlEventTouchUpInside];
            UIBarButtonItem *homeItem = [[UIBarButtonItem alloc] initWithCustomView:homeButton];
            homeItem.tag = BDPNavBarButtonTagHome;
            homeItem.accessibilityIdentifier = OPNavigationBarItemConsts.homeButtonKey;
            viewController.navigationItem.leftBarButtonItems = @[homeItem];
            viewController.navigationItem.hidesBackButton = NO;
        } else {
            // 因为更新导航栏时leftBarButtonItem不可为空，只能手动把homeButton隐藏掉
            UIBarButtonItem *homeItem = nil;
            for (UIBarButtonItem *item in viewController.navigationItem.leftBarButtonItems) {
                if (item.tag == BDPNavBarButtonTagHome) {
                    homeItem = item;
                    break;
                }
            }
            homeItem.customView.hidden = YES;
            // 可以通过调用api隐藏，所以homeItem可能为nil
            viewController.navigationItem.leftBarButtonItems = homeItem ? @[homeItem] : @[];
            viewController.navigationItem.hidesBackButton = NO;
        }
    } else {
        // 注意此处有坑，更新导航栏时leftBarButtonItem不可为空，BDPAppPageController做了特殊处理
        // 否则导航栏组件位置会有bug
        viewController.navigationItem.leftBarButtonItem = nil;
        viewController.navigationItem.hidesBackButton = YES;
    }
    
    // 设置载入图标的颜色
    UIView *titleView = viewController.navigationItem.titleView;
    UIView *loadingParentView = [titleView viewWithTag:BDPNavTitleViewTagLoadingParent];
    UIImageView *loadingView = [loadingParentView viewWithTag:BDPNavTitleViewTagLoading];
    
    if (loadingView && [viewController isKindOfClass:[BDPAppPageController class]]) {
        BDPAppPageController *appVC = (BDPAppPageController*)viewController;
        BOOL reverse = [appVC.appPage bap_navBarItemColorShouldReverse];
        NSString *textStyle = [appVC.pageConfig.window navigationBarTextStyleWithReverse:reverse];
        BDPToolBarViewStyle toolBarStyle = [textStyle isEqualToString:@"black"] ? BDPToolBarViewStyleLight : BDPToolBarViewStyleDark;
        if (self.containerContext.uniqueID.isAppSupportDarkMode) {
            if ([textStyle isEqualToString:@"black"]) {
                toolBarStyle = BDPToolBarViewStyleLight;
            } else if ([textStyle isEqualToString:@"white"]) {
                toolBarStyle = BDPToolBarViewStyleDark;
            } else {
                // 缺省颜色按照 Light Mode
                toolBarStyle = BDPToolBarViewStyleLight;
            }
        }
        NSString *imageName = (toolBarStyle == BDPToolBarViewStyleLight) ? @"icon_navigation_loading_black" : @"icon_navigation_loading_white";
        [loadingView setImage:[UIImage imageNamed:imageName inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil]];
    }
}

- (void)homeButtonOnClicked
{
    [self clickEventFlush:OPNavigationBarItemMonitorCodeBridge.homeButton];
    BDPAppContainerController *appVC = [BDPResponderHelper findParentViewControllerFor:self class:[BDPAppContainerController class]];
    BDPTask *task = [[BDPTaskManager sharedManager] getTaskWithUniqueID:appVC.uniqueID];
    [appVC.appController.routeManager goHome];
    task.showGoHomeButton = NO;
}

- (BDPWebViewComponent *)webViewForAppController {
    BDPAppPageController *vc = [self.viewControllers lastObject];
    if ([vc isKindOfClass:[BDPAppPageController class]]) {
        for (UIView *v in vc.appPage.subviews) {
            if ([v isKindOfClass:[BDPWebViewComponent class]]) {
                BDPWebViewComponent *webView = (BDPWebViewComponent *)v;
                return webView;
            }
        }
    }
    return nil;
}

- (BOOL)goBackForWebView {
    BDPWebViewComponent *webView = [self webViewForAppController];
    if (webView && [webView canGoBack]) {
        [webView goBack];
        return YES;
    }
    return NO;
}

- (BOOL)canGoBackForWebView {
    BDPWebViewComponent *webView = [self webViewForAppController];
    if (webView && [webView canGoBack]) {
        return YES;
    }
    return NO;
}

- (BOOL)goBackforAppPage {
    BDPAppPageController *appPageController = [self.viewControllers lastObject];
    if ([appPageController isKindOfClass:[BDPAppPageController class]]) {
        __weak typeof(self) weakSelf = self;
        return [appPageController handleLeaveComfirmAction:BDPLeaveComfirmActionBack confirmCallback:^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf popViewControllerAnimated:YES];
        }];
    }
    return NO;
}

- (BOOL)goBackForGadgetTakeover {
    BDPAppPageController *appPageController = [self.viewControllers lastObject];
    if ([appPageController isKindOfClass:[BDPAppPageController class]]) {
        if ([appPageController handleTakeoverBackEventIfRegisted]) {
            return YES;
        }
    }
    return NO;
}

- (void)backButtonOnClicked:(id)sender
{
    [self clickEventFlush:OPNavigationBarItemMonitorCodeBridge.backButton];
    // 如果有WebView组件，优先返回WebView组件的上一级
    if ([self goBackForWebView]) {
        return;
    }
    
    // 托管给小程序处理返回的检查和处理
    if ([self goBackForGadgetTakeover]) {
        return;
    }
    
    // 二次弹框拦截
    if ([OPSDKFeatureGating enableLeaveComfirm]) {
        if ([self goBackforAppPage]) {
            return;
        }
    }
    [self popViewControllerAnimated:YES];
}

-(CGFloat)getMaxLabelWidthForVC:(UIViewController *)vc{
    if (![BDPDeviceHelper isPadDevice]) {
        return kTitleViewMaxWidth;
    }
    CGFloat leftBarWidth = vc.navigationItem.leftBarButtonItem.customView.bdp_width;
    CGFloat rightBarWidth = vc.navigationItem.rightBarButtonItem.customView.bdp_width;
    CGFloat maxBarWidth = MAX(leftBarWidth, rightBarWidth);
    return (vc.navigationController.navigationBar.bdp_width - (maxBarWidth + 20)*2);
    
}

#pragma mark - StatusBar
/*------------------------------------------*/
//            StatusBar - 状态栏
/*------------------------------------------*/
- (void)updateStatusBarStyle:(BOOL)animated
{
    // 状态栏风格
    [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle] animated:animated];
}

- (void)updateStatusBarHidden:(BOOL)animated
{
    // 状态栏隐藏/显示
    BOOL isVCBaseStatusBar = NO;
    if ([[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"]) {
        isVCBaseStatusBar = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"UIViewControllerBasedStatusBarAppearance"] boolValue];
    }
    
    if (isVCBaseStatusBar) {
        return;
    }
    
    NSTimeInterval duration = animated ? UINavigationControllerHideShowBarDuration : 0.f;
    if ([BDPDeviceHelper OSVersionNumber] < 13.f) {
        [UIView animateWithDuration:duration animations:^{
            [[[UIApplication sharedApplication] valueForKey:@"statusBar"] setAlpha:![self prefersStatusBarHidden]];
        }];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:[self prefersStatusBarHidden] withAnimation:animated];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.topViewController preferredStatusBarStyle];
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.topViewController preferredStatusBarUpdateAnimation];
}

- (BOOL)prefersStatusBarHidden
{
    return [self.topViewController prefersStatusBarHidden];
}

#pragma mark - Orientation
/*------------------------------------------*/
//          Orientation - 屏幕旋转
/*------------------------------------------*/
- (void)refreshOrientation
{
    if (![OPGadgetRotationHelper enableGadgdetRotation:self.containerContext.uniqueID]) {
        [BDPDeviceManager deviceInterfaceOrientationAdaptToMask:[self supportedInterfaceOrientations]];
    }
}

- (BOOL)shouldAutorotate
{
    return [self.topViewController shouldAutorotate];
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [self.topViewController supportedInterfaceOrientations];
}

- (void)updateRightItems:(NSArray<UIBarButtonItem *> *)rightItems viewController:(UIViewController *)viewController
{
    viewController.navigationItem.rightBarButtonItems = [rightItems copy];
}

#pragma mark - private
/// 导航栏按钮点击事件上报. '关闭'/'更多'按钮
/// @param buttonId 埋点ID. 产品侧定义的code.见链接
/// https://bytedance.feishu.cn/sheets/shtcncTYngXV6omM6ltYTzccpOD
- (void)clickEventFlush:(NSString *)buttonId {
    BDPMonitorWithName(@"openplatform_mp_container_click", self.containerContext.uniqueID)
        .setPlatform(OPMonitorReportPlatformTea)
        .addCategoryValue(@"application_id", BDPSafeString(self.containerContext.uniqueID.appID))
        .addCategoryValue(@"click", @"button")
        .addCategoryValue(@"target", @"none")
        .addCategoryValue(@"button_id", buttonId)
        .flush();
}
@end

@implementation BDPNavigationController (Private)

- (UIViewController *)origin_popViewControllerAnimated:(BOOL)animated
{
    return [super popViewControllerAnimated:animated];
}

- (void)origin_pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    return [super pushViewController:viewController animated:animated];
}

@end

@implementation BDPNavigationTitleLabel

- (instancetype)initWithFrame:(CGRect)rect
{
    self = [super initWithFrame:rect];
    if (self) {
        [self setOpaque:NO];
    }
    return self;
}

- (void)adjustLabelSize:(CGFloat)maxWidth
{
    CGSize labelSize = (CGSize){maxWidth, self.frame.size.height};
    CGRect fitLabelSize = [self.attributedText boundingRectWithSize:labelSize options:(NSStringDrawingUsesLineFragmentOrigin| NSStringDrawingTruncatesLastVisibleLine) context:nil];
    
    CGRect newFrame = self.frame;
    newFrame.size.width = ceil(fitLabelSize.size.width);
    newFrame.size.height = ceil(fitLabelSize.size.height);
    [self setFrame:newFrame];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    [self.attributedText drawWithRect:self.bounds options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingTruncatesLastVisibleLine context:nil];
}

@end
