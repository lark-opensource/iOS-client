//
//  HMDCrashContentAnalyzeBase.h
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#ifndef HMDCrashContentAnalyzeBase_h
#define HMDCrashContentAnalyzeBase_h

#include <stdio.h>
#include "HMDCrashHeader.h"
#include "HMDCrashAddressAnalyze.h"

EXTERN_C

// Compiler hints for "if" statements
#define likely_if(x) if(__builtin_expect(x,1))
#define unlikely_if(x) if(__builtin_expect(x,0))

typedef enum {
    HMDClassSubtypeNone = 0,
    HMDClassSubtypeCFArray,
    HMDClassSubtypeNSArrayMutable,
    HMDClassSubtypeNSArrayImmutable,
    HMDClassSubtypeNSArraySingle,
    HMDClassSubtypeCFString,
    HMDClassSubtypeNSDictionayMutable,
    HMDClassSubtypeNSDictionayImmutable,
    HMDClassSubtypeNSDictionaySingle,
    HMDClassSubtypeNSDictionayFrozen
} HMDClassSubtype;

typedef enum {
    HMDObjCClassTypeUnknown     = 0,   // 这种类型 默认是按照 <class : address>的格式写入。
    
    HMDObjCClassTypeAll         = 0xFF,
    HMDObjCClassTypeString      = 1 << 0,
    HMDObjCClassTypeDate        = 1 << 1,  // 尚未实现。。。
    HMDObjCClassTypeURL         = 1 << 2,
    HMDObjCClassTypeArray       = 1 << 3,
    HMDObjCClassTypeDictionary  = 1 << 4,
    HMDObjCClassTypeNumber      = 1 << 5,
} HMDObjCClassType;
HMDObjCClassType HMDFetchObjectClassType(HMDCrashObjectInfo *objectInfo);
HMDClassSubtype HMDFetchObjectClassSubType(HMDCrashObjectInfo *objectInfo);

typedef struct {
    const char *name;
    HMDObjCClassType type;
    HMDClassSubtype subType;
    int (*writeObject)(int fd, HMDCrashObjectInfo *info, char *buffer, int length);
} HMDClassData;

HMDClassData *HMDFetchObjectClassData(HMDCrashObjectInfo *object);

const char *HMDUnknownClassName(void);

int HMDWriteObjectDescription(int fd, HMDCrashObjectInfo *info, char *buffer, int length);

bool HMDWritePlaceholder(int fd, uintptr_t ptr);

EXTERN_C_END

#endif /* HMDCrashContentAnalyzeBase_h */
