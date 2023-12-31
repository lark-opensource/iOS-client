//
//  UINavigationController+HMDUITracker.m
//  Heimdallr
//
//  Created by 谢俊逸 on 23/1/2018.
//

#include <stdatomic.h>
#import "UINavigationController+HMDUITracker.h"
#import <objc/runtime.h>
#import "HMDUITrackableContext.h"
#import "HMDSwizzle.h"
#import "UIViewController+HMDUITracker.h"
#import "HMDUITracker.h"

@implementation UINavigationController (HMDUITracker)


+ (void)hmd_startSwizzle {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        hmd_swizzle_instance_method([self class], @selector(pushViewController:animated:), @selector(hmd_pushViewController:animated:));
        hmd_swizzle_instance_method([self class], @selector(popViewControllerAnimated:), @selector(hmd_popViewControllerAnimated:));
        hmd_swizzle_instance_method([self class], @selector(popToViewController:animated:), @selector(hmd_popToViewController:animated:));
    }
}


- (void)hmd_pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    if ([self hmd_trackEnabled]) {
        UIViewController *visiableVc = self.visibleViewController;
        [self.hmd_trackContext trackableEvent:@"push_controller" info:@{@"from":visiableVc.hmd_defaultTrackName?:@"",
                                                                        @"to":viewController.hmd_defaultTrackName?:@""}];
    }
    if ([[HMDUITracker sharedInstance].delegate respondsToSelector:@selector(hmdSwitchToNewVCFrom:to:)]) {
        // [[HMDUITracker sharedInstance].delegate hmdSwitchToNewVCFrom:self.visibleViewController to:viewController];
        // 目前 fromVC 和 toVC 参数尚未使用, 其原本意图是控制当前 VC 切换到哪里了
        // 但是目前切换到哪个 VC 事用 VCFinder 管理, 所以没有传递, 也不用传递
        [[HMDUITracker sharedInstance].delegate hmdSwitchToNewVCFrom:nil to:nil];
    }
    [self hmd_pushViewController:viewController animated:animated];
}

- (UIViewController *)hmd_popViewControllerAnimated:(BOOL)animated {
    UIViewController *popVC = [self hmd_popViewControllerAnimated:animated];
    if ([self hmd_trackEnabled]) {
        [self.hmd_trackContext trackableEvent:@"pop_controller" info:@{@"from":popVC.hmd_defaultTrackName?:@"",
                                                                       @"to":self.topViewController.hmd_defaultTrackName?:@""
                                                                       }];
    }
    return popVC;
}

- (NSArray<UIViewController *> *)hmd_popToViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
    UIViewController *oldTopVC = self.topViewController;
    NSArray<UIViewController *> * vcs = [self hmd_popToViewController:viewController animated:animated];
    if ([self hmd_trackEnabled]) {
        [self.hmd_trackContext trackableEvent:@"pop_controller" info:@{@"from":oldTopVC.hmd_defaultTrackName?:@"",
                                                                       @"to":self.topViewController.hmd_defaultTrackName?:@""
                                                                       }];
    }
    return vcs;    
}

#pragma mark HMDUITrackable

- (BOOL)hmd_trackEnabled
{
    return YES;
}
@end
