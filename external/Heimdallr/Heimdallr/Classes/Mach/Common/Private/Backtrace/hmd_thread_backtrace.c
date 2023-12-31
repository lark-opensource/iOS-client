//
//  hmd_thread_backtrace.c
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include <stdatomic.h>
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
#include "hmd_types.h"

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
        
        if (len > 2 && len <= 100) {
            hmdbt_main_adress = (unsigned long)main_backtrace[len-2];
        } DEBUG_ELSE
    };
    
    if (pthread_main_np() == 0) {
        dispatch_async(dispatch_get_main_queue(), mainAdressBlock);
        return;
    }
    
    mainAdressBlock();
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

struct hmd_stack_range {
    uintptr_t stacktop;
    uintptr_t stackbot;
};
typedef struct hmd_stack_range hmd_stack_range;

static hmd_stack_range main_thread_stack_range(void) {
    
    static hmd_stack_range main_thread_range;
    
    static atomic_bool onceFlag;
    if(atomic_load_explicit(&onceFlag, memory_order_acquire)) {
        return main_thread_range;
    }
    
    main_thread_range.stacktop = (uintptr_t) pthread_get_stackaddr_np(hmdbt_main_pthread);
    main_thread_range.stackbot = main_thread_range.stacktop - pthread_get_stacksize_np(hmdbt_main_pthread);
    
    atomic_store_explicit(&onceFlag, true, memory_order_release);
    
    return main_thread_range;
}

static bool hmd_is_valid_frame_pointer(hmd_stack_range range, uintptr_t location) {
    
    // FP 16 bits aligned
    if((((uint64_t)location) & UINT64_C(0xF)) != 0)
        return false;
    
    // FP is on stack
    return location >= range.stackbot && location < range.stacktop;
}

unsigned main_thread_stack(uintptr_t *buffer, unsigned max_store_size) {
    
    if(buffer == NULL || max_store_size < 1)
        DEBUG_RETURN(0);

    KSMC_NEW_CONTEXT(machine_context);
    machine_context->thread = (thread_t)hmdbt_main_thread;
    hmdmc_get_state(machine_context);
    
    uintptr_t frame = hmdmc_get_fp(machine_context);
    uintptr_t pc = hmdmc_get_pc(machine_context);
    
    if(frame == 0){
        HMDLOG_ERROR("fp are empty, backtrace failure");
        return 0;
    }
    
    hmd_stack_range stack_range = main_thread_stack_range();
    
    unsigned stack_count = 0;
    
    if(!hmd_is_valid_frame_pointer(stack_range, frame)) {
        return 0;
    }
    
    buffer[stack_count++] = pc;
    
    max_store_size -= 1;
    
    uintptr_t next_frame;
    
    while (max_store_size-- > 0) {
        
        next_frame = *(uintptr_t *)frame; // get next fp from current fp
        next_frame = (next_frame & NONE_PAC_MASK);
        
        uintptr_t *lr_ptr = (uintptr_t *)frame + 1; //the last lr is near the fp
        
        uintptr_t retaddr = *lr_ptr;
        
        if (retaddr == 0) {
            return stack_count;
        }
        
        buffer[stack_count++] = HMD_POINTER_STRIP(retaddr);

        if (!hmd_is_valid_frame_pointer(stack_range, next_frame)) {
            return stack_count;
        }

        frame = next_frame;
    }
    return stack_count;
}

hmdbt_backtrace_t* hmdbt_fast_backtrace_of_main_thread(int skippedDepth, bool suspend) {
    // suspend begin
    bool is_current_thread = (hmdthread_self() == hmdbt_main_thread);
    uintptr_t stack_frames[HMDBT_MAX_FRAMES_COUNT] = {0};
    if (suspend && !is_current_thread) {
        hmdbt_suspend_thread((thread_t)hmdbt_main_thread);
    }
    if(is_current_thread) {
        skippedDepth ++;
    }

    int frame_cnt = main_thread_stack(stack_frames, HMDBT_MAX_FRAMES_COUNT);
    
    if (suspend && !is_current_thread) {
        hmdbt_resume_thread((thread_t)hmdbt_main_thread);
    }
    
    hmdbt_backtrace_t *backtrace = calloc(1, sizeof(hmdbt_backtrace_t));
    if (backtrace == NULL) {
        return NULL;
    }
    frame_cnt -= skippedDepth;
    backtrace->frames = calloc(frame_cnt, sizeof(hmdbt_frame_t));
    backtrace->thread_id = (thread_t)hmdbt_main_thread;
    backtrace->frame_count = frame_cnt;
    for(int i = 0; i < frame_cnt; i++) {
        hmdbt_frame_t *frame = &(backtrace->frames[i]);
        frame->address = stack_frames[i+skippedDepth];
        frame->stack_index = i;
    }
    
    // suspend over
    GCC_FORCE_NO_OPTIMIZATION return backtrace;
}
