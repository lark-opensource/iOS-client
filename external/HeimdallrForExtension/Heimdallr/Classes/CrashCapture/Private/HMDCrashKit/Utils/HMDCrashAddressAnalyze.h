//
//  HMDCrashAddressAnalyze.h
//  Pods
//
//  Created by yuanzhangjing on 2019/11/26.
//

#ifndef HMDCrashAddressAnalyze_h
#define HMDCrashAddressAnalyze_h
#import <mach/vm_region.h>

#include <stdio.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    void *addr;
    bool is_tagpointer;
    bool is_aligned;
    bool is_object;
    bool is_class;
    uintptr_t isa;
    uint32_t cf_typeID;
    char class_name[128];
}HMDCrashObjectInfo;
bool HMDCrashGetObjectInfo(void *address,HMDCrashObjectInfo *objectInfo);

typedef struct {
    void *addr;
    char buffer[256];
}HMDCrashStringInfo;
bool HMDCrashGetStringInfo(void *address,HMDCrashStringInfo *stringInfo);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashAddressAnalyze_h */
