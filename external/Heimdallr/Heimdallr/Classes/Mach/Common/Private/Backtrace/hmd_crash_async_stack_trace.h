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
#define HMD_MAX_ASYNC_STACK_THREAD_NAME_LENGTH 128

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    pthread_t pre_pthread;
    thread_t pre_thread;
    pthread_t pthread;
    thread_t thread;
    char pre_thread_ids[HMD_MAX_ASYNC_STACK_THREAD_NAME_LENGTH];
    char thread_name[HMD_MAX_ASYNC_STACK_THREAD_NAME_LENGTH];
    void * backtrace[HMD_MAX_ASYNC_STACK_LENGTH];
    int length;
    int skip_length;
    bool valid;
    int pool_index;
    int async_times; // multiple_async_stack_trace
}hmd_async_stack_record_t;

void hmd_enable_async_stack_trace(void);

void hmd_disable_async_stack_trace(void);

void hmd_enable_multiple_async_stack_trace(void);

void hmd_disable_multiple_async_stack_trace(void);

hmd_async_stack_record_t *hmd_async_stack_trace_current_thread(void);
hmd_async_stack_record_t *hmd_async_stack_trace_pthread(pthread_t thread);
hmd_async_stack_record_t *hmd_async_stack_trace_mach_thread(thread_t thread);

void hmd_async_stack_reading(bool reading);

bool hmd_async_stack_trace_open(void);



#ifdef __cplusplus
} // extern "C"
#endif


#endif /* HMDCrashAsyncStackTrace_h */

