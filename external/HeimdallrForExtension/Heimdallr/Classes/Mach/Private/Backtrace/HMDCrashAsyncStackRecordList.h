//
//  HMDCrashAsyncStackRecordList.hpp
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/10/20.
//

#ifndef HMDCrashAsyncStackRecordList_hpp
#define HMDCrashAsyncStackRecordList_hpp

#include "hmd_crash_async_stack_trace.h"
#include <stdio.h>

#ifdef __cplusplus

#include "HMDAsyncSafeLinkedList.hpp"

extern "C" {
#endif

typedef struct hmd_async_stack_record_list {
#ifdef __cplusplus
    hmd::async_safe::linked_list<hmd_async_stack_record_t *> *_list;
    hmd::async_safe::linked_list<hmd_async_stack_record_t *> *_main_thread_list;
#else
    void *_list;
    void *_main_thread_list;
#endif
} hmd_async_stack_record_list;

void hmd_nasync_stack_record_list_init(hmd_async_stack_record_list *list);
void hmd_nasync_stack_record_free(hmd_async_stack_record_list *list);
    
void* hmd_nasync_stack_record_append(hmd_async_stack_record_list *list, hmd_async_stack_record_t *record);
void hmd_nasync_stack_record_remove(hmd_async_stack_record_list *list, hmd_async_stack_record_t *record);
void hmd_nasync_stack_record_remove_node(hmd_async_stack_record_list *list, void *node);

void hmd_async_stack_record_list_set_reading(hmd_async_stack_record_list *list, bool enable);

hmd_async_stack_record_t *hmd_async_stack_record_with_mach_thread(hmd_async_stack_record_list *list, thread_t thread);
hmd_async_stack_record_t *hmd_async_stack_record_with_pthread(hmd_async_stack_record_list *list, pthread_t pthread);
hmd_async_stack_record_t *hmd_async_stack_record_with_current_thread(hmd_async_stack_record_list *list);

#ifdef __cplusplus
} // extern "C"
#endif


#endif /* HMDCrashAsyncStackRecordList_hpp */
