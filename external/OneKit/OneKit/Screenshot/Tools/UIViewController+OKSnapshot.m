//
//  UIViewController+OKSnapshot.m
//  OKSnapshotScroll
//
//  Created by tonyreet on 2018/9/20.
//  Copyright © 2018年 TonyReet. All rights reserved.
//

#import "UIViewController+OKSnapshot.h"

@implementation UIViewController (OKSnapshot)

+ (UIViewController *)currentViewController {
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    UIViewController *vc = keyWindow.rootViewController;
    
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
        
        if ([vc isKindOfClass:[UINavigationController class]]) {
            vc = [(UINavigationController *)vc visibleViewController];
        } else if ([vc isKindOfClass:[UITabBarController class]]) {
            vc = [(UITabBarController *)vc selectedViewController];
        }
    }
    
    return vc;
}


@end
