//
//  HMDCrashDictionaryAnalyze.c
//  Heimdallr
//
//  Created by bytedance on 2020/4/14.
//

#include "HMDCrashDictionaryAnalyze.h"
#include "HMDCrashFileBuffer.h"
#include "HMDCrashContentAnalyze.h"
#include "hmd_memory.h"

#import <objc/runtime.h>

#ifdef __LP64__
#define HMD_PTR_SIZE 8
#else
#define HMD_PTR_SIZE 4
#endif


// __NSSingleEntryDictionaryI
typedef struct {
    void *isa;
#ifdef __LP64__
    unsigned long count :58;
    unsigned long szidx :6;
#else
    unsigned long count :26;
    unsigned long szidx :6;
#endif
    void *list;
} HMDDictionaryIClass;

// __NSDictionaryI
typedef struct {
    void *isa;
    void *key;
    void *value;
}HMDSingleEntryDictionaryIClass;

/**
 * __NSFrozenDictionaryM  其实是不可变字典 但struct结构和 __NSDictionaryM一样
 * __NSDictionaryM
 */
typedef struct {
    void *isa;
    void **buffer;
    union {
        struct {
            uint64_t mutations;
        };
        struct {
            uint32_t muts;
            uint32_t other;
        };
        struct {
            int mutbits :31;
            int copyKeys :1;
            int used :25;
            int kvo :1;
            int szidx :6;
        };
    }state;
}HMDDictionaryMClass;


// https://github.com/ROCm-Developer-Tools/llvm-project/blob/master/lldb/source/Plugins/Language/ObjC/NSDictionary.cpp
static const uint64_t NSDictionaryCapacities[] = {
    0, 3, 7, 13, 23, 41, 71, 127, 191, 251, 383, 631, 1087, 1723,
    2803, 4523, 7351, 11959, 19447, 31231, 50683, 81919, 132607,
    214519, 346607, 561109, 907759, 1468927, 2376191, 3845119,
    6221311, 10066421, 16287743, 26354171, 42641881, 68996069,
    111638519, 180634607, 292272623, 472907251
};

static const size_t NSDictionaryNumSizeBuckets = sizeof(NSDictionaryCapacities) / sizeof(uint64_t);

static int hmd_analyzeSingleDictionary(int fd, HMDCrashObjectInfo *object, char *buffer, int length);
static int hmd_analyzeDictionaryI(int fd, HMDCrashObjectInfo *object, char *buffer, int length);
static int hmd_analyzeDictionaryM(int fd, HMDCrashObjectInfo *object, char *buffer, int length);

int HMDAnalyzeNSDictionaryContent(int fd, HMDCrashObjectInfo *object, char *buffer, int length) {
    int result = 0;
    hmd_file_begin_json_object(fd);
    HMDClassSubtype type = HMDFetchObjectClassSubType(object);
    switch (type) {
        case HMDClassSubtypeNSDictionaySingle:
            result = hmd_analyzeSingleDictionary(fd, object, buffer, length);
            break;
        case HMDClassSubtypeNSDictionayImmutable:
            result = hmd_analyzeDictionaryI(fd, object, buffer, length);
            break;
        case HMDClassSubtypeNSDictionayMutable:
        case HMDClassSubtypeNSDictionayFrozen:
            result = hmd_analyzeDictionaryM(fd, object, buffer, length);
            break;
        default:
            break;
    }
    hmd_file_end_json_object(fd);
    return result;
}

#pragma mark - private
/**
 * https://github.com/ROCm-Developer-Tools/llvm-project/blob/master/lldb/source/Plugins/Language/ObjC/NSDictionary.cpp
 */
static uint64_t hmd_getSize(int szidx) {
    return (szidx) >= NSDictionaryNumSizeBuckets ?
      0 : NSDictionaryCapacities[szidx];
}

static int hmd_analyzeSingleDictionary(int fd, HMDCrashObjectInfo *object, char *buffer, int length) {
    HMDSingleEntryDictionaryIClass cls = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)object->addr , &cls, sizeof(cls)) != HMD_ESUCCESS) {
        return 0;
    }
    
    int keyResult = HMDCrashWriteClassInfoWithAddress(fd, (void *)cls.key, buffer, length);
    hmd_file_write_string(fd, ":");
    int ValueResult = HMDCrashWriteClassInfoWithAddress(fd, (void *)cls.value, buffer, length);
    
    return keyResult && ValueResult;
}

static int hmd_analyzeDictionaryI(int fd, HMDCrashObjectInfo *object, char *buffer, int length) {
    HMDDictionaryIClass cls = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)object->addr, &cls, sizeof(HMDDictionaryIClass)) != ERR_SUCCESS) {
        return 0;
    }
    
    int result = 0;
    
    // 计算list所在的地址
    uintptr_t startPtr = (uintptr_t)&cls;
    uintptr_t ptr = (uintptr_t)&cls.list;
    ptr = ptr - startPtr + (uintptr_t)object->addr;
    
    uintptr_t m_keys_ptr = (uintptr_t)ptr;
    uintptr_t m_values_ptr = (uintptr_t)ptr + HMD_PTR_SIZE;
    
    uint64_t total = hmd_getSize(cls.szidx) * 2;
    
    uint64_t offset = 0;
    uintptr_t content = 0;
    int validCycleCounts = 0;

    for (int i = 0; i < total; i++) {
        offset = 2 * i * sizeof(uintptr_t);
        // 读key
        if (hmd_async_read_memory((hmd_vm_address_t)m_keys_ptr + offset, &content, sizeof(uintptr_t)) != HMD_ESUCCESS || !content) {
            continue;
        }
        
        result = HMDCrashWriteClassInfoWithAddress(fd, (void *)content, buffer, length);
        hmd_file_write_string(fd, ":");
        
        if (hmd_async_read_memory((hmd_vm_address_t)m_values_ptr + offset, &content, sizeof(uintptr_t)) != HMD_ESUCCESS || !content) {
            // 写了key值， 需要写一个占位的value值保证数据格式
            HMDWritePlaceholder(fd, m_values_ptr);
            continue;
        }
        
        result = HMDCrashWriteClassInfoWithAddress(fd, (void *)content, buffer, length);
        
        if (result) {
            validCycleCounts++;
        }
        
        if (validCycleCounts == cls.count) {
            break;
        }
        hmd_file_write_string(fd, ",");
    }
    return result;
}

static int hmd_analyzeDictionaryM(int fd, HMDCrashObjectInfo *object, char *buffer, int length) {
    HMDDictionaryMClass cls = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)object->addr, &cls, sizeof(HMDDictionaryMClass)) != HMD_ESUCCESS) {
        return 0;
    }
    
    // https://github.com/ROCm-Developer-Tools/llvm-project/blob/master/lldb/source/Plugins/Language/ObjC/NSDictionary.cpp
    uint64_t size = hmd_getSize(cls.state.szidx);
    uintptr_t m_keys_ptr = (uintptr_t)cls.buffer;
    uintptr_t m_values_ptr = (uintptr_t)cls.buffer + (HMD_PTR_SIZE * size);
    
    int validCycleCounts = 0; // 数据存储不是连续的。 避免不必要的循环
    int result = 0;
    uint64_t offset = 0;
    uintptr_t content = 0;
    for (int i = 0; i < size; i ++) {
        offset = i * sizeof(uintptr_t);
        // 读key
        if (hmd_async_read_memory((hmd_vm_address_t)m_keys_ptr + offset, &content, sizeof(uintptr_t)) != HMD_ESUCCESS || !content) {
            continue;
        }
        
        result = HMDCrashWriteClassInfoWithAddress(fd, (void *)content, buffer, length);
        hmd_file_write_string(fd, ":");
        
        if (hmd_async_read_memory((hmd_vm_address_t)m_values_ptr + offset, &content, sizeof(uintptr_t)) != HMD_ESUCCESS || !content) {
            // 写了key值， 需要写一个占位的value值保证数据格式
            HMDWritePlaceholder(fd, m_values_ptr);
            continue;
        }
        
        result = HMDCrashWriteClassInfoWithAddress(fd, (void *)content, buffer, length);
        
        if (result) {
            validCycleCounts++;
        }
        
        if (validCycleCounts == cls.state.used) {
            break;
        }
        hmd_file_write_string(fd, ",");
    }
    return result;
}
