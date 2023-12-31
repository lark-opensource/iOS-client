//
//  TSPKPermissionCheckerAlert.m
//  Baymax_MusicallyTests
//
//  Created by admin on 2022/5/10.
//

#import "TSPKPermissionCheckerAlert.h"

@implementation TSPKPermissionCheckerAlert

+ (void)showWithMessage:(NSString *)message {
#if DEBUG
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"Lost Permission" message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @throw [NSException exceptionWithName:@"Lose Permission" reason:message userInfo:nil];
        }];
        
        [alertVC addAction:confirmAction];
        
        UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
        UIViewController *topVC = [[self class] topViewControllerForController:vc];
        [topVC presentViewController:alertVC animated:YES completion:nil];
    });
#else
#endif
}

+ (UIViewController *)topViewControllerForController:(UIViewController *)rootViewController
{
    if ([rootViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *) rootViewController;
        return [self topViewControllerForController:[navigationController.viewControllers lastObject]];
    }
    if ([rootViewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabController = (UITabBarController *) rootViewController;
        return [self topViewControllerForController:tabController.selectedViewController];
    }
    if ([rootViewController isKindOfClass:[UIViewController class]] && rootViewController.presentedViewController) {
        return [self topViewControllerForController:rootViewController.presentedViewController];
    }
    return rootViewController;
}

@end
