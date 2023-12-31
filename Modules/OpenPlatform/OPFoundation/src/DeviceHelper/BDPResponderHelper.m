//
//  BDPResponderHelper.m
//  Timor
//
//  Created by CsoWhy on 2018/9/3.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "BDPResponderHelper.h"
#import "BDPDeviceHelper.h"
#import "BDPTimorClient.h"
#import "BDPMacroUtils.h"
#import <OPFoundation/OPFoundation-Swift.h>

@implementation BDPResponderHelper

+ (CGSize)windowSize:(UIWindow *_Nullable)window
{
    window = window ?: OPWindowHelper.fincMainSceneWindow;
    CGSize windowSize = window.bounds.size;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0f && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return CGSizeMake(windowSize.height, windowSize.width);
    }
    return windowSize;
}

+ (CGSize)screenSize {
    UIScreen *mainScreen = [UIScreen mainScreen];
    CGSize screenSize = mainScreen.bounds.size;
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0f && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return CGSizeMake(screenSize.height, screenSize.width);
    }
    return screenSize;
}

+ (UIEdgeInsets)safeAreaInsets:(UIWindow *_Nullable)window
{
    window = window ?: OPWindowHelper.fincMainSceneWindow;
    return window.safeAreaInsets;
}

+ (UIViewController*)topViewControllerFor:(UIResponder*)responder
{
    UIResponder *topResponder = responder;
    while(topResponder && ![topResponder isKindOfClass:[UIViewController class]]) {
        topResponder = [topResponder nextResponder];
    }
    
    if (!topResponder) {
        topResponder = [[[UIApplication sharedApplication] delegate].window rootViewController];
    }
    
    return (UIViewController*)topResponder;
}

+ (UINavigationController*)topNavigationControllerFor:(UIResponder*)responder
{
    UIViewController *top = [self topViewControllerFor:responder];
    if (top.presentedViewController && [top.presentedViewController isKindOfClass:[UINavigationController class]]) {
        top = top.presentedViewController;
        while (top.presentedViewController && [top.presentedViewController isKindOfClass:[UINavigationController class]]) {
            top = top.presentedViewController;
        }
        return (UINavigationController *)top;
        
    } else if ([top isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)top;
        
    } else if (top.navigationController) {
        return top.navigationController;
        
    } else if ([top isKindOfClass:[UITabBarController class]]) {
        UIViewController *selectedVC = [(UITabBarController *)top selectedViewController];
        return [selectedVC isKindOfClass:[UINavigationController class]] ? (UINavigationController *)selectedVC : nil;
        
    } else {
        return nil;
    }
}

/// 获取最顶层UIViewController，增加了对iPad present弹出popover视图的支持，使之在这种情况下可以返回正确的VC，fixForPopover表示是否开启修复
+ (UIViewController *)topViewControllerForController:(UIViewController *)rootViewController fixForPopover:(BOOL)fixForPopover
{
    // ipad 因为涉及到自定义容器UI，需要靠外部来找UI架构
    BDPPlugin(customResponderPlugin, BDPCustomResponderPluginDelegate);
    if ([BDPDeviceHelper isPadDevice] && [customResponderPlugin respondsToSelector:@selector(bdp_customTopMostViewControllerFor:fixForPopover:)]) {
        return [customResponderPlugin bdp_customTopMostViewControllerFor: rootViewController fixForPopover:fixForPopover];
    }

    // iphone 继续走原逻辑
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        return [self topViewControllerForController:[(UINavigationController *)rootViewController topViewController] fixForPopover:false];
    }
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        return [self topViewControllerForController:[(UITabBarController *)rootViewController selectedViewController] fixForPopover:false];
    }
    if ([rootViewController isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *splitVC = (UISplitViewController *)rootViewController;
        return [self topViewControllerForController:splitVC.viewControllers.lastObject fixForPopover:false];
    }
    if (rootViewController.presentedViewController) {
        return [self topViewControllerForController:rootViewController.presentedViewController fixForPopover:false];
    }
    return rootViewController;
}

+ (id)findParentViewControllerFor:(UIViewController *)viewController class:(Class)clz
{
    UIViewController *currentVC = viewController;
    while (currentVC && ![currentVC isKindOfClass:clz]) {
        currentVC = [currentVC parentViewController];
    }
    return currentVC;
}

+ (UIView*)topmostView:(UIWindow *_Nullable)window
{
    window = window ?: OPWindowHelper.fincMainSceneWindow;
    UIViewController *vc = [self topViewControllerForController:window.rootViewController fixForPopover:false];
    return vc.view;
}

+ (UIViewController*)topmostViewController:(UIWindow *_Nullable)window {
    window = window ?: OPWindowHelper.fincMainSceneWindow;
    UIView *topView = window.subviews.lastObject;
    UIViewController *topController = [self topViewControllerFor:topView];
    return topController;
}

@end
