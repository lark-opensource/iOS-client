//
//  UIViewController+Navigation.m
//  Timor
//
//  Created by tujinqiu on 2019/10/8.
//

#import "UIViewController+Navigation.h"
#import "UINavigationBar+Navigation.h"
#import <objc/runtime.h>
#import "BDPAppPageController.h"
#import <OPFoundation/NSObject+BDPExtension.h>
#import <LKLoadable/Loadable.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <OPSDK/OPSDK-Swift.h>

#pragma GCC diagnostic ignored "-Wundeclared-selector"

LoadableRunloopIdleFuncBegin(UIViewControllerNavigationSwizzle)
[UIViewController performSelector:@selector(bdp_viewController_navigation_swizzle)];
LoadableRunloopIdleFuncEnd(UIViewControllerNavigationSwizzle)

@implementation UIViewController (Navigation)

+ (void)bdp_viewController_navigation_swizzle {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self bdp_swizzleOriginInstanceMethod:@selector(viewWillLayoutSubviews) withHookInstanceMethod:@selector(bdp_viewWillLayoutSubviews)];
        [self bdp_swizzleOriginInstanceMethod:@selector(viewDidLayoutSubviews) withHookInstanceMethod:@selector(bdp_viewDidLayoutSubviews)];
    });
}

- (void)bdp_viewWillLayoutSubviews
{
    [self bdp_viewWillLayoutSubviews];

    if (self.bdp_shouldFakeNavigationBarBG) {
        [self bdp_tryAddFakeNavigationBarBG];
    }
}

- (void)bdp_viewDidLayoutSubviews
{
    [self bdp_viewDidLayoutSubviews];

    if (self.bdp_shouldFakeNavigationBarBG) {
        [self bdp_tryAddFakeNavigationBarBG];
    }
}

- (void)bdp_tryAddFakeNavigationBarBG
{
    if (![self _bdp_fakeNavigationBarBG]) {
        UIView *bg = UIView.new;
        bg.backgroundColor = UDOCColor.bgBody;
        self.bdp_fakeNavigationBarBG = bg;
    }

    if ([self _bdp_fakeNavigationBarBG].superview) {
        [self bdp_resizeFakeNavigationBarBG];
        return;
    }

    // view 如果没有 Loaded，不能添加，否则会提前 VC 的 load 时机
    if (!self.viewIfLoaded) {
        return;
    }

    [self.view addSubview:[self _bdp_fakeNavigationBarBG]];
    [self bdp_resizeFakeNavigationBarBG];
}

- (BOOL)bdp_shouldFakeNavigationBarBG
{
    return [objc_getAssociatedObject(self, @selector(bdp_shouldFakeNavigationBarBG)) boolValue];
}

- (void)setBdp_shouldFakeNavigationBarBG:(BOOL)bdp_shouldFakeNavigationBarBG
{
    if (bdp_shouldFakeNavigationBarBG) {
        // 如果是push的半透明的BDPAppPageController，那么应该提前初始化，否则转场动画会跳变
        if ([self isKindOfClass:[BDPAppPageController class]] && self.navigationController.viewControllers.count > 1) {
            if (((BDPAppPageController *)self).pageConfig.window.navigationBarBgTransparent) {
                [self view];
            }
        }
        [self bdp_tryAddFakeNavigationBarBG];
    }
    objc_setAssociatedObject(self, @selector(bdp_shouldFakeNavigationBarBG), @(bdp_shouldFakeNavigationBarBG), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)bdp_fakeNavigationBarBG
{
    if (self.bdp_shouldFakeNavigationBarBG) {
        [self bdp_tryAddFakeNavigationBarBG];
    }
    return [self _bdp_fakeNavigationBarBG];
}

- (UIView *)_bdp_fakeNavigationBarBG
{
    return objc_getAssociatedObject(self, @selector(bdp_fakeNavigationBarBG));
}

- (void)setBdp_fakeNavigationBarBG:(UIView *)bdp_fakeNavigationBarBG
{
    objc_setAssociatedObject(self, @selector(bdp_fakeNavigationBarBG), bdp_fakeNavigationBarBG, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGRect)bdp_getNavigationBarBgRect
{
    UIView *navigationBar = self.navigationController.navigationBar;
    if (navigationBar) {
        CGFloat height = navigationBar.frame.size.height + UIApplication.sharedApplication.statusBarFrame.size.height;
        CGFloat y = [self bdp_isViewLayoutBelowNavigationBar] ? -height : 0;
        return CGRectMake(0, y, navigationBar.frame.size.width, height);
    }
    return CGRectZero;
}

- (void)bdp_resizeFakeNavigationBarBG
{
    if ([self _bdp_fakeNavigationBarBG]) {
        CGRect frame = [self bdp_getNavigationBarBgRect];
        // fix: 返回无导航栏的时候动画效果错误
        if (!CGRectEqualToRect(frame, CGRectZero)) {
            [self _bdp_fakeNavigationBarBG].frame = frame;
        }
        if (frame.origin.y < -0.00001) {
            self.view.clipsToBounds = NO;
        }
        [self.view bringSubviewToFront:[self _bdp_fakeNavigationBarBG]];
    }
}

- (BOOL)bdp_isViewLayoutBelowNavigationBar
{
    UIView *fakeBG = [self _bdp_fakeNavigationBarBG];
    if (fakeBG) {
        if (fakeBG.hidden == YES) {
            return NO;
        } else {
            // 当展示导航栏时，只有半透明的情况下self.view会扩展到导航栏下方
            if ([self isKindOfClass:[BDPAppPageController class]]) {
                BDPAppPageController *pageVC = (BDPAppPageController *)self;
                if (pageVC.pageConfig.window.navigationBarBgTransparent) {
                    return NO;
                }
            }
        }
    }
    return YES;
}

@end
