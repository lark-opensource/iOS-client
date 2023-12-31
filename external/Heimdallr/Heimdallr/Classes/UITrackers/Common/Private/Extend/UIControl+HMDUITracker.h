//
//  UIControl+HMDUITracker.h
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/10.
//

#import <UIKit/UIKit.h>
#import "HMDUITrackableContext.h"

@interface UIControl (HMDUITracker)<HMDUITrackable>
+ (void)hmd_startSwizzle;
@end
