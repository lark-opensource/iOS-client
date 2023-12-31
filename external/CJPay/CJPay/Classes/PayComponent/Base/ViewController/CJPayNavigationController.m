//
//  CJPayNavigationController.m
//  CJPay
//
//  Created by 王新华 on 9/19/19.
//

#import "CJPayNavigationController.h"
#import "CJPayTransitionManager.h"
#import "UIViewController+CJTransition.h"
#import "CJPayUIMacro.h"
#import "CJPayHalfPageBaseViewController.h"
#import "CJPayFullPageBaseViewController.h"
#import "CJPayFullPageBaseViewController+Theme.h"

NSInteger const gCJTransitionMaxX = 100;

@interface CJPayNavigationController()<UIGestureRecognizerDelegate>

@property (nonatomic, assign) BOOL isCustomPush;
@property (nonatomic, weak) UIDocumentMenuViewController *weakDocumentMenuVC;

@end

@implementation CJPayNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    
     // 兼容暗黑模式
    if (@available(iOS 13.0, *)) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
    if (!CJ_Pad) {
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
        [self.view addGestureRecognizer:panGesture];
        panGesture.delegate = self;
        self.interactivePopGestureRecognizer.enabled = NO;
    }
}

+ (CJPayNavigationController *)instanceForRootVC:(UIViewController *)rootVC {
    CJPayNavigationController *nav = [[CJPayNavigationController alloc] initWithRootViewController:rootVC]; //  initWithRootVC 不走init方法,所以属性在这设置一份
    CJPayTransitionManager *transitionManager = [CJPayTransitionManager transitionManagerWithNavi:nav];
    nav.transitioningDelegate = transitionManager;
    nav.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet : UIModalPresentationFullScreen;
    nav.navigationBarHidden = YES;
    nav.navigationBar.hidden = YES;
    nav.modalPresentationCapturesStatusBarAppearance = YES;
    nav.delegate = transitionManager;
    nav.transitionManager = transitionManager;
    return nav;
}

// 统一登录需要定制
+ (CJPayNavigationController *)customPushNavigationVC {
    CJPayNavigationController *nav = [CJPayNavigationController new];
    nav.isCustomPush = YES;
    return nav;
}

- (BOOL)shouldAutorotate {
    return CJ_Pad;
}

// 兼容抖音的转场逻辑
- (BOOL)aweDisableFullscreenPopTransition {
    return YES;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        CJPayTransitionManager *transitionManager = [CJPayTransitionManager transitionManagerWithNavi:self];
        self.transitioningDelegate = transitionManager;
        self.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet : UIModalPresentationFullScreen;
        self.navigationBarHidden = YES;
        self.navigationBar.hidden = YES;
        self.delegate = transitionManager;
        self.transitionManager = transitionManager;
        // TODO: 确认以下属性的影响
        self.modalPresentationCapturesStatusBarAppearance = YES;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (CJ_Pad) {
        CGFloat preferHeight = MAX(620, self.cjpadPreferHeight);
        CGSize size = [self.view systemLayoutSizeFittingSize:UILayoutFittingCompressedSize withHorizontalFittingPriority:UILayoutPriorityDefaultHigh verticalFittingPriority:UILayoutPriorityRequired];
        if (!CGSizeEqualToSize(size, CGSizeZero)) {
            self.preferredContentSize = CGSizeMake(MIN(375, size.width), preferHeight);
        } else {
            self.preferredContentSize = CGSizeMake(375, preferHeight);
        }
    }
}

- (void)handleGesture:(UIPanGestureRecognizer *)panGesture {
    [self.transitionManager handleGesture:panGesture];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer{
    return self.topViewController.cjAllowTransition;
}

// 兼容抖音的转场逻辑
- (id<UIViewControllerTransitioningDelegate>)transition_navigationProxyDelegate {
    return self.transitionManager;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    if (CJ_Pad) {
        return UIInterfaceOrientationMaskAll;
    }
    return UIInterfaceOrientationMaskPortrait;
}

- (void)pushViewControllerSingleTop:(UIViewController *)viewController animated:(BOOL)animated completion:(nullable void (^)(void))completion {

    [CJPayCommonUtil cj_catransactionAction:^{
        [self pushViewController:viewController animated:animated];
    } completion:^{
        [self p_removeVCsUnderVC:viewController];
        CJ_CALL_BLOCK(completion);
    }];
}

- (BOOL)hasFullPageInNavi {
    __block BOOL hasFullPageVC = NO;
    [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:CJPayFullPageBaseViewController.class]) {
            hasFullPageVC = YES;
            *stop = YES;
        }
    }];
    return hasFullPageVC;
}

#pragma mark override

- (NSArray<UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (!viewController || ![self.viewControllers containsObject:viewController]) {
        return @[];
    }

    return [super popToViewController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    if (self.viewControllers.count <= 1) {
        [self dismissViewControllerAnimated:animated completion:nil];
        return nil;
    } else {
        return [super popViewControllerAnimated:animated];
    }
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    if (![viewController isCJPayViewController]) {
        viewController.cjAllowTransition = YES;
    }
    
    if ([self.viewControllers containsObject:viewController]) {
        return;
    }
    
    [self copyCurrentThemeModeTo:viewController];
    
    if (self.isCustomPush && self.viewControllers.count < 1) {
        self.viewControllers = @[viewController];
        [[UIViewController cj_topViewController] presentViewController:self animated:animated completion:nil];
        return;
    }
    
    [super pushViewController:viewController animated:animated];
}

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    [super presentViewController:viewControllerToPresent animated:flag completion:completion];
    if ([viewControllerToPresent isKindOfClass:UIDocumentMenuViewController.class]) {
        self.weakDocumentMenuVC = (UIDocumentMenuViewController *)viewControllerToPresent;
    }
}

// 修改兼容性bug。 iOS 9，10 在webviewvc调用系统相册会出现，dismiss多调用一次的问题https://stackoom.com/question/2mOJV/UIDocumentPickerViewController%E5%85%B3%E9%97%AD%E7%88%B6%E8%A7%86%E5%9B%BE%E6%8E%A7%E5%88%B6%E5%99%A8
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    if (@available(iOS 11.2, *)) {
        [super dismissViewControllerAnimated:flag completion:completion];
    } else { // 只对iOS 9系列进行处理
        UIViewController *vc = self.presentedViewController;
        if (self.weakDocumentMenuVC && !vc && [self.topViewController isKindOfClass:NSClassFromString(@"CJPayBizWebViewController")] ) {
            // 这种情况下不调用super，防止出现2次关闭的问题
        } else {
            [super dismissViewControllerAnimated:flag completion:completion];
        }
    }
}

#pragma mark private

- (void)p_removeVCsUnderVC:(UIViewController *)VC {
    [self setViewControllers:@[VC] animated:NO];
}

@end
