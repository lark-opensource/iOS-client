//
//  HMDAsyncThreadState.h
//  AFgzipRequestSerializer
//
//  Created by yuanzhangjing on 2020/1/21.
//

#ifndef HMDAsyncThreadState_h
#define HMDAsyncThreadState_h

#include <stdio.h>
#include <sys/types.h>
#include <sys/ucontext.h>
#include "hmd_types.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef uintptr_t hmd_greg_t;

void hmd_thread_state_mcontext_init(hmd_thread_state_t *thread_state, const hmd_thread_state_t *mctx);

hmd_error_t hmd_thread_state_mach_thread_init(hmd_thread_state_t *thread_state, thread_t thread);

hmd_greg_t hmd_thread_state_get_fp(const hmd_thread_state_t *thread_state);

hmd_greg_t hmd_thread_state_get_sp(const hmd_thread_state_t *thread_state);

hmd_greg_t hmd_thread_state_get_lr(const hmd_thread_state_t *thread_state);

hmd_greg_t hmd_thread_state_get_pc(const hmd_thread_state_t *thread_state);

void hmd_thread_state_set_fp(hmd_thread_state_t *thread_state, uintptr_t value);

void hmd_thread_state_set_sp(hmd_thread_state_t *thread_state, uintptr_t value);

void hmd_thread_state_set_lr(hmd_thread_state_t *thread_state, uintptr_t value);

void hmd_thread_state_set_pc(hmd_thread_state_t *thread_state, uintptr_t value);


#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDAsyncThreadState_h */
