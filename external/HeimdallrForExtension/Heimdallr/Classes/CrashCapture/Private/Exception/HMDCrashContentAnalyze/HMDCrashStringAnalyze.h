//
//  HMDCrashStringAnalyze.h
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#ifndef HMDCrashStringAnalyze_h
#define HMDCrashStringAnalyze_h

#include <stdio.h>
#include "HMDCrashContentAnalyzeBase.h"

EXTERN_C

int HMDAnalyzeStringContent(int fd, HMDCrashObjectInfo *object, char *buffer, int length);

bool HMDReadStringContent(HMDCrashObjectInfo *object, char *buffer, int length);

EXTERN_C_END

#endif /* HMDCrashStringAnalyze_h */
