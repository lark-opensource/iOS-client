//
//  HMDCrashDetectCPP.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/12.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashDetectCPP_h
#define HMDCrashDetectCPP_h

#include "HMDCrashHeader.h"
#include "HMDCrashDetect_Private.h"

EXTERN_C

    void HMDCrashDetect_cpp_start(void);
    void HMDCrashDetect_cpp_end(void);
    bool HMDCrashDetect_cpp_check(void);

EXTERN_C_END

#endif /* HMDCrashDetectCPP_h */
