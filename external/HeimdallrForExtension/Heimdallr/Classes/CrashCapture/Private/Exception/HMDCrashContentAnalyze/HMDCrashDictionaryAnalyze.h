//
//  HMDCrashDictionaryAnalyze.h
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#ifndef HMDCrashDictionaryAnalyze_h
#define HMDCrashDictionaryAnalyze_h

#include <stdio.h>
#include "HMDCrashContentAnalyzeBase.h"

EXTERN_C

int HMDAnalyzeNSDictionaryContent(int fd, HMDCrashObjectInfo *object, char *buffer, int length);

EXTERN_C_END

#endif /* HMDCrashDictionaryAnalyze_h */
