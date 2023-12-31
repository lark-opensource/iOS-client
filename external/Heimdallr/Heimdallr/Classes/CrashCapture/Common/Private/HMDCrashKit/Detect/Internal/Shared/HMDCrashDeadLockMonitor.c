//
//  HMDCrashDeadLockMonitor.c
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/23.
//

#include "HMDCrashDeadLockMonitor.h"
#include <pthread/pthread.h>
#include <mach/mach_types.h>
#include <mach/mach_init.h>
#include <mach/thread_act.h>
#include <unistd.h>
#include "HMDCrashOnceCatch.h"
#include "HMDCrashSDKLog.h"
#include "hmd_machine_context.h"
#include "hmd_stack_cursor.h"
#include "hmd_stack_cursor_machine_context.h"
#include "HMDCompactUnwind.hpp"
#include "hmd_crash_safe_tool.h"

static _Atomic(thread_t) server_thread;
static _Atomic(bool) isCoredump = false;

static void record_catch_thread_crash(thread_t current_thread, thread_t capture_thread)
{
    thread_t c_thread = current_thread;
    
    SDKLog_warn("record catch thread deadlock");
    
    thread_suspend(capture_thread);
    
    //crash thread
    KSMC_NEW_CONTEXT(machineContext);
    machineContext->working_thread = c_thread;
    hmdmc_get_state_with_thread(capture_thread, machineContext, true);
    
    uintptr_t pc = hmdmc_get_pc(machineContext);
    uintptr_t lr = hmdmc_get_lr(machineContext);
    uintptr_t fp = hmdmc_get_fp(machineContext);
    uintptr_t sp = hmdmc_get_sp(machineContext);
    
    SDKLog("pc:%p lr:%p fp:%p sp:%p",pc,lr,fp,sp);
        
    hmd_stack_cursor cursor;
    hmdsc_initWithMachineContext(&cursor, machineContext);
    machineContext->cursor = &cursor;
    
    SDKLog_basic("=======start backtrace=======");
    while (cursor.advanceCursor(&cursor)) {
        
        hmd_vm_address_t address = cursor.stackEntry.address;
        
        hmd_async_image_list_set_reading(&shared_image_list, true);
        
        hmd_async_image_t * image = hmd_async_image_containing_address(&shared_image_list, address);
        
        if (image != NULL) {
            char *image_name = hmd_reliable_basename(image->macho_image.name);
            SDKLog_basic("%d %s %p %p",cursor.state.currentDepth-1,image_name,address,image->macho_image.header_addr);
            SDKLog_basic("%p - %p %s %s",image->macho_image.header_addr,image->macho_image.header_addr + image->macho_image.text_segment.size - 1, image_name, image->macho_image.uuid);
        } else {
            SDKLog_basic("%d %s %p %p",cursor.state.currentDepth-1,"",address,0);
        }
        
        hmd_async_image_list_set_reading(&shared_image_list, false);

        if (cursor.state.currentDepth > 100) {
            break;
        }
    }
    
    char queue_name_buffer[256] = {0};
    hmdthread_getName(capture_thread, queue_name_buffer, 256);
    SDKLog("thread_name:%s",queue_name_buffer);
    SDKLog_basic("==========end backtrace=======");
    
    thread_resume(capture_thread);
}

static void *thread_entrance(void * const context) {
    pthread_setname_np("com.hmd.crash.listener");

    thread_t thread = server_thread;
    if (thread == 0) {
        thread = mach_thread_self();
    }
    if (thread > 0) {
        thread_suspend(thread);
    }
        
    thread_t capture_thread = catch_thread();
    if (capture_thread == 0) {
        SDKLog_error("no catch thread, quit");
        return 0;
    }
    
    SDKLog("dead lock detector start working");

    int count = 0;
    for (;;) {
        usleep(500000); //500ms
        count++;
        if (count >= 10) {
            if (isCoredump) {
                SDKLog("start core dump, sleep 3s, delay dead lock callback");
                usleep(3000000); // 3S
            }
            SDKLog_error("watch exceed 5000ms, most likely deadlock happend");
            record_catch_thread_crash(thread, capture_thread);
            break;
        }
    }
    
    return 0;
}

void hmd_crash_start_coredump(void) {
    isCoredump = true;
}

bool hmd_crash_init_detect_deadlock(void) {
    bool attributes_created = false;
    pthread_attr_t attr;
    
    pthread_attr_init(&attr);
    attributes_created = true;
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);
    pthread_t thread;
    int error = pthread_create(&thread,
                               &attr,
                               &thread_entrance,
                               (void *)NULL);
    
    if (error != 0) {
        if(attributes_created)
        {
            pthread_attr_destroy(&attr);
        }
    }

    if (error == 0) {
        server_thread = pthread_mach_thread_np(thread);
        hmdmc_add_reserved_thread(server_thread);
        return true;
    }

    return false;
}

void hmd_crash_start_detect_deadlock(void) {
    if (server_thread > 0) {
        thread_resume(server_thread);
    }
}

void hmd_crash_stop_detect_deadlock(void) {
    if (server_thread > 0) {
        thread_suspend(server_thread);
    }
}

