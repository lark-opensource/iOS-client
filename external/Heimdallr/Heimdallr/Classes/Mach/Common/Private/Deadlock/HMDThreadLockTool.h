//
//  HMDThreadLockTool.h
//  Pods
//
//  Created by wangyinhui on 2021/8/6.
//

#ifndef HMDThreadLockTool_h
#define HMDThreadLockTool_h
#include <stdio.h>
#include <mach/mach_types.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef enum : int {
    HMDDeadlockTypeUnKnow = 0,  // 其他类型
    HMDDeadlockTypeSemaphore,   // 信号量
    HMDDeadlockTypeGCD,         // GCD同步导致的锁
    HMDDeadlockTypeMutex,       // Mutex锁  -  普通锁，递归锁，条件锁
    HMDDeadlockTypeReadWrite,   // 读写锁
    HMDDeadlockTypeUnfairLock   // 不公平锁 os_unfair_lock, @synchronized
} HMDDeadlockType;

typedef struct {
    size_t waiting_thread_idx;
    thread_t waiting_tid;
    char waiting_thread_name[256];
    size_t owner_thread_idx;
    thread_t owner_tid; //mach thread id
    char owner_thread_name[256];
    uint64_t owner_system_tid; //system thread id
    uint64_t semaphore_name; //port name
    const char * symbol_name;
    const char * lock_type;
} hmd_deadlocl_node;


int is_thread_waiting(thread_t thread_id);
int is_deadlock_symbol(const char *name);
const char *fetch_symbol_name(uintptr_t ptr);
int fetch_thread_lock_info(hmd_deadlocl_node *node);
uint64_t fetch_system_thread64_id(thread_t thread);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDThreadLockTool_h */
