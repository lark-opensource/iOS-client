//
//  HMDCrashImagesState.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/22.
//

#ifndef HMDCrashImagesState_h
#define HMDCrashImagesState_h

#include <stdio.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

extern void HMDCrashMarkImagesFinish(void);

extern long long HMDCrashWaitForImagesSetupFinish(long long timeout);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashImagesState_h */
