//
//  hmd_thread_backtrace.c
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include "hmd_thread_backtrace.h"
#include <libgen.h>
#include "pthread_extended.h"
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <os/base.h>
#include <dispatch/dispatch.h>
#include <execinfo.h>

#include <mach/mach.h>
#include "HMDAsyncThread.h"
#include "HMDMacro.h"
#include "hmd_logger.h"
#include "hmd_mach.h"
#include "hmd_stack_cursor.h"
#include "hmd_stack_cursor_machine_context.h"
#include "hmd_stack_cursor_self_thread.h"
#include "HMDAsyncImageList.h"
#include "HMDCompactUnwind.hpp"
#include "HMDAsyncSymbolicator.h"
#include "hmd_symbolicator.h"
#include "HMDCPUUtilties.h"

typedef void(malloc_logger_t)(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result,
                              uint32_t num_hot_frames_to_skip);
extern malloc_logger_t *malloc_logger;
static malloc_logger_t *tmp_malloc_logger;

hmd_thread hmdbt_main_thread;

pthread_t hmdbt_main_pthread;

static unsigned long hmdbt_main_adress;

#pragma mark - Thread info

static bool hmdset_backtrace_thread_info(hmdbt_backtrace_t *bt) {
    if (!bt) {
        return false;
    }
    struct thread_extended_info thread_expend_info;
    kern_return_t kr = hmdthread_getExtendInfo(bt->thread_id, &thread_expend_info);
    if (kr == KERN_SUCCESS) {
        if (!(thread_expend_info.pth_flags & TH_FLAGS_IDLE))
            bt->thread_cpu_usage = ((float)thread_expend_info.pth_cpu_usage) / (float) TH_USAGE_SCALE * 100.0;
        bt->flags = thread_expend_info.pth_flags;
        bt->run_state = thread_expend_info.pth_run_state;
        bt->pth_curpri = thread_expend_info.pth_curpri;
        return true;
    }
    return false;
}

#pragma mark - Thread

bool hmdbt_all_threads(thread_act_array_t *thread_list, mach_msg_type_number_t *count) {
    if (task_threads(mach_task_self(), thread_list, count) != KERN_SUCCESS) {
        return false;
    }
    
    return true;
}

bool hmdbt_suspend_thread(thread_t thread) {
    // 关闭malloc监控回调
    // 可能会出现: 其他thread 在malloc_logger 回调中(其中有lock,并且进入lock), 随后调用hmd_suspend_environment,
    // 暂停了该线程，随后backtraceOfAllThreads 触发 malloc_logger, 导致死锁
    if (malloc_logger != NULL) {
        tmp_malloc_logger = malloc_logger;
        malloc_logger = NULL;
    }
    
    kern_return_t kr;
    bool rst = true;
    if ((kr = thread_suspend(thread)) != KERN_SUCCESS) {
        // Record the error and keep going.
        rst = false;
    }
    
    return rst;
}

bool hmdbt_suspend_threads(thread_act_array_t thread_list, mach_msg_type_number_t count, thread_t current_thread) {
    // 关闭malloc监控回调
    // 可能会出现: 其他thread 在malloc_logger 回调中(其中有lock,并且进入lock), 随后调用hmd_suspend_environment,
    // 暂停了该线程，随后backtraceOfAllThreads 触发 malloc_logger, 导致死锁
    if (malloc_logger != NULL) {
        tmp_malloc_logger = malloc_logger;
        malloc_logger = NULL;
    }
    
    kern_return_t kr;
    bool rst = true;
    for (mach_msg_type_number_t i = 0; i < count; i++) {
        thread_t thread = thread_list[i];
        if (thread != current_thread) {
            if ((kr = thread_suspend(thread)) != KERN_SUCCESS) {
                // Record the error and keep going.
                rst = false;
            }
        }
    }
    
    return rst;
}

bool hmdbt_resume_thread(thread_t thread) {
    if (tmp_malloc_logger != NULL) {
        malloc_logger = tmp_malloc_logger;
        tmp_malloc_logger = NULL;
    }
    
    kern_return_t kr;
    bool rst = true;
    if ((kr = thread_resume(thread)) != KERN_SUCCESS) {
        // Record the error and keep going.
        rst = false;
    }
    
    return rst;
}

bool hmdbt_resume_threads(thread_act_array_t thread_list, mach_msg_type_number_t count, thread_t current_thread) {
    kern_return_t kr;
    bool rst = true;
    for (mach_msg_type_number_t i = 0; i < count; i++) {
        thread_t thread = thread_list[i];
        if (thread != current_thread) {
            if ((kr = thread_resume(thread)) != KERN_SUCCESS) {
                // Record the error and keep going.
                rst = false;
            }
        }
    }
    
    if (tmp_malloc_logger != NULL) {
        malloc_logger = tmp_malloc_logger;
        tmp_malloc_logger = NULL;
    }
    
    return rst;
}

#pragma mark - Private

void HMD_NO_OPT_ATTRIBUTE _hmdbt_origin_backtrace_of_thread(hmd_thread thread, hmdbt_backtrace_t *backtrace, unsigned long skippedDepth, hmd_machine_context* machine_context, bool is_current_thread) {
    if (!backtrace->frames) {
        GCC_FORCE_NO_OPTIMIZATION return;
    }
    hmdthread_getName(thread, backtrace->name, HMDBT_MAX_NAME_LENGTH);
    hmd_stack_cursor stack_cursor;
    if (is_current_thread) {
        hmdsc_initSelfThread(&stack_cursor, (int)skippedDepth + 1);
    }
    else {
        hmdsc_initCursor(&stack_cursor, NULL, NULL);
        if (hmdmc_get_state_with_thread(thread, machine_context, false)) {
            hmdsc_initWithMachineContext(&stack_cursor, machine_context);
        }
    }
    
    stack_cursor.fast_unwind = true;
    
    size_t frame_count = 0;
    while (frame_count < HMDBT_MAX_FRAMES_COUNT && stack_cursor.advanceCursor(&stack_cursor)) {
        hmdbt_frame_t *frame = &(backtrace->frames[frame_count]);
        frame->address = stack_cursor.stackEntry.address;
        frame->stack_index = frame_count;
        frame_count++;
    }
    
    backtrace->frame_count = frame_count;
    backtrace->thread_id = (thread_t)thread;
    GCC_FORCE_NO_OPTIMIZATION return;
}

#pragma mark - Backtraces

unsigned long HMD_NO_OPT_ATTRIBUTE hmdbt_top_app_backtrace_addr_of_main_thread(unsigned long skippedDepth, bool suspend) {
    bool is_current_thread = (hmdthread_self() == hmdbt_main_thread);
    KSMC_NEW_CONTEXT(machine_context);
    size_t frame_count = 0;
    unsigned long addr = 0;
    hmd_async_image_list_set_reading(&shared_app_image_list, true);
    
    // suspend begin
    if (suspend && !is_current_thread) {
        hmdbt_suspend_thread((thread_t)hmdbt_main_thread);
    }
    
    hmd_stack_cursor stack_cursor;
    if (is_current_thread) {
        hmdsc_initSelfThread(&stack_cursor, (int)skippedDepth + 1);
    }
    else {
        hmdsc_initCursor(&stack_cursor, NULL, NULL);
        if (hmdmc_get_state_with_thread(hmdbt_main_thread, machine_context, false)) {
            hmdsc_initWithMachineContext(&stack_cursor, machine_context);
        }
    }
    
    stack_cursor.fast_unwind = true;
    
    while (frame_count < HMDBT_MAX_FRAMES_COUNT && stack_cursor.advanceCursor(&stack_cursor)) {
        uintptr_t current_addr = stack_cursor.stackEntry.address;
        if(current_addr > 0 && hmd_async_image_containing_address(&shared_app_image_list, current_addr)) {
            addr = stack_cursor.stackEntry.address;
            break;
        }
        frame_count++;
    }
    
    if (suspend && !is_current_thread) {
        hmdbt_resume_thread((thread_t)hmdbt_main_thread);
    }
    
    hmd_async_image_list_set_reading(&shared_app_image_list, false);
    GCC_FORCE_NO_OPTIMIZATION return addr;
}

void hmdbt_init_app_main_addr(void) {
    void(^mainAdressBlock)(void) = ^{
        void * main_backtrace[100];
        int len = backtrace(main_backtrace, 100);
        if (len > 2 && len <= 100){
            hmdbt_main_adress = (unsigned long)main_backtrace[len-2];
        }else{
#if DEBUG
            assert(0);
#endif
            hmdbt_main_adress = 0;
        }
    };
    if (pthread_main_np() == 0) {
        dispatch_async(dispatch_get_main_queue(), mainAdressBlock);
    }
    else {
        mainAdressBlock();
    }
}

unsigned long hmdbt_get_app_main_addr(void) {
#if DEBUG
    assert(hmdbt_main_adress != 0);
#endif
    GCC_FORCE_NO_OPTIMIZATION return hmdbt_main_adress;
}

hmdbt_backtrace_t * HMD_NO_OPT_ATTRIBUTE hmdbt_origin_backtrace_of_main_thread(unsigned long skippedDepth, bool suspend, bool fast) {
    hmdbt_backtrace_t *backtrace = calloc(1, sizeof(hmdbt_backtrace_t));
    if (fast) {
        backtrace->name = NULL;
    }
    else {
        backtrace->name = calloc(HMDBT_MAX_NAME_LENGTH, sizeof(char));
    }
    
    backtrace->frames = calloc(HMDBT_MAX_FRAMES_COUNT, sizeof(hmdbt_frame_t));
    backtrace->thread_id = (thread_t)hmdbt_main_thread;
    hmdset_backtrace_thread_info(backtrace);
    backtrace->thread_idx = 0;
    bool is_current_thread = (hmdthread_self() == hmdbt_main_thread);
    KSMC_NEW_CONTEXT(machine_context);
    
    // suspend begin
    if (suspend && !is_current_thread) {
        hmdbt_suspend_thread((thread_t)hmdbt_main_thread);
    }
    
    _hmdbt_origin_backtrace_of_thread(hmdbt_main_thread, backtrace, skippedDepth+1, machine_context, is_current_thread);
    
    if (suspend && !is_current_thread) {
        hmdbt_resume_thread((thread_t)hmdbt_main_thread);
    }
    
    // suspend over
    GCC_FORCE_NO_OPTIMIZATION return backtrace;
}

hmdbt_backtrace_t * HMD_NO_OPT_ATTRIBUTE hmdbt_origin_backtrace_of_thread(hmd_thread thread, unsigned long skippedDepth, bool suspend) {
    hmdbt_backtrace_t *backtrace = calloc(1, sizeof(hmdbt_backtrace_t));
    if (backtrace == NULL) {
        return NULL;
    }
    
    backtrace->name = calloc(HMDBT_MAX_NAME_LENGTH, sizeof(char));
    backtrace->frames = calloc(HMDBT_MAX_FRAMES_COUNT, sizeof(hmdbt_frame_t));
    backtrace->thread_id = (thread_t)thread;
    backtrace->thread_idx = 0;
    hmdset_backtrace_thread_info(backtrace);
    
    bool is_current_thread = (hmdthread_self() == thread);
    KSMC_NEW_CONTEXT(machine_context);
    // suspend begin
    if (suspend && !is_current_thread) {
        hmdbt_suspend_thread((thread_t)thread);
    }
    
    _hmdbt_origin_backtrace_of_thread(thread, backtrace, skippedDepth+1, machine_context, is_current_thread);
    
    if (suspend && !is_current_thread) {
        hmdbt_resume_thread((thread_t)thread);
    }
    
    // suspend over
    GCC_FORCE_NO_OPTIMIZATION return backtrace;
}

hmdbt_backtrace_t * HMD_NO_OPT_ATTRIBUTE hmdbt_origin_backtraces_of_all_threads(int *size, unsigned long skippedDepth, bool suspend, unsigned long max_thread_count) {
    if (size == NULL) {
        return NULL;
    }
    
    thread_act_array_t thread_list;
    mach_msg_type_number_t origin_thread_count = 0;
    hmdbt_all_threads(&thread_list, &origin_thread_count);
    mach_msg_type_number_t thread_count = origin_thread_count;
    if (max_thread_count > 0 && origin_thread_count > max_thread_count) {
        thread_count = (mach_msg_type_number_t)max_thread_count;
    }
    
    hmdbt_backtrace_t *backtraces = calloc(thread_count, sizeof(hmdbt_backtrace_t));
    if (backtraces == NULL) {
        return NULL;
    }
    
    thread_t current_thread = (thread_t)hmdthread_self();
    KSMC_NEW_CONTEXT(machine_context);
    
    for (int i = 0; i < thread_count; i++) {
        thread_t thread = thread_list[i];
        
        hmdbt_backtrace_t *backtrace = &(backtraces[i]);
        backtrace->name = calloc(HMDBT_MAX_NAME_LENGTH, sizeof(char));
        backtrace->frames = calloc(HMDBT_MAX_FRAMES_COUNT, sizeof(hmdbt_frame_t));
        backtrace->thread_id = thread;
        backtrace->thread_idx = i;
        hmdset_backtrace_thread_info(backtrace);
    }
    
    // suspend begin
    if (suspend) {
        hmdbt_suspend_threads(thread_list, thread_count, current_thread);
    }
    
    for (int i=0; i<thread_count; i++) {
        thread_t thread = thread_list[i];
        hmdbt_backtrace_t *backtrace = &(backtraces[i]);
        _hmdbt_origin_backtrace_of_thread(thread, backtrace, skippedDepth + 1, machine_context, current_thread == thread);
    }
    
    if (suspend) {
        hmdbt_resume_threads(thread_list, thread_count, current_thread);
    }
    
    for(size_t index = 0; index < origin_thread_count; index++) {
        mach_port_deallocate(mach_task_self(), thread_list[index]);
    }
    
    vm_deallocate(mach_task_self(), (vm_address_t)thread_list, sizeof(thread_act_t) * origin_thread_count);
    *size = thread_count;
    GCC_FORCE_NO_OPTIMIZATION return backtraces;
}

void hmdbt_dealloc_bactrace(hmdbt_backtrace_t **backtrace, int size) {
    if (backtrace == NULL || *backtrace == NULL) {
        return;
    }
    
    for (int i=0; i<size; i++) {
        hmdbt_backtrace_t *bt = &((*backtrace)[i]);
        if (bt->frames != NULL) {
            free(bt->frames);
            bt->frames = NULL;
        }
        
        if (bt->name != NULL) {
            free(bt->name);
            bt->name = NULL;
        }
    }
    
    free(*backtrace);
    *backtrace = NULL;
}



