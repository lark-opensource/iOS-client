//  HMDAsyncThread.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#ifndef HMD_ASYNC_THREAD_H
#define HMD_ASYNC_THREAD_H

#include <stdbool.h>
#include <mach/thread_info.h>

#include "hmd_queue_name_offset.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef uintptr_t hmd_thread;

bool hmdthread_getThreadName(const hmd_thread thread, char *const buffer, int bufLength);
bool hmdthread_getQueueName(const hmd_thread thread, char *const buffer, int bufLength);
void hmdthread_getName(const hmd_thread thread, char *const buffer, int bufLength);
kern_return_t hmdthread_getBaseInfo(const hmd_thread thread, thread_basic_info_t base_info);
kern_return_t hmdthread_getExtendInfo(const hmd_thread thread, thread_extended_info_t extend_info);
bool hmdthread_setPriority(const pthread_t thread, int sched_priority);

hmd_thread hmdthread_self(void);


#ifdef __cplusplus
}
#endif

#endif /* HMD_ASYNC_THREAD_H */
