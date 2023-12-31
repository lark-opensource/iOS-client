//
//  Jato_Machine_Types.h
//  Pods
//
//  Created by yuanzhangjing on 2021/12/13.
//

#ifndef Jato_Machine_Types_h
#define Jato_Machine_Types_h

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

#define JATO_IS_VALID_PTR(pointer) ((uintptr_t)pointer >= PAGE_SIZE)

#if defined(__arm64__)
#define JATO_POINTER_STRIP(pointer) ((uintptr_t)pointer & 0x0000000FFFFFFFFF)
#else
#define JATO_POINTER_STRIP(pointer) (pointer)
#endif

#if defined(__arm64__)

#define JATO_FP_INDEX                29
#define JATO_SP_INDEX                31
#define JATO_LR_INDEX                30
#define JATO_PC_INDEX                32

#define JATO_FP_NAME                 __fp
#define JATO_SP_NAME                 __sp
#define JATO_LR_NAME                 __lr
#define JATO_PC_NAME                 __pc
#define JATO_FAR_NAME                __far

#define JATO_THREAD_STATE            ARM_THREAD_STATE64
#define JATO_THREAD_STATE_COUNT      ARM_THREAD_STATE64_COUNT
#define JATO_EXCEPTION_STATE         ARM_EXCEPTION_STATE64
#define JATO_EXCEPTION_STATE_COUNT   ARM_EXCEPTION_STATE64_COUNT

#elif defined(__arm__)

#define JATO_FP_INDEX                7
#define JATO_SP_INDEX                13
#define JATO_LR_INDEX                14
#define JATO_PC_INDEX                15

#define JATO_FP_NAME                 __r[7]
#define JATO_SP_NAME                 __sp
#define JATO_LR_NAME                 __lr
#define JATO_PC_NAME                 __pc
#define JATO_FAR_NAME                __far

#define JATO_THREAD_STATE            ARM_THREAD_STATE
#define JATO_THREAD_STATE_COUNT      ARM_THREAD_STATE_COUNT
#define JATO_EXCEPTION_STATE         ARM_EXCEPTION_STATE
#define JATO_EXCEPTION_STATE_COUNT   ARM_EXCEPTION_STATE_COUNT

#elif defined(__x86_64__)

#define JATO_FP_INDEX                6
#define JATO_SP_INDEX                7
#define JATO_LR_INDEX                -1
#define JATO_PC_INDEX                16

#define JATO_FP_NAME                 __rbp
#define JATO_SP_NAME                 __rsp
#define JATO_PC_NAME                 __rip
#define JATO_FAR_NAME                __faultvaddr

#define JATO_THREAD_STATE            x86_THREAD_STATE64
#define JATO_THREAD_STATE_COUNT      x86_THREAD_STATE64_COUNT
#define JATO_EXCEPTION_STATE         x86_EXCEPTION_STATE64
#define JATO_EXCEPTION_STATE_COUNT   x86_EXCEPTION_STATE64_COUNT

#elif defined(__i386__)

#define JATO_FP_INDEX                6
#define JATO_SP_INDEX                7
#define JATO_LR_INDEX                -1
#define JATO_PC_INDEX                10

#define JATO_FP_NAME                 __ebp
#define JATO_SP_NAME                 __esp
#define JATO_PC_NAME                 __eip
#define JATO_FAR_NAME                __faultvaddr

#define JATO_THREAD_STATE            x86_THREAD_STATE32
#define JATO_THREAD_STATE_COUNT      x86_THREAD_STATE32_COUNT
#define JATO_EXCEPTION_STATE         x86_EXCEPTION_STATE32
#define JATO_EXCEPTION_STATE_COUNT   x86_EXCEPTION_STATE32_COUNT

#else
#error platform not support
#endif

#define JATO_GET_SP(CONTEXT)         JATO_POINTER_STRIP((CONTEXT)->__ss.JATO_SP_NAME)
#define JATO_GET_FP(CONTEXT)         JATO_POINTER_STRIP((CONTEXT)->__ss.JATO_FP_NAME)
#define JATO_GET_PC(CONTEXT)         JATO_POINTER_STRIP((CONTEXT)->__ss.JATO_PC_NAME)
#define JATO_GET_FAR(CONTEXT)        ((CONTEXT)->__es.JATO_FAR_NAME)

#define JATO_SET_SP(CONTEXT,val)     ((CONTEXT)->__ss.JATO_SP_NAME = (uintptr_t)(val))
#define JATO_SET_FP(CONTEXT,val)     ((CONTEXT)->__ss.JATO_FP_NAME = (uintptr_t)(val))
#define JATO_SET_PC(CONTEXT,val)     ((CONTEXT)->__ss.JATO_PC_NAME = (uintptr_t)(val))

#ifdef JATO_LR_NAME
#define JATO_GET_LR(CONTEXT)         JATO_POINTER_STRIP((CONTEXT)->__ss.JATO_LR_NAME)
#define JATO_SET_LR(CONTEXT,val)     ((CONTEXT)->__ss.JATO_LR_NAME = (uintptr_t)(val))
#else
#define JATO_GET_LR(CONTEXT)         (0)
#define JATO_SET_LR(CONTEXT,val)
#endif

typedef _STRUCT_MCONTEXT jato_thread_state_t;


/** The largest address value that can be represented via the jato_vm_address_t type. */
#ifdef __LP64__
#define JATO_VM_ADDRESS_MAX UINT64_MAX
#else
#define JATO_VM_ADDRESS_MAX UINT32_MAX
#endif

/** The largest address value that can be represented via the jato_vm_size_t type. */
#ifdef __LP64__
#define JATO_VM_SIZE_MAX UINT64_MAX
#else
#define JATO_VM_SIZE_MAX UINT32_MAX
#endif

#ifdef DEBUG
#define JATO_DEBUG_ASSERT   1
#define JATO_DEBUG_LOG      1
#else
//#define JATO_DEBUG_ASSERT   1
//#define JATO_DEBUG_LOG      1
#endif

#if JATO_DEBUG_ASSERT

#define JATO_ASSERT(expr) assert(expr);

#else

#define JATO_ASSERT(expr)

#endif

#include <sys/time.h>
#define JATO_TIMESTAMP \
({ \
double ret = 0; \
struct timeval tv; \
if(!gettimeofday(&tv, NULL)) { \
    ret = tv.tv_sec + ( (double)tv.tv_usec / 1000000); \
} \
ret*1000; \
})

#if JATO_DEBUG_LOG

#ifdef __FILE_NAME__
#define JATO_LOG(format, ...) do { \
fprintf(stdout, "[JATO] %s:%d ",__FILE_NAME__, __LINE__);          \
fprintf(stdout, "" format "\n", ## __VA_ARGS__);            \
} while(0)
#else
#define JATO_LOG(format, ...) do { \
fprintf(stdout, "[JATO] " format "\n", ## __VA_ARGS__);            \
} while(0)
#endif

#define JATO_START(identifier) double start_ts_##identifier = JATO_TIMESTAMP;
#define JATO_END_AND_LOG(identifier) \
double end_ts_##identifier = JATO_TIMESTAMP; \
JATO_LOG("%s dur = %.3fms",#identifier,end_ts_##identifier - start_ts_##identifier); \

#else

#define JATO_LOG(format, ...)

#define JATO_START(identifier)
#define JATO_END_AND_LOG(identifier)

#endif

#ifdef __cplusplus
}  // extern "C"
#endif


#endif /* Jato_Machine_Types_h */
