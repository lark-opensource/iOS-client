//
//  HMDWatchDogAppExitReasonMark.h
//  Pods
//
//  Created by ByteDance on 2023/9/18.
//

#ifndef HMDWatchDogAppExitReasonMark_h
#define HMDWatchDogAppExitReasonMark_h

#include <stdbool.h>
#include "HMDPublicMacro.h"

HMD_EXTERN void HMDWatchDog_registerAppExitReasonMark(bool * _Nullable flag);

HMD_EXTERN void HMDWatchDog_markAppExitReasonWatchDog(bool isWatchdog);

HMD_EXTERN void HMDWeakWatchDog_registerAppExitReasonMark(bool * _Nullable flag);

HMD_EXTERN void HMDWeakWatchDog_markAppExitReasonWatchDog(bool isWeakWatchdog);

#endif /* HMDWatchDogAppExitReasonMark_h */
