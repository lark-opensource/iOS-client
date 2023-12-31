//
//  UIViewController+ACCStatusBar.h
//  AWEBizUIComponent
//
//  Created by long.chen on 2019/11/7.
//

#import <objc/runtime.h>
#import <CreativeKit/NSObject+ACCAdditions.h>

#import "UIViewController+ACCStatusBar.h"
#import "ACCStatusBarControllerFinder.h"

static BOOL classHooked(Class className) {
    static NSMutableArray *hookedClass;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hookedClass = @[].mutableCopy;
    });
    BOOL hooked = [hookedClass containsObject:className];
    [hookedClass addObject:className];
    return hooked;
}

@interface UIViewController ()

@property (nonatomic, assign) BOOL acc_forceHideStatusBar;
@property (nonatomic, assign) BOOL acc_forceShowStatusBar;

@end

@implementation UIViewController (ForceStatusBarShowOrHide)

- (BOOL)acc_forceHideStatusBar
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setAcc_forceHideStatusBar:(BOOL)acc_forceHideStatusBar
{
    [self willChangeValueForKey:@"acc_forceHideStatusBar"];
    objc_setAssociatedObject(self, @selector(acc_forceHideStatusBar), @(acc_forceHideStatusBar), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"acc_forceHideStatusBar"];
}

- (BOOL)acc_forceShowStatusBar
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setAcc_forceShowStatusBar:(BOOL)acc_forceShowStatusBar
{
    [self willChangeValueForKey:@"acc_forceShowStatusBar"];
    objc_setAssociatedObject(self, @selector(acc_forceShowStatusBar), @(acc_forceShowStatusBar), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self didChangeValueForKey:@"acc_forceShowStatusBar"];
}

- (BOOL)acc_vc_prefersStatusBarHidden
{
    if (self.acc_forceShowStatusBar) {
        return NO;
    } else if (self.acc_forceHideStatusBar) {
        return YES;
    } else {
        return [self acc_vc_prefersStatusBarHidden];
    }
}

+ (BOOL)acc_setStatusBarForceHide:(BOOL)hide
{
    id controller = [ACCStatusBarControllerFinder currentStatusBarControllerForType:ACCStatusBarControllerFindHidden];
    if (![controller isKindOfClass:UIViewController.class]) {
        return NO;
    }
    
    UIViewController *effectiveStatusBarVC = (UIViewController *)controller;
    [self effectiveStatusBarVCHookIfNeeded:effectiveStatusBarVC];
    effectiveStatusBarVC.acc_forceHideStatusBar = hide;
    [effectiveStatusBarVC setNeedsStatusBarAppearanceUpdate];
    return YES;
}

+ (BOOL)acc_setStatusBarForceShow:(BOOL)show
{
    id controller = [ACCStatusBarControllerFinder currentStatusBarControllerForType:ACCStatusBarControllerFindHidden];
    if (![controller isKindOfClass:UIViewController.class]) {
        return NO;
    }
    
    UIViewController *effectiveStatusBarVC = (UIViewController *)controller;
    [self effectiveStatusBarVCHookIfNeeded:effectiveStatusBarVC];
    effectiveStatusBarVC.acc_forceShowStatusBar = show;
    [effectiveStatusBarVC setNeedsStatusBarAppearanceUpdate];
    return YES;
}

+ (void)effectiveStatusBarVCHookIfNeeded:(UIViewController *)viewController
{
    if (!classHooked(viewController.class)) {
        [viewController.class acc_swizzleInstanceMethod:@selector(prefersStatusBarHidden) with:@selector(acc_vc_prefersStatusBarHidden)];
    }
}

@end
