//
//  HMDCrashHeader.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/10.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashHeader_h
#define HMDCrashHeader_h

#include "HMDCrashDebugAssert.h"
#include "HMDCrashAsyncThreadUtils.h"

#ifdef __cplusplus
#define EXTERN_C extern "C" {
#else
#define EXTERN_C
#endif

#ifdef __cplusplus
#define EXTERN_C_END  }
#else
#define EXTERN_C_END
#endif

#define NOLINIE __attribute__((noinline))

#if defined(__GNUC__)
#define WEAK_FUNC     __attribute__((weak))
#elif defined(_MSC_VER) && !defined(_LIB)
#define WEAK_FUNC __declspec(selectany)
#else
#define WEAK_FUNC
#endif

#endif /* HMDCrashHeader_h */
