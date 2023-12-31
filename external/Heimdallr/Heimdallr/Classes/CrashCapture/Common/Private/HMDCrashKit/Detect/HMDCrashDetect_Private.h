//
//  HMDCrashDetect_Private.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/11.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashDetect_Private_h
#define HMDCrashDetect_Private_h

#include "HMDCrashHeader_Public.h"
#include "HMDCrashHeader.h"
#include <stdbool.h>
EXTERN_C

#define needDiskSpace 256*1024

typedef void (*invoke_t)(void);

typedef struct {
    HMDCrashType type;
    invoke_t start;
    invoke_t end;
    bool(*check)(void);
} hmd_detector_t;

void HMDCrashStopDetect(void);


EXTERN_C_END

#endif /* HMDCrashDetect_Private_h */
