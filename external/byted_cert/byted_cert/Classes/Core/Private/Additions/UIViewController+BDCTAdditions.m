//
//  UIViewController+BDCTAdditions.m
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/8/23.
//

#import "UIViewController+BDCTAdditions.h"
#import "BDCTLocalization.h"
#import <ByteDanceKit/ByteDanceKit.h>


@implementation UIWindow (BDCTAdditions)

+ (UIWindow *)bdct_keyWindow {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([UIWindow respondsToSelector:@selector(btd_keyWindow)]) {
        return [UIWindow performSelector:@selector(btd_keyWindow)];
    }
#pragma clang diagnostic pop
    __block UIWindow *keyWindow = UIApplication.sharedApplication.keyWindow;
    if (!keyWindow) {
        [UIApplication.sharedApplication.windows enumerateObjectsUsingBlock:^(__kindof UIWindow *_Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            if (obj.isKeyWindow) {
                keyWindow = obj;
                *stop = YES;
            }
        }];
    }
    return keyWindow;
}

@end


@implementation UIViewController (BDCTAdditions)

- (void)bdct_showViewController:(UIViewController *)viewController {
    if ([self isKindOfClass:UINavigationController.class]) {
        [(UINavigationController *)self pushViewController:viewController animated:YES];
    } else if (self.navigationController) {
        [self.navigationController pushViewController:viewController animated:YES];
    } else {
        [self presentViewController:[[UINavigationController alloc] initWithRootViewController:viewController] animated:YES completion:nil];
    }
}

- (void)bdct_dismiss {
    [self bdct_dismissWithComplation:nil];
}

- (void)bdct_dismissWithComplation:(void (^)(void))completion {
    __block BOOL isCompleted = NO;
    void (^realCompletion)(void) = ^{
        if (isCompleted) {
            return;
        }
        isCompleted = YES;
        !completion ?: completion();
    };
    if (self.navigationController) {
        if (self.navigationController.viewControllers.count > 1) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                realCompletion();
            });
            if (self.navigationController.topViewController == self) {
                [CATransaction begin];
                [CATransaction setCompletionBlock:realCompletion];
                [self.navigationController popViewControllerAnimated:YES];
                [CATransaction commit];
                return;
            }
            NSUInteger index = [self.navigationController.viewControllers indexOfObject:self];
            if (index > 0) {
                [CATransaction begin];
                [CATransaction setCompletionBlock:realCompletion];
                [self.navigationController popToViewController:[self.navigationController.viewControllers btd_objectAtIndex:(index - 1)] animated:YES];
                [CATransaction commit];
                return;
            }
        }
        if (self.navigationController.presentingViewController) {
            [self.navigationController dismissViewControllerAnimated:YES completion:realCompletion];
            return;
        }
    }
    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:realCompletion];
    }
}

+ (UIViewController *)bdct_topViewController {
    return [self bdct_visibleTopViewControllerForViewController:[UIWindow.bdct_keyWindow rootViewController]] ?: [BTDResponder topViewController];
}

+ (UIViewController *)bdct_visibleTopViewControllerForViewController:(UIViewController *)vc {
    if (vc.presentedViewController != nil) {
        return [self bdct_visibleTopViewControllerForViewController:vc.presentedViewController];
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self bdct_visibleTopViewControllerForViewController:[(UINavigationController *)vc topViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self bdct_visibleTopViewControllerForViewController:[(UITabBarController *)vc selectedViewController]];
    }
    return vc;
}

@end


@implementation UIAlertController (BDCTAdditions)

- (void)bdct_showFromViewController:(UIViewController *)fromViewController {
    // 兼容部分app弹窗样式
    if ([self respondsToSelector:NSSelectorFromString(@"awe_show")]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:NSSelectorFromString(@"awe_show")];
#pragma clang diagnostic pop
    } else {
        [fromViewController presentViewController:self animated:YES completion:nil];
    }
}

@end
