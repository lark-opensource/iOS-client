//
//  UIControl+HMDUITracker.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/10.
//

#import <stdatomic.h>
#import "UIControl+HMDUITracker.h"
#import "HMDSwizzle.h"

@implementation UIControl (HMDUITracker)

+ (void)hmd_startSwizzle {
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        hmd_swizzle_instance_method([self class], @selector(sendAction:to:forEvent:), @selector(hmd_sendAction:to:forEvent:));
    }
}

- (BOOL)hmd_trackEnabled {
    return YES;
}

#pragma mark - Swizzled method

- (void)hmd_sendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
    if ([self hmd_trackEnabled]) {
        if ([self isKindOfClass:[UIButton class]]) {
            UIButton *btn = ((UIButton *)self);
            NSString *titleName = btn.currentTitle;
            NSString *backgroundImageName = [btn.currentBackgroundImage accessibilityIdentifier];
            NSString *currentImageName = [btn.currentImage accessibilityIdentifier];
            CGRect frame = btn.frame;
            NSString *frameString = [NSString stringWithFormat:@"rect(%0.1f,%0.1f,%0.1f,%0.1f)",frame.origin.x,frame.origin.y,frame.size.width,frame.size.height];
            
            [self.hmd_trackContext trackableDidTrigger:@{@"target":NSStringFromClass([target class])?:@"nil",
                                                         @"action":NSStringFromSelector(action)?:@"NULL",
                                                         @"title":titleName?:@"nil",
                                                         @"backgroundImage":backgroundImageName?:@"nil",
                                                         @"currentImage":currentImageName?:@"nil",
                                                         @"frame":frameString?:@"nil"
                                                         }];
        }
        else if ([self isKindOfClass:[UISwitch class]]) {
            UISwitch *aSwitch = (UISwitch *)self;
            NSString *switchValue = aSwitch.isOn ? @"1" : @"0";
            [self.hmd_trackContext trackableDidTrigger:@{@"target":NSStringFromClass([target class])?:@"nil",
                                                         @"action":NSStringFromSelector(action)?:@"NULL",
                                                         @"switchValue":switchValue
                                                         }];
        }
        else if ([self isKindOfClass:[UISegmentedControl class]]) {
            UISegmentedControl *segmentControl = (UISegmentedControl *)self;
            NSString *selectedIndex = [NSString stringWithFormat:@"%ld",(long)segmentControl.selectedSegmentIndex];
            [self.hmd_trackContext trackableDidTrigger:@{@"target":NSStringFromClass([target class])?:@"nil",
                                                         @"action":NSStringFromSelector(action)?:@"NULL",
                                                         @"selectedIndex":selectedIndex?:@"nil"
                                                         }];
        }
        else {
            [self.hmd_trackContext trackableDidTrigger:@{@"target":NSStringFromClass([target class])?:@"nil",
                                                         @"action":NSStringFromSelector(action)?:@"NULL"
                                                         }];
        }
    }
    [self hmd_sendAction:action to:target forEvent:event];
}
@end
