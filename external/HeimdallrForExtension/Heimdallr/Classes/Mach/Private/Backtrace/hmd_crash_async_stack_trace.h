//
//  hmd_crash_async_stack_trace.h
//  HeimdallrForExtension
//
//  Created by xuminghao.eric on 2020/8/13.
//

#ifndef HMDCrashAsyncStackTrace_h
#define HMDCrashAsyncStackTrace_h

#include <stdio.h>
#include <stdbool.h>
#include <pthread/pthread.h>
#include <mach/mach_types.h>
//#include <stdatomic.h>

#define HMD_MAX_ASYNC_STACK_LENGTH 150

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    pthread_t pre_pthread;
    thread_t pre_thread;
    pthread_t pthread;
    thread_t thread;
    char thread_name[128];
    void *backtrace[HMD_MAX_ASYNC_STACK_LENGTH];
    int length;
    int skip_length;
    bool valid;
}hmd_async_stack_record_t;

void hmd_enable_async_stack_trace(void);

void hmd_disable_async_stack_trace(void);

void hmd_enable_multiple_async_stack_trace(void);

void hmd_disable_multiple_async_stack_trace(void);

hmd_async_stack_record_t *hmd_async_stack_trace_current_thread(void);
hmd_async_stack_record_t *hmd_async_stack_trace_pthread(pthread_t thread);
hmd_async_stack_record_t *hmd_async_stack_trace_mach_thread(thread_t thread);

void hmd_async_stack_reading(bool reading);



#ifdef __cplusplus
} // extern "C"
#endif


#endif /* HMDCrashAsyncStackTrace_h */

