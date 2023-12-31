//
//  ACCResponder.m
//  Essay
//
//  Created by Quan Quan on 15/11/5.
//  Copyright  ©  Byedance. All rights reserved, 2015
//

#import <CreationKitInfra/ACCResponder.h>

@implementation ACCResponder

#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wincompatible-pointer-types"
#pragma clang diagnostic pop

+ (UINavigationController *)topNavigationControllerForResponder:(UIResponder *)responder
{
    UIViewController *topViewController = [self topViewControllerForResponder:responder];
    if ([topViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)topViewController;
    } else if (topViewController.navigationController) {
        return topViewController.navigationController;
    } else {
        return nil;
    }
}

+ (UIViewController *)topViewController
{
    return [self topViewControllerForController:[UIApplication sharedApplication].keyWindow.rootViewController];
}

+ (BOOL)isTopViewController:(UIViewController *)viewController
{
    return [self topViewController] == viewController;
}

+ (UIView *)topView
{
    return [self topViewController].view;
}

+ (UIViewController *)topViewControllerForController:(UIViewController *)rootViewController
{
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)rootViewController;
        return [self topViewControllerForController:[navigationController.viewControllers lastObject]];
    }
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController *)rootViewController;
        return [self topViewControllerForController:tabController.selectedViewController];
    }
    if (rootViewController.presentedViewController) {
        return [self topViewControllerForController:rootViewController.presentedViewController];
    }
    if (rootViewController.acc_topViewController != rootViewController) {
        return [self topViewControllerForController:rootViewController.acc_topViewController];
    }
    // story legacy problem, will fix it in the future
    // plz contact @lijiale.mario or @zhangzhihao.lucas, if you want to remove it
    return rootViewController.acc_topViewController;
}

+ (UIViewController *)topViewControllerForView:(UIView *)view
{
    UIResponder *responder = view;
    while(responder && ![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
    }
    
    if(!responder) {
        responder = [UIApplication sharedApplication].keyWindow.rootViewController;
    }
    
    return [self topViewControllerForController:(UIViewController *)responder];
}

+ (UIViewController *)topViewControllerForResponder:(UIResponder *)responder
{
    if ([responder isKindOfClass:[UIView class]]) {
        return [self topViewControllerForView:(UIView *)responder];
    } else if ([responder isKindOfClass:[UIViewController class]]) {
        return [self topViewControllerForController:(UIViewController *)responder];
    } else {
        return [self topViewController];
    }
}

+ (void)closeTopViewControllerWithAnimated:(BOOL)animated
{
    UIViewController *viewController = [self topViewController];
    [viewController acc_closeWithAnimated:animated];
}

@end

@implementation UIViewController (ACC_Close)

- (void)acc_closeWithAnimated:(BOOL)animated
{
    //The navigation controller is given priority, followed by the model viewcontroller
    if (self.navigationController && self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:animated];
    } else if (self.presentingViewController) {
        [self.presentingViewController dismissViewControllerAnimated:animated completion:nil];
    } else {
        // do nothing
    }
}

@end

@implementation UIViewController (ACC_TopViewController)

- (UIViewController *)acc_topViewController
{
    return self;
}

@end
