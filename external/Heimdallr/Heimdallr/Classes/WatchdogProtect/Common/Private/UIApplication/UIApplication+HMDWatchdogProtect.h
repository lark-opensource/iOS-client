//
//  UIApplication+HMDWatchdogProtect.h
//  Pods
//
//  Created by 白昆仑 on 2020/4/9.
//

#import <UIKit/UIKit.h>
#import "HMDWatchdogProtectDefine.h"
#import "HMDMacro.h"

NS_ASSUME_NONNULL_BEGIN

HMD_EXTERN void hmd_wp_toggle_application_protection(HMDWPExceptionCallback _Nullable callback);

NS_ASSUME_NONNULL_END
