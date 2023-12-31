//
//  UITabBarController+HMDUITracker.m
//  Heimdallr
//
//  Created by 谢俊逸 on 24/1/2018.
//

#include <stdatomic.h>
#import "UITabBarController+HMDUITracker.h"
#import <objc/runtime.h>
#import "HMDSwizzle.h"
#import "HMDUITrackableContext.h"
#import "UIViewController+HMDUITracker.h"

@interface UITabBarController()
@end


@implementation UITabBarController (HMDUITracker)

+ (void)hmd_startSwizzle
{
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        hmd_swizzle_instance_method([self class], @selector(setSelectedIndex:), @selector(hmd_setSelectedIndex:));
    }
}

#pragma mark Swizzle

- (void)hmd_setSelectedIndex:(NSUInteger)selectedIndex
{
    if (self.selectedIndex != selectedIndex) {
        [self.hmd_trackContext trackableEvent:@"tab_select_index" info:@{@"controller":self.hmd_defaultTrackName?:@"",
                                                                         @"index":@(selectedIndex)
                                                                         }];
    }
    [self hmd_setSelectedIndex:selectedIndex];
}

#pragma mark HMDUITrackable

- (BOOL)hmd_trackEnabled {
    return YES;
}

@end
