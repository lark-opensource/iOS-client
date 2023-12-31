//
//  HMDCrashURLAnalyze.h
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#ifndef HMDCrashURLAnalyze_h
#define HMDCrashURLAnalyze_h

#include <stdio.h>
#include "HMDCrashContentAnalyzeBase.h"

EXTERN_C

int HMDAnalyzeNSURLContent(int fd, HMDCrashObjectInfo *object, char *buffer, int length);

EXTERN_C_END

#endif /* HMDCrashURLAnalyze_h */
