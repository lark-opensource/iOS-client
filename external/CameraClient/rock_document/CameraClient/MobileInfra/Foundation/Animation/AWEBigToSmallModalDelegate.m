//
//  AWEBigToSmallModalDelegate.m
//  Aweme
//
//  Created by hanxu on 2018/3/7.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#import "AWEBigToSmallModalDelegate.h"
#import "AWEBigToSmallPresentAnimation.h"
#import "AWEBigToSmallDismissAnimation.h"

@implementation AWEBigToSmallModalDelegate

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [[AWEBigToSmallPresentAnimation alloc] init];
}

- (nullable id <UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [[AWEBigToSmallDismissAnimation alloc] init];
}

@end
