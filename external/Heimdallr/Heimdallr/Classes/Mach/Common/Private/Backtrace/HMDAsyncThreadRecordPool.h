//
//  HMDAsyncThreadRecordPool.h
//  Pods
//
//  Created by wangyinhui on 2022/9/14.
//
#ifndef HMDAsyncThreadRecordPool_h
#define HMDAsyncThreadRecordPool_h

#include "hmd_crash_async_stack_trace.h"


#ifdef __cplusplus
extern "C" {
#endif

bool hmd_init_async_stack_pool(size_t pool_size);

hmd_async_stack_record_t* hmd_allocate_async_stack_pool_record(thread_t tid);

void hmd_free_async_stack_pool_record(hmd_async_stack_record_t* record);

hmd_async_stack_record_t* hmd_get_async_stack_pool_record_mach_thread(thread_t thread);

hmd_async_stack_record_t* hmd_get_async_stack_pool_record_pthread(pthread_t thread);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDAsyncThreadRecordPool_h */
