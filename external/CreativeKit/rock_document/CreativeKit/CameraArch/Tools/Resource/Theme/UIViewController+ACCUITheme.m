//
//  UIViewController+ACCUITheme.m
//  CreativeKit-Pods-AwemeCore
//
//  Created by xiangpeng on 2021/10/8.
//

#import "UIViewController+ACCUITheme.h"
#import "UIView+ACCUITheme.h"
#import "ACCUIThemeManager.h"
#import "ACCUIDynamicColor.h"

@implementation UIViewController (ACCUITheme)

- (void)acc_themeReload
{
    [self.childViewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj acc_themeReload];
    }];
    [self.presentedViewController acc_themeReload];
    
    [self.view acc_themeReload];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

@end

@interface UINavigationController (ACCUITheme)

@end

@implementation UINavigationController (ACCUITheme)

- (void)acc_themeReload
{
    [super acc_themeReload];
    [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj acc_themeReload];
    }];
}

@end

@interface UITabBarController (ACCUITheme)

@end

@implementation UITabBarController (ACCUITheme)

- (void)acc_themeReload
{
    [super acc_themeReload];
    [self.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj acc_themeReload];
    }];
}

@end
