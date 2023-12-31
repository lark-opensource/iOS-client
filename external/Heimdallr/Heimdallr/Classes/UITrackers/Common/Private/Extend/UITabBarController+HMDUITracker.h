//
//  UITabBarController+HMDUITracker.h
//  Heimdallr
//
//  Created by 谢俊逸 on 24/1/2018.
//

#import <UIKit/UIKit.h>
#import "HMDUITrackableContext.h"
#import "HMDDelegateProxy.h"

@class HMDUITrackableContext;


@interface UITabBarController (HMDUITracker)<HMDUITrackable>
+ (void)hmd_startSwizzle;
@end
