//
//  HMDCrashAppExitReasonMark.h
//  Pods
//
//  Created by yuanzhangjing on 2019/12/30.
//

#ifndef HMDCrashAppExitReasonMark_h
#define HMDCrashAppExitReasonMark_h

#include <stdbool.h>
#include "HMDPublicMacro.h"

HMD_EXTERN void HMDCrashKit_registerAppExitReasonMark(bool * _Nullable flag);

HMD_EXTERN void HMDCrashKit_markAppExitReasonCrash(void);

#endif /* HMDCrashAppExitReasonMark_h */
