//
//  UIViewController+AWEDismissPresentVCStack.m
//  PresentDemo
//
//  Created by 郝一鹏 on 2017/7/11.
//  Copyright © 2017年 郝一鹏. All rights reserved.
//

#import "UIViewController+AWEDismissPresentVCStack.h"
#import <CreativeKit/UIApplication+ACC.h>
#import <objc/runtime.h>

@implementation UIViewController (AWEDismissPresentVCStack)

- (void)acc_dismissModalStackAnimated:(bool)animated completion:(void (^)(void))completion {
    UIView *fullscreenSnapshot = [[UIApplication acc_currentWindow] snapshotViewAfterScreenUpdates:false];
    [self.presentedViewController.view addSubview:fullscreenSnapshot];
    [self dismissViewControllerAnimated:animated completion:completion];
}

- (UIViewController *)acc_rootPresentingViewController
{
    UIViewController *presentingViewController = self.presentingViewController;

    while (presentingViewController.presentingViewController) {
        presentingViewController = presentingViewController.presentingViewController;
    }

    return presentingViewController;
}

@end

@implementation UIViewController (AWETag)

- (void)setAcc_stuioTag:(NSUInteger)acc_stuioTag
{
    objc_setAssociatedObject(self, @selector(acc_stuioTag), @(acc_stuioTag), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSUInteger)acc_stuioTag
{
    return [objc_getAssociatedObject(self, @selector(acc_stuioTag)) unsignedIntegerValue];
}

@end
