//
//  HMDProtectContainers.h
//  HMDProtectProtector
//
//  Created by fengyadong on 2018/4/8.
//

#import <Foundation/Foundation.h>
#import "HMDProtect_Private.h"

#if RANGERSAPM
extern HMDProtectionArrayCreateMode HMD_Protect_Container_arrayCreateMode;
#endif

extern void HMD_Protect_toggle_Container_protection(HMDProtectCaptureBlock _Nullable);
