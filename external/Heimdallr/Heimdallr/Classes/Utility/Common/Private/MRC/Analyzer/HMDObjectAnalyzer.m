//
//  HMDOCObjectAnalyzer.m
//  AWEAnywhereArena
//
//  Created by xushuangqing on 2022/8/15.
//

#include <mach/mach.h>
#import <stdatomic.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>
//#import "HMDALogProtocol.h"
#import "HMDObjectAnalyzer.h"
#import "HMDObjectAnalyzerInternal.h"
#import "HMDTaggedPointerAnalyzer.h"

#if __has_feature(objc_arc)
#error This file must be compiled with MRC. Use -fno-objc-arc flag.
#endif

typedef NS_ENUM(NSUInteger, HMDObjCRuntimeEnv) {
    HMDObjCRuntimeEnvNotDetermined = 0,
    HMDObjCRuntimeEnvNotSupported,
    HMDObjCRuntimeEnvArm64,
    HMDObjCRuntimeEnvArm64PAC,
    
    HMDObjCRuntimeEnvImpossible
};

# if __arm64__

struct isa_bits_arm64 {
    uintptr_t nonpointer        : 1;
    uintptr_t has_assoc         : 1;
    uintptr_t has_cxx_dtor      : 1;
    uintptr_t shiftcls          : 33;
    uintptr_t magic             : 6;
    uintptr_t weakly_referenced : 1;
    uintptr_t unused_or_deallocating : 1; //ObjC 源码的不同版本，这一位有不同实现
    uintptr_t has_sidetable_rc  : 1;
    uintptr_t extra_rc          : 19;
};

struct isa_bits_arm64_pac {
    uintptr_t nonpointer        : 1;
    uintptr_t has_assoc         : 1;
    uintptr_t weakly_referenced : 1;
    uintptr_t shiftcls_and_sig  : 52;
    uintptr_t has_sidetable_rc  : 1;
    uintptr_t extra_rc          : 8;
};

static bool objCRuntimeIsArm64WithoutPAC(uintptr_t rawIsa, uintptr_t retainCount,
                                         atomic_uintptr_t * _Nonnull deallocatingMask,
                                         atomic_uintptr_t * _Nonnull deallocatingValue) {
    DEBUG_ASSERT(deallocatingMask != NULL && deallocatingValue != NULL);
    
# define ISA_MAGIC_VALUE 0x000001a000000001ULL
# define ISA_MAGIC_MASK_Bits (ISA_MAGIC_VALUE >> 36)
    struct isa_bits_arm64 isaBits = *(struct isa_bits_arm64 *)(&rawIsa);
    if (isaBits.nonpointer && isaBits.magic == ISA_MAGIC_MASK_Bits && isaBits.has_sidetable_rc == 0 && isaBits.extra_rc >= retainCount - 1 && isaBits.extra_rc <= retainCount) {
        struct isa_bits_arm64 deallocatingObjMask = {};
        deallocatingObjMask.nonpointer |= ~deallocatingObjMask.nonpointer;
        deallocatingObjMask.magic |= ~deallocatingObjMask.magic;
        struct isa_bits_arm64 deallocatingObjValue = {
            .nonpointer = 1,
            .magic = ISA_MAGIC_MASK_Bits,
        };
# undef ISA_MAGIC_MASK_Bits
# undef ISA_MAGIC_VALUE
        if (isaBits.extra_rc == retainCount - 1) {
            deallocatingObjMask.unused_or_deallocating |= ~deallocatingObjMask.unused_or_deallocating;
            deallocatingObjValue.unused_or_deallocating = 1;
        }
        else {
            deallocatingObjMask.extra_rc |= ~deallocatingObjMask.extra_rc;
            deallocatingObjMask.has_sidetable_rc |= ~deallocatingObjMask.has_sidetable_rc;
            deallocatingObjValue.extra_rc = 0;
            deallocatingObjValue.has_sidetable_rc = 0;
        }
        *deallocatingMask = *((uintptr_t *)&deallocatingObjMask);
        *deallocatingValue = *((uintptr_t *)&deallocatingObjValue);
        return true;
    }
    return false;
}

static bool objCRuntimeIsArm64WithPAC(uintptr_t rawIsa, uintptr_t retainCount,
                                      atomic_uintptr_t * _Nonnull deallocatingMask,
                                      atomic_uintptr_t * _Nonnull deallocatingValue) {
    DEBUG_ASSERT(deallocatingMask != NULL && deallocatingValue != NULL);
    
    struct isa_bits_arm64_pac isaBits = *(struct isa_bits_arm64_pac *)(&rawIsa);
    if (isaBits.nonpointer && isaBits.has_sidetable_rc == 0 && isaBits.extra_rc == retainCount) {
        struct isa_bits_arm64_pac deallocatingObjMask = {};
        deallocatingObjMask.nonpointer |= ~deallocatingObjMask.nonpointer;
        deallocatingObjMask.extra_rc |= ~deallocatingObjMask.extra_rc;
        deallocatingObjMask.has_sidetable_rc |= ~deallocatingObjMask.has_sidetable_rc;
        struct isa_bits_arm64_pac deallocatingObjValue = {};
        deallocatingObjValue.nonpointer = 1;
        deallocatingObjValue.extra_rc = 0;
        deallocatingObjValue.has_sidetable_rc = 0;
        *deallocatingMask = *((uintptr_t *)&deallocatingObjMask);
        *deallocatingValue = *((uintptr_t *)&deallocatingObjValue);
        return true;
    }
    return false;
}

# endif

static HMDObjCRuntimeEnv estimatedObjCRuntimeEnv(atomic_uintptr_t * _Nonnull deallocatingMask,
                                                 atomic_uintptr_t * _Nonnull deallocatingValue) {
    DEBUG_ASSERT(deallocatingMask != NULL && deallocatingValue != NULL);
    
    HMDObjCRuntimeEnv runtimeEnv = HMDObjCRuntimeEnvNotSupported;
# if __arm64__
    NSObject *testObject = [[NSObject alloc] init];
    [testObject retain]; //retainCount = 2;
    if (testObject) {
        uintptr_t rawTestIsa = ((uintptr_t *)testObject)[0];
        //需要判断是 PAC 与否
        if (objCRuntimeIsArm64WithoutPAC(rawTestIsa, [testObject retainCount], deallocatingMask, deallocatingValue)) {
            runtimeEnv = HMDObjCRuntimeEnvArm64;
        }
        else if (objCRuntimeIsArm64WithPAC(rawTestIsa, [testObject retainCount], deallocatingMask, deallocatingValue)) {
            runtimeEnv = HMDObjCRuntimeEnvArm64PAC;
        }
    }
    [testObject release];
    [testObject release];
# else
# endif
    return runtimeEnv;
}

static _Atomic(HMDObjCRuntimeEnv) shared_objcRuntimeEnv = HMDObjCRuntimeEnvNotDetermined;
static atomic_uintptr_t shared_deallocatingMask = -1;
static atomic_uintptr_t shared_deallocatingValue = -1;

static void initialize_shared_objcRuntimeEnv_if_needed(void);

bool HMDObjectAnalyzer_objectIsDeallocating(__unsafe_unretained NSObject *object) {
    
    // [1] 如果当前对象为 nil 返回 false
    if (object == nil) return false;
    
    // [2] 如果当前对象没有内存分配 返回 false
    if (malloc_size(object) == 0) return false;
    
    // [3] 初始化 objcRuntimeEnv 如果有必要的话
    initialize_shared_objcRuntimeEnv_if_needed();
    
    // [4] 如果当前环境不支持的话 返回 false
    if (shared_objcRuntimeEnv == HMDObjCRuntimeEnvNotSupported) return false;
    
    DEBUG_ASSERT(shared_objcRuntimeEnv != HMDObjCRuntimeEnvNotDetermined &&
                 shared_objcRuntimeEnv < HMDObjCRuntimeEnvImpossible);
    
    // [5] 读取 ISA 数据
    uintptr_t rawIsa = hmd_objc_analyzer_read_rawISA_return_zero_if_not_exist(object);
    
    // [6] ALog 好像没发依赖 Alog
//    HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"[KVO] rawIsa: <%#" PRIXPTR ">, "
//                                             "deallocatingMask <%#" PRIXPTR ">, "
//                                             "deallocatingValue <%#" PRIXPTR ">",
//                                              rawIsa, shared_deallocatingMask, shared_deallocatingValue);
    
    // [7] 判断 然后返回值
    return (rawIsa & shared_deallocatingMask) == shared_deallocatingValue;
}

bool HMDObjectAnalyzer_objectIsDeallocating_fast_unsafe(void * _Nullable object) {
    
    // [1] 如果当前对象为 nil 返回 false
    if (object == nil) return false;
    
    // [2] 初始化 objcRuntimeEnv 如果有必要的话
    initialize_shared_objcRuntimeEnv_if_needed();
    
    // [3] 如果当前环境不支持的话 返回 false
    if (shared_objcRuntimeEnv == HMDObjCRuntimeEnvNotSupported) return false;
    
    DEBUG_ASSERT(shared_objcRuntimeEnv != HMDObjCRuntimeEnvNotDetermined &&
                 shared_objcRuntimeEnv < HMDObjCRuntimeEnvImpossible);
    
    // [4] 读取 ISA 数据
    uintptr_t rawIsa = hmd_objc_analyzer_read_rawISA_return_zero_if_not_exist(object);
    
    // [5] 判断 然后返回值
    return (rawIsa & shared_deallocatingMask) == shared_deallocatingValue;
}

static void initialize_shared_objcRuntimeEnv_if_needed(void) {
    if (shared_objcRuntimeEnv == HMDObjCRuntimeEnvNotDetermined) {
        shared_objcRuntimeEnv = estimatedObjCRuntimeEnv(&shared_deallocatingMask, &shared_deallocatingValue);
    }
}

#pragma mark - 需要在 HMDObjectAnalyzer_initialization 调用返回 YES 后可调用

#pragma mark - Macro

#pragma mark Imported Macro

/*
 * @APPLE_LICENSE_HEADER_START@
 *
 * Copyright (c) 2018 Apple Inc.  All Rights Reserved.
 *
 * This file contains Original Code and/or Modifications of Original Code
 * as defined in and that are subject to the Apple Public Source License
 * Version 2.0 (the 'License'). You may not use this file except in
 * compliance with the License. Please obtain a copy of the License at
 * http://www.opensource.apple.com/apsl/ and read it before using this
 * file.
 *
 * The Original Code and all software distributed under the License are
 * distributed on an 'AS IS' basis, WITHOUT WARRANTY OF ANY KIND, EITHER
 * EXPRESS OR IMPLIED, AND APPLE HEREBY DISCLAIMS ALL SUCH WARRANTIES,
 * INCLUDING WITHOUT LIMITATION, ANY WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE, QUIET ENJOYMENT OR NON-INFRINGEMENT.
 * Please see the License for the specific language governing rights and
 * limitations under the License.
 *
 * @APPLE_LICENSE_HEADER_END@
 */

// Define SUPPORT_PACKED_ISA=1 on platforms that store the class in the isa
// field as a maskable pointer with other data around it.
#if (!__LP64__  ||  TARGET_OS_WIN32  ||  \
     (TARGET_OS_SIMULATOR && !TARGET_OS_MACCATALYST && !__arm64__))
#   define SUPPORT_PACKED_ISA 0
#else
#   define SUPPORT_PACKED_ISA 1
#endif

#if SUPPORT_PACKED_ISA

    // extra_rc must be the MSB-most field (so it matches carry/overflow flags)
    // nonpointer must be the LSB (fixme or get rid of it)
    // shiftcls must occupy the same bits that a real class pointer would
    // bits + RC_ONE is equivalent to extra_rc + 1
    // RC_HALF is the high bit of extra_rc (i.e. half of its range)

    // future expansion:
    // uintptr_t fast_rr : 1;     // no r/r overrides
    // uintptr_t lock : 2;        // lock for atomic property, @synch
    // uintptr_t extraBytes : 1;  // allocated with extra bytes

# if __arm64__
// ARM64 simulators have a larger address space, so use the ARM64e
// scheme even when simulators build for ARM64-not-e.
#   if __has_feature(ptrauth_calls) || TARGET_OS_SIMULATOR
#     define ISA_MASK          0x007ffffffffffff8ULL
#     define ISA_MASK_NONE_PAC 0x0000000ffffffff8ULL
#     define ISA_MAGIC_MASK    0x0000000000000001ULL
#     define ISA_MAGIC_VALUE   0x0000000000000001ULL
#     define ISA_HAS_CXX_DTOR_BIT 0
#     define ISA_BITFIELD                                                      \
        uintptr_t nonpointer        : 1;                                       \
        uintptr_t has_assoc         : 1;                                       \
        uintptr_t weakly_referenced : 1;                                       \
        uintptr_t shiftcls_and_sig  : 52;                                      \
        uintptr_t has_sidetable_rc  : 1;                                       \
        uintptr_t extra_rc          : 8
#     define RC_ONE   (1ULL<<56)
#     define RC_HALF  (1ULL<<7)
#   else
#     define ISA_MASK          0x0000000ffffffff8ULL
#     define ISA_MASK_NONE_PAC 0x0000000ffffffff8ULL
#     define ISA_MAGIC_MASK    0x000003f000000001ULL
#     define ISA_MAGIC_VALUE   0x000001a000000001ULL
#     define ISA_HAS_CXX_DTOR_BIT 1
#     define ISA_BITFIELD                                                      \
        uintptr_t nonpointer        : 1;                                       \
        uintptr_t has_assoc         : 1;                                       \
        uintptr_t has_cxx_dtor      : 1;                                       \
        uintptr_t shiftcls          : 33; /*MACH_VM_MAX_ADDRESS 0x1000000000*/ \
        uintptr_t magic             : 6;                                       \
        uintptr_t weakly_referenced : 1;                                       \
        uintptr_t unused            : 1;                                       \
        uintptr_t has_sidetable_rc  : 1;                                       \
        uintptr_t extra_rc          : 19
#     define RC_ONE   (1ULL<<45)
#     define RC_HALF  (1ULL<<18)
#   endif

# elif __x86_64__
#   define ISA_MASK          0x00007ffffffffff8ULL
#   define ISA_MASK_NONE_PAC 0x00007ffffffffff8ULL
#   define ISA_MAGIC_MASK    0x001f800000000001ULL
#   define ISA_MAGIC_VALUE   0x001d800000000001ULL
#   define ISA_HAS_CXX_DTOR_BIT 1
#   define ISA_BITFIELD                                                        \
      uintptr_t nonpointer        : 1;                                         \
      uintptr_t has_assoc         : 1;                                         \
      uintptr_t has_cxx_dtor      : 1;                                         \
      uintptr_t shiftcls          : 44; /*MACH_VM_MAX_ADDRESS 0x7fffffe00000*/ \
      uintptr_t magic             : 6;                                         \
      uintptr_t weakly_referenced : 1;                                         \
      uintptr_t unused            : 1;                                         \
      uintptr_t has_sidetable_rc  : 1;                                         \
      uintptr_t extra_rc          : 8
#   define RC_ONE   (1ULL<<56)
#   define RC_HALF  (1ULL<<7)

# else
#   error unknown architecture for packed isa
# endif

#endif

#pragma mark - Typedef

typedef enum : uint8_t {
    HMDOCAStatusUnknown,
    HMDOCAStatusNotExist,
    HMDOCAStatusFetched,
    
    HMDOCAStatusImpossible
} HMDOCAStatus;

typedef struct objc_object_data {
    uintptr_t isa;
} objc_object_data_t;

#pragma mark - Variable Declaration

static HMDOCAStatus analyzerInitializationStatus = HMDOCAStatusUnknown;

static bool read_memory(void * _Nonnull from, void * _Nonnull to, vm_size_t size, bool unsafe_memory_access);

#pragma mark - Public Interface

bool HMDObjectAnalyzer_initialization(void) {
    HMDOCAStatus currentStatus;
    if((currentStatus = __atomic_load_n(&analyzerInitializationStatus, __ATOMIC_ACQUIRE)) == HMDOCAStatusUnknown) {
        
        if(HMDTaggedPointerAnalyzer_initialization()) {
            currentStatus = HMDOCAStatusFetched;
        } DEBUG_ELSE
        
        if(currentStatus != HMDOCAStatusFetched)
           currentStatus = HMDOCAStatusNotExist;
        
        __atomic_store_n(&analyzerInitializationStatus, currentStatus, __ATOMIC_RELEASE);
    }
    
    DEBUG_ASSERT(currentStatus < HMDOCAStatusImpossible);
    DEBUG_ASSERT(currentStatus != HMDOCAStatusUnknown);
    
    return currentStatus == HMDOCAStatusFetched;
}

bool HMDObjectAnalyzer_isInitialized(void) {
    return __atomic_load_n(&analyzerInitializationStatus, __ATOMIC_ACQUIRE) == HMDOCAStatusFetched;
}

HMDUnsafeClass _Nullable HMDObjectAnalyzer_unsafeObjectGetClass(HMDUnsafeObject _Nullable object) {
    DEBUG_ASSERT(HMDObjectAnalyzer_isInitialized());
    
    if(object == NULL) return NULL;
    
    if(HMDTaggedPointerAnalyzer_isTaggedPointer(object))
        return HMDTaggedPointerAnalyzer_taggedPointerGetClass(object);
    
    if(!VM_ADDRESS_CONTAIN(object)) return NULL;

    objc_object_data_t object_data;
    if(read_memory(object, &object_data, sizeof(object_data), false)) {
        
        uintptr_t rawIsa = object_data.isa;
        
#if SUPPORT_PACKED_ISA
        rawIsa &= ISA_MASK_NONE_PAC;
#endif
        return (HMDUnsafeClass)rawIsa;
    }
    
    return NULL;
}

bool HMDObjectAnalyzer_unsafeObjectGetClassName(HMDUnsafeObject _Nonnull object, uint8_t * _Nonnull name, size_t length) {
    DEBUG_ASSERT(HMDObjectAnalyzer_isInitialized());
    
    if(object != NULL && name != NULL && length > 0) {
        HMDUnsafeClass _Nullable maybeClass = HMDObjectAnalyzer_unsafeObjectGetClass(object);
        if(maybeClass != NULL) {
            return HMDClassAnalyzer_unsafeClassGetName(maybeClass, name, length);
        }
    }
    return false;
}

static bool read_memory(void * _Nonnull from, void * _Nonnull to, vm_size_t size, bool unsafe_memory_access) {
    if(from == NULL || to == NULL) DEBUG_RETURN(false);
    
    if(unsafe_memory_access) {
        // direct memory access
        memcpy(to, from, size);
        return true;
    } else {
        // safe memory access
        vm_size_t storage_size = size;
        if(vm_read_overwrite(mach_task_self(), (vm_address_t)from, size, (vm_address_t)to, &storage_size) == KERN_SUCCESS)
            return true;
        else return false;
    }
}
