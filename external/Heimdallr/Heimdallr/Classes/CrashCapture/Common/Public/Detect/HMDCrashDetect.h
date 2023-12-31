//
//  HMDCrashDetect.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/11.
//  Copyright © 2019 sunrunwang. All rights reserved.
//
//  非线程安全 🔒

#ifndef HMDCrashDetect_h
#define HMDCrashDetect_h

#include "HMDPublicMacro.h"

HMD_EXTERN void HMDCrashStartDetect(void) HMD_PRIVATE;

HMD_EXTERN void HMDCrashCheckHandler(void);

#endif
