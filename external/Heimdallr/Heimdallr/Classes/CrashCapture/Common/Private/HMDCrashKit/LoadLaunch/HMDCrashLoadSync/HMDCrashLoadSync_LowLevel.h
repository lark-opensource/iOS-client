//
//  HMDCrashLoadSync_LowLevel.h
//  Heimdallr
//
//  Created by sunrunwang on 2024/08/08.
//

#ifndef HMDCrashLoadSync_LowLevel_h
#define HMDCrashLoadSync_LowLevel_h

#import "HMDMacro.h"

HMD_EXTERN_SCOPE_BEGIN

bool HMDCrashLoadSync_starting(void);

void HMDCrashLoadSync_setStarting(bool starting);

bool HMDCrashLoadSync_started(void);

void HMDCrashLoadSync_setStarted(bool started);

void HMDCrashLoadSync_trackerCallback(void);

HMD_EXTERN_SCOPE_END

#if __OBJC__

#import <Foundation/Foundation.h>

HMD_EXTERN NSString * _Nullable HMDCrashLoadSync_currentDirectory(void);

#endif

#endif /* HMDCrashLoadSync_LowLevel_h */
