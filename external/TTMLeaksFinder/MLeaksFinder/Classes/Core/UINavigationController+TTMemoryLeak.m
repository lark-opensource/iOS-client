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

#import "UINavigationController+TTMemoryLeak.h"
#import "UIViewController+TTMemoryLeak.h"
#import "TTMLUtils.h"
#import "TTMLOperationManager.h"
#import <objc/runtime.h>

static const void *const kPoppedDetailVCKey = &kPoppedDetailVCKey;

@implementation UINavigationController (TTMemoryLeak)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [TTMLUtil tt_swizzleClass:[self class] SEL:@selector(pushViewController:animated:) withSEL:@selector(tt_swizzled_pushViewController:animated:)];
        [TTMLUtil tt_swizzleClass:[self class] SEL:@selector(popViewControllerAnimated:) withSEL:@selector(tt_swizzled_popViewControllerAnimated:)];
        [TTMLUtil tt_swizzleClass:[self class] SEL:@selector(popToViewController:animated:) withSEL:@selector(tt_swizzled_popToViewController:animated:)];
        [TTMLUtil tt_swizzleClass:[self class] SEL:@selector(popToRootViewControllerAnimated:) withSEL:@selector(tt_swizzled_popToRootViewControllerAnimated:)];
    });
}

- (void)tt_swizzled_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([TTMLeaksFinder memoryLeaksConfig] && self.splitViewController) {
        id detailViewController = objc_getAssociatedObject(self, kPoppedDetailVCKey);
        if ([detailViewController isKindOfClass:[UIViewController class]]) {
            [[TTMLOperationManager sharedManager] startBuildingRetainTreeForRoot:detailViewController];
            [[TTMLOperationManager sharedManager] startDetectingSurviveObjectsForRootAfterDelay:detailViewController];
//            [detailViewController tt_startCheckMemoryLeaks];
            objc_setAssociatedObject(self, kPoppedDetailVCKey, nil, OBJC_ASSOCIATION_RETAIN);
        }
    }
    
    [self tt_swizzled_pushViewController:viewController animated:animated];
}

- (UIViewController *)tt_swizzled_popViewControllerAnimated:(BOOL)animated {
    UIViewController *poppedViewController = [self tt_swizzled_popViewControllerAnimated:animated];
    
    if (!poppedViewController) {
        return nil;
    }
    
    if ([TTMLeaksFinder memoryLeaksConfig]) {
        // Detail VC in UISplitViewController is not dealloced until another detail VC is shown
        if (self.splitViewController &&
            self.splitViewController.viewControllers.firstObject == self &&
            self.splitViewController == poppedViewController.splitViewController) {
            objc_setAssociatedObject(self, kPoppedDetailVCKey, poppedViewController, OBJC_ASSOCIATION_RETAIN);
            return poppedViewController;
        }
        
        [[TTMLOperationManager sharedManager] startBuildingRetainTreeForRoot:poppedViewController];
        [self tt_performAction:^(BOOL isCancelled) {
            if (isCancelled == NO) {
                [[TTMLOperationManager sharedManager] startDetectingSurviveObjectsForRootAfterDelay:poppedViewController];
//                 [poppedViewController tt_startCheckMemoryLeaks];
             }
            else {
                [[TTMLOperationManager sharedManager] cancelAllOperationsForRoot:poppedViewController];
            }
        } withTransitionAnimated:animated];
    }
    
    return poppedViewController;
}

- (NSArray<UIViewController *> *)tt_swizzled_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    NSArray<UIViewController *> *poppedViewControllers = [self tt_swizzled_popToViewController:viewController animated:animated];
    
    if ([TTMLeaksFinder memoryLeaksConfig] && poppedViewControllers.count > 0) {
        for (UIViewController *viewController in poppedViewControllers) {
            [[TTMLOperationManager sharedManager] startBuildingRetainTreeForRoot:viewController];
        }
        [self tt_performAction:^(BOOL isCancelled) {
            if (isCancelled == NO) {
                for (UIViewController *viewController in poppedViewControllers) {
//                    [viewController tt_startCheckMemoryLeaks];
                    [[TTMLOperationManager sharedManager] startDetectingSurviveObjectsForRootAfterDelay:viewController];
                }
            }
            else {
                for (UIViewController *viewController in poppedViewControllers) {
                    [[TTMLOperationManager sharedManager] cancelAllOperationsForRoot:viewController];
                }
            }
        } withTransitionAnimated:animated];
    }
    
    return poppedViewControllers;
}

- (NSArray<UIViewController *> *)tt_swizzled_popToRootViewControllerAnimated:(BOOL)animated {
    NSArray<UIViewController *> *poppedViewControllers = [self tt_swizzled_popToRootViewControllerAnimated:animated];
    
    if ([TTMLeaksFinder memoryLeaksConfig] && poppedViewControllers.count > 0) {
        for (UIViewController *viewController in poppedViewControllers) {
            [[TTMLOperationManager sharedManager] startBuildingRetainTreeForRoot:viewController];
        }
        [self tt_performAction:^(BOOL isCancelled) {
            if (isCancelled == NO) {
                for (UIViewController *viewController in poppedViewControllers) {
//                    [viewController tt_startCheckMemoryLeaks];
                    [[TTMLOperationManager sharedManager] startDetectingSurviveObjectsForRootAfterDelay:viewController];
                }
            }
            else {
                for (UIViewController *viewController in poppedViewControllers) {
                    [[TTMLOperationManager sharedManager] cancelAllOperationsForRoot:viewController];
                }
            }
        } withTransitionAnimated:animated];
    }
    
    return poppedViewControllers;
}

@end
