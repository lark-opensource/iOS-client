/**
 * Tencent is pleased to support the open source community by making MLeaksFinder available.
 *
 * Copyright (C) 2017 THL A29 Limited, a Tencent company. All rights reserved.
 *
 * Licensed under the BSD 3-Clause License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 *
 * https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 */

#import "UIViewController+TTMemoryLeak.h"
#import <objc/runtime.h>
#import "TTMLOperationManager.h"
#import "TTMLUtils.h"

@implementation UIViewController (TTMemoryLeak)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [TTMLUtil tt_swizzleClass:[self class] SEL:@selector(dismissViewControllerAnimated:completion:) withSEL:@selector(tt_swizzled_dismissViewControllerAnimated:completion:)];
    });
}

- (void)tt_swizzled_dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    if ([TTMLeaksFinder memoryLeaksConfig] != nil) {
        UIViewController *dismissedViewController = self.presentedViewController;
        if (!dismissedViewController && self.presentingViewController) {
            dismissedViewController = self;
        }
        while (dismissedViewController != nil) {
            [viewControllers addObject:dismissedViewController];
            dismissedViewController = [dismissedViewController presentedViewController];
        }
    }
    // after call the original dismiss method, we can't access other presented
    // view controllers above the `dismissedViewController` on the stack.
    // so we need find these view controller first.
    [self tt_swizzled_dismissViewControllerAnimated:flag completion:completion];
    if (viewControllers.count == 0) {
        return;
    }
    for (UIViewController *vc in viewControllers) {
        [[TTMLOperationManager sharedManager] startBuildingRetainTreeForRoot:vc];
    }
    [self tt_performAction:^(BOOL isCancelled) {
        if (isCancelled == NO) {
            for (UIViewController *vc in viewControllers) {
//                [vc tt_startCheckMemoryLeaks];
                [[TTMLOperationManager sharedManager] startDetectingSurviveObjectsForRootAfterDelay:vc];
            }
        }
        else {
            for (UIViewController *vc in viewControllers) {
//                [vc tt_startCheckMemoryLeaks];
                [[TTMLOperationManager sharedManager] cancelAllOperationsForRoot:vc];
            }
        }
    } withTransitionAnimated:flag];
}

- (void)tt_performAction:(void(^)(BOOL isCancelled))action withTransitionAnimated:(BOOL)animated {
    if (animated == NO) {
        action(NO);
    } else {
        id<UIViewControllerTransitionCoordinator> transitionCoordinator = self.transitionCoordinator;
        NSAssert(transitionCoordinator != nil, @"where is your transitionCoordinator ?");
        [transitionCoordinator animateAlongsideTransition:nil
            completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            action(context.isCancelled);
        }];
    }
}

@end
