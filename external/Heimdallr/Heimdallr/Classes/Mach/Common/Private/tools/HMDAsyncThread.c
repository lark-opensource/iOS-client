//  HMDAsyncThread.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#include "HMDAsyncThread.h"
#define HMDLogger_LocalLevel INFO
#include "hmd_logger.h"
#include <dispatch/dispatch.h>
#include <mach/mach.h>
#include <pthread.h>
#include <sys/sysctl.h>
#include "hmd_memory.h"

hmd_thread hmdthread_self(void) {
    thread_t thread_self = mach_thread_self();
    mach_port_deallocate(mach_task_self(), thread_self);
    return (hmd_thread)thread_self;
}

void hmdthread_getName(const hmd_thread thread, char *const buffer, int bufLength) {
    if (buffer == NULL) {
        return;
    }
    
    bool success = hmdthread_getQueueName(thread, buffer, bufLength);
    if (success == false || buffer[0] == 0) {
        success = hmdthread_getThreadName(thread, buffer, bufLength);
    }
    
    if (success == false || buffer[0] == 0) {
        strlcpy(buffer, "null", bufLength);
    }
}


bool hmdthread_getThreadName(const hmd_thread thread, char *const buffer, int bufLength) {
    if (buffer == NULL || bufLength <= 0) {
        return false;
    }
    
    memset(buffer, 0, bufLength);
    
    integer_t info_data[THREAD_EXTENDED_INFO_COUNT] = {0};
    thread_info_t info = info_data;
    mach_msg_type_number_t out_size = THREAD_EXTENDED_INFO_COUNT;
    kern_return_t kr = 0;
    
    kr = thread_info((thread_t)thread, THREAD_EXTENDED_INFO, info, &out_size);
    if(kr != KERN_SUCCESS)
    {
        HMDLOG_ERROR("thread_info THREAD_EXTENDED_INFO error: %x", kr);
        return false;
    }
    
    thread_extended_info_t data = (thread_extended_info_t)info;
    
    memcpy(buffer, data->pth_name, MIN(bufLength, sizeof(data->pth_name)));
    
    return true;
}

bool hmdthread_getQueueName(const hmd_thread thread, char *const buffer, int bufLength) {
    if (buffer == NULL || bufLength <= 0) {
        return false;
    }

    memset(buffer, 0, bufLength);

    integer_t info_data[THREAD_IDENTIFIER_INFO_COUNT] = {0};
    thread_info_t info = info_data;
    mach_msg_type_number_t in_out_size = THREAD_IDENTIFIER_INFO_COUNT;
    kern_return_t kr = 0;
    
    kr = thread_info((thread_t)thread, THREAD_IDENTIFIER_INFO, info, &in_out_size);
    if(kr != KERN_SUCCESS)
    {
        HMDLOG_ERROR("thread_info THREAD_IDENTIFIER_INFO error: %x", kr);
        return false;
    }
    
    thread_identifier_info_t data = (thread_identifier_info_t)info;
    
    dispatch_queue_t* dispatch_queue_ptr = (dispatch_queue_t*)data->dispatch_qaddr;
    //thread_handle shouldn't be 0 also, because
    //identifier_info->dispatch_qaddr =  identifier_info->thread_handle + get_dispatchqueue_offset_from_proc(thread->task->bsd_info);
    // thread_handle and dispatch_queue_ptr double check
    if(dispatch_queue_ptr == NULL || data->thread_handle == 0)
    {
        return false;
    }
        
    dispatch_queue_t queue = {0};
    if (hmd_async_read_memory((hmd_vm_address_t)dispatch_queue_ptr, &queue, sizeof(queue)) != HMD_ESUCCESS) {
        
        HMDLOG_ERROR("queue_ptr read error");

        return false;
    }
    
    if(queue == NULL)
    {
        return false;
    }
                
    int offset = hmdthread_async_queue_name_offset();
    
    if (offset < 0) {
        return false;
    }
    
    const char *queue_name = NULL;
    if (hmd_async_read_memory((hmd_vm_address_t)queue+offset, &queue_name, sizeof(queue_name)) != HMD_ESUCCESS) {
        HMDLOG_ERROR("queue name ptr read error");
        return false;
    }
    
    if(queue_name == NULL)
    {
        return false;
    }
    
    if (hmd_async_read_string((hmd_vm_address_t)queue_name, buffer, bufLength) != HMD_ESUCCESS) {
        HMDLOG_ERROR("queue name read error");
        return false;
    }
    
    return true;
}

kern_return_t hmdthread_getBaseInfo(const hmd_thread thread, thread_basic_info_t base_info) {
    if(thread == THREAD_NULL) return -1;
    kern_return_t kr;
    mach_msg_type_number_t threadInfoCount = THREAD_INFO_MAX;
    
    kr = thread_info((thread_t)thread, THREAD_BASIC_INFO,(thread_info_t) base_info, &threadInfoCount);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    return kr;
}

kern_return_t hmdthread_getExtendInfo(const hmd_thread thread, thread_extended_info_t extend_info) {
    if(thread == THREAD_NULL) return -1;
    kern_return_t kr;
    mach_msg_type_number_t threadInfoCount = THREAD_INFO_MAX;
    
    kr = thread_info((thread_t)thread, THREAD_EXTENDED_INFO,(thread_info_t) extend_info, &threadInfoCount);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    return kr;
}

bool hmdthread_setPriority(const pthread_t thread, int sched_priority) {
    struct sched_param param;
    int priority;
    
    int ret = pthread_getschedparam(thread, &priority, &param);
    
    if (ret == 0) {
        param.sched_priority = sched_priority;
        
        ret = pthread_setschedparam(thread, priority, &param);
        if (ret == 0) {
            return true;
        }
        
    }
    
    return false;
}



