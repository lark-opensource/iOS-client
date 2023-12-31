//
//  HMDCrashArrayAnalyze.h
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#ifndef HMDCrashArrayAnalyze_h
#define HMDCrashArrayAnalyze_h

#include <stdio.h>
#include "HMDCrashContentAnalyzeBase.h"

EXTERN_C

int HMDAnalyzeNSArrayContent(int fd, HMDCrashObjectInfo *object, char *buffer, int length);

EXTERN_C_END

#endif /* HMDCrashArrayAnalyze_h */
