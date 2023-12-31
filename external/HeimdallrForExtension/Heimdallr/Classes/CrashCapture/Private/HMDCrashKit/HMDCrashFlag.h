//
//  HMDCrashFlag.h
//  Pods
//
//  Created by yuanzhangjing on 2019/12/30.
//

#ifndef HMDCrashFlag_h
#define HMDCrashFlag_h

#include <stdio.h>
#include <stdbool.h>
#ifdef __cplusplus
extern "C" {
#endif

void HMDCrashInjectFlag(bool * _Nullable flag);

void HMDCrashMarkFlag(void);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashFlag_h */
