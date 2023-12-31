//
//  hmd_types.h
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/2.
//

#ifndef hmd_types_h
#define hmd_types_h

#ifdef __cplusplus
extern "C" {
#endif

#include <assert.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>  // for snprintf
#include <unistd.h>

#include <TargetConditionals.h>
#include <mach/mach.h>
#include <sys/ucontext.h>

#define HMD_IS_VALID_PTR(pointer) ((uintptr_t)pointer >= PAGE_SIZE)

#if defined(__arm64__)
#define HMD_POINTER_STRIP(pointer) ((uintptr_t)pointer & 0x0000000FFFFFFFFF)
#else
#define HMD_POINTER_STRIP(pointer) (pointer)
#endif

#if defined(__x86_64__)
#define HMD_ISALIGNED(a) ((((uintptr_t)(a)) & 0xf) == 0)
#elif defined(__i386__)
#define HMD_ISALIGNED(a) ((((uintptr_t)(a)) & 0xf) == 8)
#elif defined(__arm__) || defined(__arm64__)
#define HMD_ISALIGNED(a) ((((uintptr_t)(a)) & 0x1) == 0)
#endif

#if defined(__arm64__)

#define HMD_FP_INDEX                29
#define HMD_SP_INDEX                31
#define HMD_LR_INDEX                30
#define HMD_PC_INDEX                32

#define HMD_FP_NAME                 __fp
#define HMD_SP_NAME                 __sp
#define HMD_LR_NAME                 __lr
#define HMD_PC_NAME                 __pc
#define HMD_FAR_NAME                __far

#define HMD_THREAD_STATE            ARM_THREAD_STATE64
#define HMD_THREAD_STATE_COUNT      ARM_THREAD_STATE64_COUNT
#define HMD_EXCEPTION_STATE         ARM_EXCEPTION_STATE64
#define HMD_EXCEPTION_STATE_COUNT   ARM_EXCEPTION_STATE64_COUNT

#elif defined(__arm__)

#define HMD_FP_INDEX                7
#define HMD_SP_INDEX                13
#define HMD_LR_INDEX                14
#define HMD_PC_INDEX                15

#define HMD_FP_NAME                 __r[7]
#define HMD_SP_NAME                 __sp
#define HMD_LR_NAME                 __lr
#define HMD_PC_NAME                 __pc
#define HMD_FAR_NAME                __far

#define HMD_THREAD_STATE            ARM_THREAD_STATE
#define HMD_THREAD_STATE_COUNT      ARM_THREAD_STATE_COUNT
#define HMD_EXCEPTION_STATE         ARM_EXCEPTION_STATE
#define HMD_EXCEPTION_STATE_COUNT   ARM_EXCEPTION_STATE_COUNT

#elif defined(__x86_64__)

#define HMD_FP_INDEX                6
#define HMD_SP_INDEX                7
#define HMD_LR_INDEX                -1
#define HMD_PC_INDEX                16

#define HMD_FP_NAME                 __rbp
#define HMD_SP_NAME                 __rsp
#define HMD_PC_NAME                 __rip
#define HMD_FAR_NAME                __faultvaddr

#define HMD_THREAD_STATE            x86_THREAD_STATE64
#define HMD_THREAD_STATE_COUNT      x86_THREAD_STATE64_COUNT
#define HMD_EXCEPTION_STATE         x86_EXCEPTION_STATE64
#define HMD_EXCEPTION_STATE_COUNT   x86_EXCEPTION_STATE64_COUNT

#elif defined(__i386__)

#define HMD_FP_INDEX                6
#define HMD_SP_INDEX                7
#define HMD_LR_INDEX                -1
#define HMD_PC_INDEX                10

#define HMD_FP_NAME                 __ebp
#define HMD_SP_NAME                 __esp
#define HMD_PC_NAME                 __eip
#define HMD_FAR_NAME                __faultvaddr

#define HMD_THREAD_STATE            x86_THREAD_STATE32
#define HMD_THREAD_STATE_COUNT      x86_THREAD_STATE32_COUNT
#define HMD_EXCEPTION_STATE         x86_EXCEPTION_STATE32
#define HMD_EXCEPTION_STATE_COUNT   x86_EXCEPTION_STATE32_COUNT

#else
#error platform not support
#endif

#define HMD_GET_SP(CONTEXT)         HMD_POINTER_STRIP((CONTEXT)->__ss.HMD_SP_NAME)
#define HMD_GET_FP(CONTEXT)         HMD_POINTER_STRIP((CONTEXT)->__ss.HMD_FP_NAME)
#define HMD_GET_PC(CONTEXT)         HMD_POINTER_STRIP((CONTEXT)->__ss.HMD_PC_NAME)
#define HMD_GET_FAR(CONTEXT)        ((CONTEXT)->__es.HMD_FAR_NAME)

#define HMD_SET_SP(CONTEXT,val)     ((CONTEXT)->__ss.HMD_SP_NAME = (uintptr_t)(val))
#define HMD_SET_FP(CONTEXT,val)     ((CONTEXT)->__ss.HMD_FP_NAME = (uintptr_t)(val))
#define HMD_SET_PC(CONTEXT,val)     ((CONTEXT)->__ss.HMD_PC_NAME = (uintptr_t)(val))

#ifdef HMD_LR_NAME
#define HMD_GET_LR(CONTEXT)         HMD_POINTER_STRIP((CONTEXT)->__ss.HMD_LR_NAME)
#define HMD_SET_LR(CONTEXT,val)     ((CONTEXT)->__ss.HMD_LR_NAME = (uintptr_t)(val))
#else
#define HMD_GET_LR(CONTEXT)         (0)
#define HMD_SET_LR(CONTEXT,val)
#endif

typedef _STRUCT_MCONTEXT hmd_thread_state_t;


/** The largest address value that can be represented via the hmd_vm_address_t type. */
#ifdef __LP64__
#define HMD_VM_ADDRESS_MAX UINT64_MAX
#else
#define HMD_VM_ADDRESS_MAX UINT32_MAX
#endif

/** The largest address value that can be represented via the hmd_vm_size_t type. */
#ifdef __LP64__
#define HMD_VM_SIZE_MAX UINT64_MAX
#else
#define HMD_VM_SIZE_MAX UINT32_MAX
#endif

/** The largest offset value that can be represented via the hmd_vm_off_t type. */
#define HMD_VM_OFF_MAX PTRDIFF_MAX

/** The smallest offset value that can be represented via the hmd_vm_off_t type. */
#define HMD_VM_OFF_MIN PTRDIFF_MIN

/** VM address type.
 * @ingroup hmd_async */
typedef vm_address_t hmd_vm_address_t;

/** VM size type.
 * @ingroup hmd_async */
typedef vm_size_t hmd_vm_size_t;

/** VM offset type.
 * @ingroup hmd_async */
typedef ptrdiff_t hmd_vm_off_t;

/** An invalid address value. */
#define HMD_VM_ADDRESS_INVALID HMD_VM_ADDRESS_MAX

#ifdef DEBUG

#define HMDCF_ASSERT(expr) assert(expr)

#else

#define HMDCF_ASSERT(expr)

#endif /* HMDCF_RELEASE_BUILD */

/**
 * @ingroup hmd_async
 * Error return codes.
 */
typedef enum {
    /** Success */
    HMD_ESUCCESS = 0,

    /** Unknown error (if found, is a bug) */
    HMD_EUNKNOWN,

    /** The output file can not be opened or written to */
    HMD_OUTPUT_ERR,

    /** No memory available (allocation failed) */
    HMD_ENOMEM,

    /** Unsupported operation */
    HMD_ENOTSUP,

    /** Invalid argument */
    HMD_EINVAL,

    /** Internal error */
    HMD_EINTERNAL,

    /** Access to the specified resource is denied. */
    HMD_EACCESS,

    /** The requested resource could not be found. */
    HMD_ENOTFOUND,

    /** The input data is in an unknown or invalid format. */
    HMD_EINVALID_DATA,
} hmd_error_t;

#ifdef __cplusplus
}  // extern "C"
#endif

#endif /* hmd_types_h */
