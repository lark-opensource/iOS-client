//
//  BDPRootNavigationController.m
//  Timor
//
//  Created by MacPu on 2019/2/2.
//

#import "BDPRootNavigationController.h"
#import <OPFoundation/BDPUtils.h>
#import <OPFoundation/BDPCommon.h>
#import <OPFoundation/BDPTimorClient.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <OPFoundation/BDPCommonManager.h>
#import "BDPWarmBootManager.h"
#import "BDPBaseContainerController.h"
#import "BDPAppContainerController.h"

#import "BDPTask.h"
#import <OPSDK/OPSDK-Swift.h>

@interface BDPRootNavigationController () <UIGestureRecognizerDelegate, UINavigationControllerDelegate>

@property (nonatomic, strong) NSArray *dontRecognizePopGestureControllers;

@end

@implementation BDPRootNavigationController

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        self.animation.style = [rootViewController isKindOfClass:[BDPAppContainerController class]] ? BDPPresentAnimationStypeRightLeft : BDPPresentAnimationStypeUpDown;
        self.modalPresentationStyle = UIModalPresentationFullScreen;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.interactivePopGestureRecognizer.delegate = self;
    self.interactivePopGestureRecognizer.enabled = YES;
    [self setNavigationBarHidden:YES animated:YES];
    self.delegate = self;
    self.transitioningDelegate = self.animation;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    //bugfix: 修复第一次进入小程序状态栏的颜色不对的问题， 不知道是不是系统的问题。
    // 暂时找不到其他的解决方案，先使用这种方式修改， 评估下影响看一下吧
    [[UIApplication sharedApplication] setStatusBarStyle:self.preferredStatusBarStyle animated:animated];
}

- (void)pushViewControllerByTransitioningAnimation:(UIViewController *)viewController animated:(BOOL)animated
{
    [self pushViewController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    // 这里因为小程序有可能跳转端上的界面，有些端上界面的返回是pop的，如果出现BDPRootNavigationController
    // 最后一个VC是端上的VC,并且这个VC是pop的，那就只好这里强制dismiss一下。
    if ([self.viewControllers count] > 1) {
        return [super popViewControllerAnimated:animated];
    } else {
        UIViewController *root = self.topViewController;
        if (![root isKindOfClass:[BDPBaseContainerController class]]) {
            // 做动画希望也能支持横滑返回。
            if (self.interactivePopGestureRecognizer.state == UIGestureRecognizerStateBegan) {
                self.animation.screenEdgePopMode = YES;
                [self.interactivePopGestureRecognizer addTarget:self action:@selector(popGestureChanged:)];                
            }
            [self dismissViewControllerAnimated:animated completion:nil];
            return root;
        }
    }
    return nil;
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    [super dismissViewControllerAnimated:flag completion:completion];
    
    // 头条做了hook，当如果有弹窗关闭的时候，会走到这里，然后设置 isWillDIsmissSoon为 YES。
    // 这个时候再进行跳转，就会失败。 头条的同学希望我们这里手动的设置为 NO。 @mayandong
    if ([self respondsToSelector:NSSelectorFromString(@"isWillDismissSoon")]){
        [self setValue:@(NO) forKey:@"isWillDismissSoon"];
    }
}

- (void)popGestureChanged:(UIScreenEdgePanGestureRecognizer *)gesture
{
    CGFloat progress = [gesture translationInView:self.view].x / self.view.bounds.size.width;
    progress = MIN(1.0, MAX(0.0, progress));//把这个百分比限制在0~1之间
    switch (gesture.state) {
        case UIGestureRecognizerStateChanged:
        {
            [self.animation.interactive updateInteractiveTransition:progress];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            CGFloat velocity = [gesture velocityInView:self.view].x;
            if (progress > 0.25 || velocity >= 80) {
                [self.animation.interactive finishInteractiveTransition];
                
            } else {
                [self.animation.interactive cancelInteractiveTransition];
            }
            [self.interactivePopGestureRecognizer removeTarget:self action:@selector(popGestureChanged:)];
            break;
        }
        default:
            break;
    }
}

- (NSArray<BDPBaseContainerController *> *)allApps
{
    NSMutableArray *apps = [[NSMutableArray alloc] init];
    [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *obj, NSUInteger idx, BOOL *stop) {
        if ([obj isKindOfClass:[BDPBaseContainerController class]]) {
            [apps addObject:obj];
        }
    }];
    return apps;
}

- (NSArray<BDPBaseContainerController *> *)shouldRemoveAppsInAppArray:(NSArray<BDPBaseContainerController *> *)appAray retainCount:(NSInteger)retainCount
{
    if (appAray.count <= retainCount) {
        return nil;
    }
    
    NSMutableDictionary *weightMap = [[NSMutableDictionary alloc] initWithCapacity:appAray.count];
    [appAray enumerateObjectsUsingBlock:^(BDPBaseContainerController *obj, NSUInteger idx, BOOL *stop) {
        NSInteger factor = ([[BDPCommonManager sharedManager] getCommonWithUniqueID:obj.uniqueID].uniqueID.appType == BDPTypeNativeApp) ? 20 : 10;
        NSInteger multiplier = 1;
        NSInteger weight = multiplier * factor + idx;
        if (idx >= appAray.count - 2) { // 最后两个的权值很高，不应该被杀掉。
            weight += 1000;
        }
        BDPUniqueID *uniqueID = obj.uniqueID;
        if ([uniqueID respondsToSelector:@selector(isBackgroundAudioWorking)] && [[uniqueID performSelector:@selector(isBackgroundAudioWorking)] boolValue]) {
            weight += 10000;
        }
        [weightMap setObject:obj forKey:@(weight)];
    }];
    
    NSMutableArray *weightArray = [[weightMap allKeys] mutableCopy];
    NSSortDescriptor *highestToLowest = [NSSortDescriptor sortDescriptorWithKey:@"self" ascending:NO];
    [weightArray sortUsingDescriptors:[NSArray arrayWithObject:highestToLowest]];
    weightArray = (NSMutableArray *)[weightArray subarrayWithRange:NSMakeRange(retainCount, weightArray.count - retainCount)];
    return [weightMap objectsForKeys:weightArray notFoundMarker:[NSNull null]];
}

- (void)removeApps:(NSArray<BDPBaseContainerController *> *)apps
{
    if (apps.count > 0) {
        NSMutableArray *vcs = [self.viewControllers mutableCopy];
        [apps enumerateObjectsUsingBlock:^(BDPBaseContainerController *obj, NSUInteger idx, BOOL *stop) {
            [vcs removeObject:obj];
            [[BDPWarmBootManager sharedManager] cleanCacheWithUniqueID:[[BDPCommonManager sharedManager] getCommonWithUniqueID:obj.uniqueID].model.uniqueID];
        }];
        self.viewControllers = vcs;
    }
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    // 状态栏处理
    [self updateStatusBarStyle:animated];
    [self updateStatusBarHidden:animated];
}

- (UIInterfaceOrientationMask)navigationControllerSupportedInterfaceOrientations:(UINavigationController *)navigationController
{
    return [navigationController.topViewController supportedInterfaceOrientations];
}

- (BDPPresentAnimation *)animation
{
    if (!_animation) {
        _animation = [[BDPPresentAnimation alloc] init];
    }
    return _animation;
}

#pragma mark - GestureDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.viewControllers.count <= 1) {
        if ([self.topViewController isKindOfClass:[BDPBaseContainerController class]]) {
            return NO;
        } else {
            // 如果 BDPRootNavigationController 最后的界面不是小程序的界面，那就可能是端上的某一个界面，所以需要支持横滑返回。
            return YES;
        }
    }
    
    if ([self.dontRecognizePopGestureControllers containsObject:NSStringFromClass([self.topViewController class])]) {
        return NO;
    }
    
    if ([self.topViewController isKindOfClass:[BDPBaseContainerController class]]) {
        return NO;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return gestureRecognizer == self.interactivePopGestureRecognizer;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController isKindOfClass:[BDPBaseContainerController class]]) {
        NSMutableArray<BDPBaseContainerController *> *allApps = [self.allApps mutableCopy];
        [allApps removeObject:(BDPBaseContainerController *)viewController];
        
        NSInteger retainAppCount = [BDPTimorClient sharedClient].currentNativeGlobalConfiguration.maxWarmBootCacheCount;
        NSArray *shouldRemoveArray = [self shouldRemoveAppsInAppArray:self.allApps retainCount:retainAppCount];
        [self removeApps:shouldRemoveArray];
        
    }
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController
                         interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    if (self.animation == animationController && self.animation.screenEdgePopMode) {
        return self.animation.interactive;
    }
    return nil;
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController *)fromVC
                                                 toViewController:(UIViewController *)toVC
{
    if ((operation == UINavigationControllerOperationPop && [fromVC isKindOfClass:[BDPBaseContainerController class]])
        || (operation == UINavigationControllerOperationPush && [toVC isKindOfClass:[BDPBaseContainerController class]])) {
        self.animation.operation = operation;
        
        self.animation.style = BDPPresentAnimationStypeUpDown;
        if ((operation == UINavigationControllerOperationPop && [fromVC isKindOfClass:[BDPAppContainerController class]])
            || (operation == UINavigationControllerOperationPush && [toVC isKindOfClass:[BDPAppContainerController class]]))
            self.animation.style = BDPPresentAnimationStypeRightLeft;
        
        return self.animation;
    }
    return nil;
}

- (void)updateStatusBarStyle:(BOOL)animated
{
    // 状态栏风格
    [[UIApplication sharedApplication] setStatusBarStyle:[self preferredStatusBarStyle] animated:animated];
}

- (void)updateStatusBarHidden:(BOOL)animated
{
    // 状态栏隐藏/显示
    NSTimeInterval duration = animated ? UINavigationControllerHideShowBarDuration : 0.f;
    [[UIApplication sharedApplication] setStatusBarHidden:[self prefersStatusBarHidden] withAnimation:animated];
}

- (BOOL)prefersStatusBarHidden
{
    return [self.topViewController prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [self.topViewController preferredStatusBarStyle];
}

@end
