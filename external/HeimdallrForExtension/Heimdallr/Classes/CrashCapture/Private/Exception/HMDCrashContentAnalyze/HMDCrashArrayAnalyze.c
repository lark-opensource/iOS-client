//
//  HMDCrashArrayAnalyze.c
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#include "HMDCrashArrayAnalyze.h"
#include "HMDCrashFileBuffer.h"
#include "HMDCrashContentAnalyze.h"
#include "hmd_memory.h"

typedef struct {
    void *isa;
    void *firstEntry;
}HMDSingleEntryArrayIClass;

typedef struct {
    void *isa;
    unsigned long count;
    void *list;
} HMDArrayIClass;

typedef struct {
    void *isa;
    void *cow;
    
    void **list;
    unsigned int offset;
    unsigned int size;
    union {
        void *mutations;
        struct {
            unsigned int muts;
            unsigned int used;
        } entry;
    } state;
}HMDArrayMClass;

static int hmd_analyzeSingleArray(int fd, HMDCrashObjectInfo *object, char *buffer, int length);
static int hmd_analyzeArrayI(int fd, HMDCrashObjectInfo *object, char *buffer, int length);
static int hmd_analyzeArrayM(int fd, HMDCrashObjectInfo *object, char *buffer, int length);

int HMDAnalyzeNSArrayContent(int fd, HMDCrashObjectInfo *info, char *buffer, int length) {
    
    HMDClassSubtype type= HMDFetchObjectClassSubType(info);
    int result = 0;
    hmd_file_begin_json_array(fd);
    switch (type) {
        case HMDClassSubtypeNSArraySingle:
            result = hmd_analyzeSingleArray(fd, info, buffer, length);
            break;
        case HMDClassSubtypeNSArrayImmutable:
            result = hmd_analyzeArrayI(fd, info, buffer, length);
            break;
        case HMDClassSubtypeNSArrayMutable:
            result = hmd_analyzeArrayM(fd, info, buffer, length);
            break;
        default:
            break;
    }
    hmd_file_end_json_array(fd);
    return result;
    
}

#pragma mark - private
static int hmd_analyzeSingleArray(int fd, HMDCrashObjectInfo *object, char *buffer, int length) {
    HMDSingleEntryArrayIClass cls = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)object->addr, &cls, sizeof(cls)) != HMD_ESUCCESS) {
        return 0;
    }
    
    return HMDCrashWriteClassInfoWithAddress(fd, cls.firstEntry, buffer, length);
}

static int hmd_analyzeArrayI(int fd, HMDCrashObjectInfo *object, char *buffer, int length) {
    
    HMDArrayIClass cls = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)object->addr, &cls, sizeof(HMDArrayIClass)) != HMD_ESUCCESS) {
        return 0;
    }
    
    // 计算list所在的地址
    uintptr_t startPtr = (uintptr_t)&cls;
    uintptr_t ptr = (uintptr_t)&cls.list;
    ptr = ptr - startPtr + (uintptr_t)object->addr;
    
    uintptr_t content[cls.count];
    if (hmd_async_read_memory((hmd_vm_address_t)ptr, content, sizeof(uintptr_t) * cls.count) != HMD_ESUCCESS) {
        return 0;
    }

    int result = 0;
    for (int i = 0; i < cls.count; i++) {
        uintptr_t ptr = content[i];
        result = HMDCrashWriteClassInfoWithAddress(fd, (void *)ptr, buffer, length);
        if (i != cls.count - 1) {
            hmd_file_write_string(fd, ",");
        }
    }
    return true;
}

static int hmd_analyzeArrayM(int fd, HMDCrashObjectInfo *object, char *buffer, int length) {
    int result = 0;
    HMDArrayMClass cls = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)object->addr, &cls, sizeof(HMDArrayMClass)) != HMD_ESUCCESS) {
        return 0;
    }

    uintptr_t content;
    int start = cls.offset;
    int index = 0;
    for (int i = 0; i < cls.state.entry.used; i++) {
        index = start + i;
        // 环形缓冲区，从中间开始写后末尾了接着从开始的地方写
        if (index >= cls.size) {
            index = index - cls.size;
        }
        if (hmd_async_read_memory((hmd_vm_address_t)&cls.list[index], &content, sizeof(uintptr_t)) == HMD_ESUCCESS) {
            result = HMDCrashWriteClassInfoWithAddress(fd, (void *)content, buffer, length);
            if (i != cls.state.entry.used - 1) {
                hmd_file_write_string(fd, ",");
            }
        }
    }
    
    return true;
}

