//
//  HMDThreadLockTool.c
//
//  Created by wangyinhui on 2021/8/6.
//

#include "HMDThreadLockTool.h"
#include "hmd_thread_backtrace.h"
#include <mach/thread_state.h>
#include "hmd_machine_context.h"
#include "hmd_symbolicator.h"
#include "HMDLockHeader.h"
#include "hmd_memory.h"
#include <dispatch/once.h>

static const char *waiting_symbol_list[] = {
    "___psynch_mutexwait",
    "___psynch_rw_rdlock",
    "___psynch_rw_wrlock",
    "_semaphore_wait_trap",
    "___ulock_wait",
    "_kevent_id"
};
static HMDDeadlockType waiting_lock_types[] = {
    HMDDeadlockTypeMutex,
    HMDDeadlockTypeReadWrite,
    HMDDeadlockTypeReadWrite,
    HMDDeadlockTypeSemaphore,
    HMDDeadlockTypeUnfairLock,
    HMDDeadlockTypeGCD
};

int is_thread_waiting(thread_t thread_id){
    thread_basic_info_t basic_info_th;
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    thread_info_count = THREAD_INFO_MAX;
    kern_return_t kr = thread_info(thread_id, THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    basic_info_th = (thread_basic_info_t)thinfo;
    if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
        if(basic_info_th->run_state == TH_STATE_WAITING){
            return 1;
        }
    }
    return -1;
}

int fetch_waiting_lock_index(uintptr_t pc){
    static hmd_symbol_range waiting_symbol_ranges[sizeof(waiting_symbol_list)/sizeof(void *)];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        for (int i = 0; i < sizeof(waiting_symbol_list) / sizeof(void *); i++) {
            const char *symbol = waiting_symbol_list[i];
            hmd_symbol_range *range = &waiting_symbol_ranges[i];
            hmd_symbol_address_range("libsystem_kernel.dylib", symbol, range);
        }
    });
    
    for (int i = 0; i < sizeof(waiting_symbol_list) / sizeof(void *); i++) {
        hmd_symbol_range range = waiting_symbol_ranges[i];
        if(range.dli_start_saddr > 0 && range.dli_end_saddr > 0) {
            if (pc > range.dli_start_saddr && pc < range.dli_end_saddr) {
                return i;
            }
        }
    }
    return -1;
}

uint64_t fetch_mutex_lock(const hmd_machine_context* const context){
    uintptr_t ptr = hmdmc_register_value(context, 0);
    if (__builtin_available(iOS 10.0, *)) {
        hmd_pthread_mutex mtx;
        if (hmd_async_read_memory(ptr, &mtx, sizeof(hmd_pthread_mutex)) == HMD_ESUCCESS) {
            return *(uint64_t*)(((uintptr_t)mtx.m_tid + 0x7ul) & ~0x7ul);
        }
    }
    return 0;
}

thread_t fetch_unfair_lock(const hmd_machine_context* const context){
    uintptr_t ptr = hmdmc_register_value(context, 1);
    uintptr_t retval = hmdmc_register_value(context, 2);
    if (retval == UINT32_MAX) {
        //ptr 是dispatch_thread_event_s地址
        dispatch_thread_event_s event_t = {0};
        if (hmd_async_read_memory((hmd_vm_address_t)ptr, &event_t, sizeof(uintptr_t)) == HMD_ESUCCESS) {
            
        }
    }
    size_t size = sizeof(hmd_ulock_wait_args);
    hmd_ulock_wait_args lock;
    if (hmd_async_read_memory(ptr, &lock, size) == HMD_ESUCCESS) {
        return lock.operation ^ ULL_WAITERS;
    }
    return 0;
}

thread_t fetch_gcd_lock(const hmd_machine_context* const context){
    uintptr_t ptr = hmdmc_register_value(context, 0);
    hmd_dispatch_queue_s queue = {0};
    if (hmd_async_read_memory(ptr, &queue, sizeof(hmd_dispatch_queue_s)) == HMD_ESUCCESS) {
        uint32_t dq_state = (uint32_t)queue.dq_state;
        if (dq_state & DLOCK_OWNER_MASK) {
            return (thread_t)(dq_state | DLOCK_WAITERS_BIT | DLOCK_FAILED_TRYLOCK_BIT);
        }
    }
    return 0;
}

uint64_t fetch_semaphore_lock(const hmd_machine_context* const context){
    uintptr_t ptr = hmdmc_register_value(context, 0);
    return (uint64_t)ptr;
}

uint64_t fetch_read_write_lock(const hmd_machine_context* const context){
    uintptr_t ptr = hmdmc_register_value(context, 0);
    if (__builtin_available(iOS 10.0, *)) {
        hmd_pthread_rwlock mtx;
        if (hmd_async_read_memory(ptr, &mtx, sizeof(hmd_pthread_rwlock)) == HMD_ESUCCESS) {
            uint64_t tid = (uint64_t)mtx.rw_tid[0];
            return tid;
        }
    }
    return 0;
}


int fetch_thread_lock_info(hmd_deadlocl_node *node){
    KSMC_NEW_CONTEXT(machine_context);
    hmdmc_get_state_with_thread(node->waiting_tid, machine_context, false);
    if (hmdthread_self() == node->waiting_tid){
        return -1;
    }
    uintptr_t pc = hmdmc_get_pc(machine_context);
    if (pc){
        int index = fetch_waiting_lock_index(pc);
        if (index < 0){
            return -1;
        }
        
        const char *str_lock_type;
        switch (waiting_lock_types[index]) {
            case HMDDeadlockTypeMutex:
                node->owner_system_tid = fetch_mutex_lock(machine_context);
                str_lock_type = "Mutex";
                break;
            case HMDDeadlockTypeUnfairLock:
                node->owner_tid = fetch_unfair_lock(machine_context);
                str_lock_type = "Unfair";
                break;
            case HMDDeadlockTypeGCD:
                node->owner_tid = fetch_gcd_lock(machine_context);
                str_lock_type = "GCD";
                break;
            case HMDDeadlockTypeSemaphore:
                node->semaphore_name = fetch_semaphore_lock(machine_context);
                str_lock_type = "Semaphore";
                break;
            case HMDDeadlockTypeReadWrite:
                node->owner_system_tid = fetch_read_write_lock(machine_context);
                str_lock_type = "ReadWrite";
                break;
            default:
                str_lock_type = "Unknow";
                break;
        }
        node->symbol_name = waiting_symbol_list[index];
        node->lock_type = str_lock_type;
        return 0;
    }
    return -1;
}

uint64_t fetch_system_thread64_id(thread_t thread) {
    integer_t info_data[THREAD_IDENTIFIER_INFO_COUNT] = {0};
    thread_info_t info = info_data;
    mach_msg_type_number_t in_out_size = THREAD_IDENTIFIER_INFO_COUNT;
    kern_return_t kr = 0;
    
    kr = thread_info((thread_t)thread, THREAD_IDENTIFIER_INFO, info, &in_out_size);
    if(kr != KERN_SUCCESS) {
        return 0;
    }
    
    thread_identifier_info_t data = (thread_identifier_info_t)info;
    if (!data) {
        return 0;
    }

    return data->thread_id;
}



