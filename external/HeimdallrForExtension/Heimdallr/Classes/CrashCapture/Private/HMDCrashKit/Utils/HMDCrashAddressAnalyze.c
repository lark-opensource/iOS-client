//
//  HMDCrashAddressAnalyze.c
//  Pods
//
//  Created by yuanzhangjing on 2019/11/26.
//

#include "HMDCrashAddressAnalyze.h"
#include <mach/vm_map.h>
#include <mach/mach_init.h>
#include "HMDAsyncImageList.h"
#include "HMDCompactUnwind.hpp"
#include "HMDObjcRuntime.h"
#include <objc/objc.h>
#include <objc/runtime.h>
#include <CoreFoundation/CoreFoundation.h>
#include "HMDObjcRuntime.h"
#include "HMDAsyncSymbolicator.h"

// Use ISA_MASK_OLD before iOS 9, in and after iOS 9, use ISA_MASK
#if __x86_64__
#   define ISA_TAG_MASK 1UL
#   define ISA_MASK     0x00007ffffffffff8UL
#elif defined(__arm64__)
#   define ISA_TAG_MASK 1UL
#   define ISA_MASK_OLD 0x00000001fffffff8UL
#   define ISA_MASK     0x0000000ffffffff8UL
#else
#   define ISA_TAG_MASK 0UL
#   define ISA_MASK     ~1UL
#endif

static bool read_isa_from_address(void *address,uintptr_t *isa_ptr) {
    uintptr_t ori_isa;
    if (hmd_async_read_memory((hmd_vm_address_t)address, &ori_isa, sizeof(ori_isa)) != HMD_ESUCCESS) {
        return false;
    }
    
#if ISA_TAG_MASK
    uintptr_t isa = ori_isa & ISA_MASK;
#if defined(__arm64__)
    if (kCFCoreFoundationVersionNumber <= kCFCoreFoundationVersionNumber_iOS_8_x_Max) {
        isa = ori_isa & ISA_MASK_OLD;
    }
#endif
#else
    uintptr_t isa = ori_isa;
#endif
    if (isa_ptr) {
        *isa_ptr = isa;
    }
    return true;
}

bool HMDCrashGetObjectInfo(void *address,HMDCrashObjectInfo *objectInfo) {
    if (address == NULL || objectInfo == NULL) {
        return false;
    }
    memset(objectInfo, 0, sizeof(*objectInfo));
    objectInfo->addr = address;
    //tagpointer
    bool is_tagpointer = hmd_objc_is_tag_pointer(address);
    objectInfo->is_tagpointer = is_tagpointer;
    //align
    bool is_aligned = ((uintptr_t)address & (sizeof(void *) - 1)) == 0;
    objectInfo->is_aligned = is_aligned;
    if (!is_aligned) {
        return is_tagpointer;
    }
    //64 46bit
    //readable
    
    uintptr_t nsobject_meta_cls = hmd_objc_NSObject_metaclass();
    uintptr_t nsproxy_meta_cls = hmd_objc_NSProxy_metaclass();
    
    uintptr_t isa = (uintptr_t)address;
    uintptr_t first_isa = 0;
    bool is_objc = false;
    for (int i = 0;i < 3;i++) {
        bool isa_valid = read_isa_from_address((void *)isa,&isa);
        if (!isa_valid || isa == 0) {
            return is_tagpointer;
        }
        
        if (first_isa == 0) {
            first_isa = isa;
        }
        
        if (nsobject_meta_cls == isa || nsproxy_meta_cls == isa) {
            is_objc = true;
            break;
        }
    }
    
    if (is_objc) {
        uintptr_t isa = first_isa;
        class_t cls;
        if (hmd_async_read_memory(isa, &cls, sizeof(cls)) != HMD_ESUCCESS) {
            return true;
        }
        objectInfo->isa = isa;
        if (hmd_objc_isMetaClass(&cls)) {
            objectInfo->is_class = true;
        } else {
            objectInfo->is_object = true;
        }
        const char *cls_name = hmd_objc_className(&cls);
        if (cls_name) {
            if (hmd_async_read_string((hmd_vm_address_t)cls_name, objectInfo->class_name, sizeof(objectInfo->class_name)) == HMD_ESUCCESS) {
                if (strcmp("__NSCFType", objectInfo->class_name) == 0) {
                    uint32_t cfinfo = 0;
                    if (hmd_async_read_memory((hmd_vm_address_t)((uintptr_t)address+sizeof(uintptr_t)), &cfinfo, sizeof(cfinfo)) == HMD_ESUCCESS) {
                        objectInfo->cf_typeID = (cfinfo >> 8) & 0x03FF; // mask up to 0x0FFF
                    }
                }
            }
        }
        return true;
    }

    //check isa
    //check rootclass or metaclass
    return is_tagpointer || is_objc;
}

bool HMDCrashGetStringInfo(void *address,HMDCrashStringInfo *stringInfo) {
    if (address == NULL || stringInfo == NULL) {
        return false;
    }
    memset(stringInfo, 0, sizeof(*stringInfo));
    if (hmd_async_read_string((hmd_vm_address_t)address, stringInfo->buffer, sizeof(stringInfo->buffer)) == HMD_ESUCCESS) {
        stringInfo->addr = address;
        return strlen(stringInfo->buffer) > 0;
    }
    return false;
}
