//
//  HMDCrashAsyncThreadUtils.h
//  Pods
//
//  Created by yuanzhangjing on 2019/12/26.
//

#ifndef HMDCrashAsyncThreadUtils_h
#define HMDCrashAsyncThreadUtils_h

#include <stdio.h>

#ifdef __cplusplus
extern "C" {
#endif

void hmd_perform_on_mainthread(void(^block)(void));

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashAsyncThreadUtils_h */
