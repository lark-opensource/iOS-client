//
//  UIGestureRecognizer+HMDUITracker.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/3/7.
//

#include <stdatomic.h>
#import "UIGestureRecognizer+HMDUITracker.h"
#import "UIViewController+HMDUITracker.h"
#import "HMDUITrackableContext.h"
#import "UIView+HMDController.h"
#import "HMDSwizzle.h"
#import "HMDUITrackableContext.h"
#import "HeimdallrUtilities.h"
#import "HMDCompactUnwind.hpp"

@implementation UIGestureRecognizer (HMDUITracker)

+ (void)hmd_startSwizzle {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        hmd_swizzle_instance_method([self class], @selector(setState:), @selector(hmd_setState:));
        hmd_swizzle_instance_method([self class], @selector(initWithTarget:action:), @selector(hmd_initWithTarget:action:));
    }
}

- (instancetype)hmd_initWithTarget:(id)target action:(SEL)action {
    [self hmd_initWithTarget:target action:action];
    if (target && action && hmd_async_share_image_list_has_setup()) {
        // 判断target是否来自app
        if (hmd_async_image_containing_address(&shared_app_image_list, (unsigned long)[target class])) {
            [self.hmd_trackContext setAnalysisInfo:@{@"gesture":NSStringFromClass(self.class),
                                                     @"target":NSStringFromClass([target class]) ?: @"default_target",
                                                     @"action":NSStringFromSelector(action)
            }];
        }
    }
    return self;
}

- (void)hmd_setState:(UIGestureRecognizerState)state
{
    // 修改为 UIGestureRecognizerStateEnded，如果监控 UIGestureRecognizerStateBegan，那么后续可能会 cancel、fail 等，并不代表发生了 action
    if (UIGestureRecognizerStateEnded == state) {
        UIViewController *controller = [self.view hmd_controller];
        if (controller && self.hmd_trackContext.analysisInfo) {
            [[controller hmd_trackContext] trackableEvent:@"gesture"
                                                     info:self.hmd_trackContext.analysisInfo];
        }
    }
    [self hmd_setState:state];
}

- (BOOL)hmd_trackEnabled
{
    return YES;
}
@end
