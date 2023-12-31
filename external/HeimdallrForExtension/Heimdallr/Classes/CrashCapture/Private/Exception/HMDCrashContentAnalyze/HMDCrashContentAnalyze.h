//
//  HMDCrashContentAnalyze.h
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#ifndef HMDCrashContentAnalyze_h
#define HMDCrashContentAnalyze_h

#include <stdio.h>
#include "HMDCrashContentAnalyzeBase.h"

EXTERN_C

/**
 @return 返回当前解析的类型
 */
HMDObjCClassType HMDFetchAnalyzeTypes(void);

/**
 *可以设置多项，比如 HMDObjCClassTypeArray | HMDObjCClassTypeDictionary  默认 HMDObjCClassTypeAll
 *设置的类型全局通用，比如在这里设置了只读取 HMDObjCClassTypeArray  即使单独调用Dictionary的写入方法 也只会解析一层，内层Dictionary写入的结果仍然会是<class : address>
 */
void HMDInitWriteContentTypes(HMDObjCClassType types);

int HMDCrashWriteClassInfo(int fd, HMDCrashObjectInfo *info);

int HMDCrashWriteClassInfoWithAddress(int fd, void *object, char *buffer, int length);

EXTERN_C_END

#endif /* HMDCrashContentAnalyze_h */
