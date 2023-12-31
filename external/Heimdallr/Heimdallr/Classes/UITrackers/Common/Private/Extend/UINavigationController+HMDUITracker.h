//
//  UINavigationController+HMDUITracker.h
//  Heimdallr
//
//  Created by 谢俊逸 on 23/1/2018.
//

#import <UIKit/UIKit.h>
#import "HMDUITrackableContext.h"

@interface UINavigationController (HMDUITracker)<HMDUITrackable>
+ (void)hmd_startSwizzle;
@end
