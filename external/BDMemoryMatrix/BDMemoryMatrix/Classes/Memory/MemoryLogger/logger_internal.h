/*
 * Tencent is pleased to support the open source community by making wechat-matrix available.
 * Copyright (C) 2019 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the BSD 3-Clause License (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://opensource.org/licenses/BSD-3-Clause
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef logger_internal_h
#define logger_internal_h

#include <mach/vm_statistics.h>
#include <mach/mach.h>
#include <errno.h>
#include <sys/_types/_off_t.h>
#include <stdio.h>
#include "memory_stat_err_code.h"
#include "memory_debug.h"

#define memory_logging_type_free 0
#define memory_logging_type_generic 1 /* anything that is not allocation/deallocation */
#define memory_logging_type_alloc 2 /* malloc, realloc, etc... */
#define memory_logging_type_dealloc 4 /* free, realloc, etc... */
#define memory_logging_type_vm_allocate 16 /* vm_allocate or mmap */
#define memory_logging_type_vm_deallocate 32 /* vm_deallocate or munmap */
#define memory_logging_type_mapped_file_or_shared_mem 128

// The valid flags include those from VM_FLAGS_ALIAS_MASK, which give the user_tag of allocated VM regions.
#define memory_logging_valid_type_flags                                                                                      \
    (memory_logging_type_generic | memory_logging_type_alloc | memory_logging_type_dealloc | memory_logging_type_vm_allocate \
     | memory_logging_type_vm_deallocate | memory_logging_type_mapped_file_or_shared_mem | VM_FLAGS_ALIAS_MASK)

#define STACK_LOGGING_MAX_STACK_SIZE 48

#ifndef __FILE_NAME__
#define __FILE_NAME__ (strrchr(__FILE__, '/') + 1)
#endif

//#define __malloc_printf(FORMAT, ...)                              \
//    do {                                                          \
//        char msg[256] = { 0 };                                    \
//        sprintf(msg, FORMAT, ##__VA_ARGS__);                      \
//        log_internal(__FILE_NAME__, __LINE__, __FUNCTION__, msg); \
//    } while (0)

#define __malloc_printf(FORMAT, ...) // empty


extern int err_code;

// Lock Function
//#define USE_SPIN_LOCK

#ifdef USE_SPIN_LOCK

#include <libkern/OSAtomic.h>

typedef OSSpinLock malloc_lock_s;

__attribute__((always_inline)) inline malloc_lock_s __malloc_lock_init() {
    return OS_SPINLOCK_INIT;
}

__attribute__((always_inline)) inline void __malloc_lock_lock(malloc_lock_s *lock) {
    OSSpinLockLock(lock);
}

__attribute__((always_inline)) inline bool __malloc_lock_trylock(malloc_lock_s *lock) {
    return OSSpinLockTry(lock);
}

__attribute__((always_inline)) inline void __malloc_lock_unlock(malloc_lock_s *lock) {
    OSSpinLockUnlock(lock);
}

#else

#include <os/lock.h>

typedef os_unfair_lock malloc_lock_s;

__attribute__((always_inline)) inline malloc_lock_s __malloc_lock_init() {
    return OS_UNFAIR_LOCK_INIT;
}

__attribute__((always_inline)) inline void __malloc_lock_lock(malloc_lock_s *lock) {
    os_unfair_lock_lock(lock);
}

__attribute__((always_inline)) inline bool __malloc_lock_trylock(malloc_lock_s *lock) {
    return os_unfair_lock_trylock(lock);
}

__attribute__((always_inline)) inline void __malloc_lock_unlock(malloc_lock_s *lock) {
    os_unfair_lock_unlock(lock);
}

#endif

// Thread Info for Logging
typedef mach_port_t thread_id;

typedef union {
    uint64_t value;

    struct {
        uint32_t t_id;
        bool is_ignore;
    } detail;
} thread_info_for_logging_t;

bool logger_internal_init(void);

uint64_t current_thread_info_for_logging();

#ifdef __cplusplus
extern "C" {
#endif
thread_id current_thread_id();
void set_curr_thread_ignore_logging(bool ignore);
bool is_thread_ignoring_logging();
#ifdef __cplusplus
}
#endif


// Allocation/Deallocation Function without Logging
void *inter_malloc(size_t size);
void *inter_calloc(size_t num_items, size_t size);
void *inter_realloc(void *oldMem, size_t newSize);
void inter_free(void *ptr);

void *inter_mmap(void *start, size_t length, int prot, int flags, int fd, off_t offset);
int inter_munmap(void *start, size_t length);

// File Functions
int open_file(const char *dir_name, const char *file_name);
void remove_file(const char *dir_name, const char *file_name);
void remove_folder(const char *dir_name);

extern void disable_memory_logging(void);
extern void heimdallr_disable_memory_logging(const char *);
extern void set_memory_logging_invalid(void);
extern void log_internal(const char *file, int line, const char *funcname, char *msg);
extern void log_internal_without_this_thread(thread_id t_id);
extern void report_error(int error);
extern void report_reason(const char *reason);
extern void delete_current_record(void);

#endif /* logger_internal_h */
