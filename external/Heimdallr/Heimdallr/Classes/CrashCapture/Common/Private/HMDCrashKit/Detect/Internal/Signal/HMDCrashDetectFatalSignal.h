//
//  HMDCrashDetectFatalSignal.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/14.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashDetectFatalSignal_h
#define HMDCrashDetectFatalSignal_h

#include "HMDCrashHeader.h"
#include "HMDCrashDetect_Private.h"
#include <stdbool.h>
EXTERN_C
    void HMDCrashDetect_signal_start(void);
    void HMDCrashDetect_signal_end(void);
    bool HMDCrashDetect_signal_check(void);
EXTERN_C_END
#endif /* HMDCrashDetectFatalSignal_h */
