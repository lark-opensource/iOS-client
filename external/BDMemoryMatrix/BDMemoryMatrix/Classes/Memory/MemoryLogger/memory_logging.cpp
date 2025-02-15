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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <limits.h>
#include <unistd.h>
#include <fcntl.h>
#include <dlfcn.h>
#include <dirent.h>
#include <mach/mach.h>
#include <sys/sysctl.h>
#include <sys/stat.h>
#include <sys/mman.h>
#include <paths.h>
#include <errno.h>
#include <assert.h>
#include <pthread/pthread.h>
#include <execinfo.h>
#include <mach-o/dyld.h>

#include "logger_internal.h"
#include "memory_logging.h"
#include "object_event_handler.h"
#include "memory_logging_event_buffer.h"
#include "memory_logging_event_buffer_list.h"
#include "memory_logging_event_buffer_pool.h"
#include "allocation_event_db.h"
#include "dyld_image_info.h"
#include "stack_frames_db.h"
#include "memory_logging_event_config.h"
#include "main_thread_id_util.h"
#import <Heimdallr/HMDAsyncThreadRecordPool.h>
#import <Heimdallr/hmd_crash_async_stack_trace.h>
#import "logger_timer.h"
#import <atomic>
#import <mutex>

#pragma mark -
#pragma mark Constants/Globals

// single-thread access variables
static stack_frames_db *s_stack_frames_writer = NULL;
static allocation_event_db *s_allocation_event_writer = NULL;
static dyld_image_info_db *s_dyld_image_info_writer = NULL;
static object_type_db *s_object_type_writer = NULL;
static vc_name_db *s_vc_name_writer = NULL;
static memory_logging_event_buffer_list *s_buffer_list = NULL;
memory_logging_event_buffer_pool *s_buffer_pool = NULL;
static std::mutex custom_memory_mutex;

static Timer timer;
static std::atomic<uint32_t> current_timestamp;
static bool is_get_event_time;

// activation variables
bool s_logging_is_enable = false; // set this to zero to stop logging memory ativities
bool matrix_stop_logging = false;

int dump_call_stacks = 1; // 0 = not dump, 1 = dump all objects' call stacks, 2 = dump only objc objects'
bool memory_graph_dump = false;

long matrix_dump_time_cost = 0;

// We set malloc_logger to NULL to disable logging, if we encounter errors
// during file writing
typedef void(malloc_logger_t)(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result, uint32_t num_hot_frames_to_skip);

extern malloc_logger_t *malloc_logger;

#ifdef __cplusplus
extern "C" {
#endif
// custom matrix datagram timing of heimdallr
__attribute__ ((weak)) double getMatrixMinGenerateMinuteInterval(void) {return 0;}
__attribute__ ((weak)) int getMatrixMaxTimesPerDay(void) {return INT_MAX;}

#ifdef __cplusplus
} // extern "C"
#endif

#ifndef MEMORY_IGNORE_VMALLOCATE
static malloc_logger_t **syscall_logger; // use this to set up syscall logging (e.g., vm_allocate, vm_deallocate, mmap, munmap)
#endif

static pthread_t s_working_thread = 0;
static thread_id s_working_thread_id = 0;
thread_id s_main_thread_id = 0;

static pthread_key_t s_event_buffer_key = 0;

// Some callback in memory logging thread
static pthread_t s_dumping_thread = 0;
static std::shared_ptr<std::string> s_memory_dump_data = NULL;
static summary_report_param s_memory_dump_param;
static void (*s_memory_dump_callback)(const char *, size_t) = NULL;
static void (*s_memory_dump_time_callback)(long) = NULL;
// pre-declarations
void *__memory_event_writing_thread(void *param);
void *__memory_event_dumping_thread(void *param);

#pragma mark -
#pragma mark Memory Logging

bool __prepare_working_thread() {
    int ret;
    pthread_attr_t tattr;
    sched_param param;

    /* initialized with default attributes */
    ret = pthread_attr_init(&tattr);

    /* safe to get existing scheduling param */
    ret = pthread_attr_getschedparam(&tattr, &param);

    /* set the highest priority; others are unchanged */
    param.sched_priority = MAX(sched_get_priority_max(SCHED_RR), param.sched_priority);

    /* setting the new scheduling param */
    ret = pthread_attr_setschedparam(&tattr, &param);

    if (pthread_create(&s_working_thread, &tattr, __memory_event_writing_thread, NULL) == KERN_SUCCESS) {
        pthread_detach(s_working_thread);
        return true;
    } else {
        return false;
    }
}

bool __prepare_dumping_thread() {
    int ret;
    pthread_attr_t tattr;
    sched_param param;

    /* initialized with default attributes */
    ret = pthread_attr_init(&tattr);

    /* safe to get existing scheduling param */
    ret = pthread_attr_getschedparam(&tattr, &param);

    /* set the highest priority; others are unchanged */
    param.sched_priority = MAX(sched_get_priority_max(SCHED_RR), param.sched_priority);

    /* setting the new scheduling param */
    ret = pthread_attr_setschedparam(&tattr, &param);

    if (pthread_create(&s_dumping_thread, &tattr, __memory_event_dumping_thread, (void *)s_memory_dump_callback) == KERN_SUCCESS) {
        pthread_detach(s_dumping_thread);
        return true;
    } else {
        return false;
    }
}

#if __has_feature(ptrauth_calls)
#include <ptrauth.h>
#endif
//#include <pthread/stack_np.h> // iOS 12+ only

__attribute__((noinline, not_tail_called)) static unsigned __thread_stack_pcs(uintptr_t *buffer, unsigned max, int skip) {
    uintptr_t frame, next;
    pthread_t self = pthread_self();
    uintptr_t stacktop = (uintptr_t)pthread_get_stackaddr_np(self);
    uintptr_t stackbot = stacktop - pthread_get_stacksize_np(self);
    unsigned nb = 0;

    // Rely on the fact that our caller has an empty stackframe (no local vars)
    // to determine the minimum size of a stackframe (frame ptr & return addr)
    frame = (uintptr_t)__builtin_frame_address(1);

#define INSTACK(a) ((a) >= stackbot && (a) < stacktop)

#if defined(__x86_64__)
#define ISALIGNED(a) ((((uintptr_t)(a)) & 0xf) == 0)
#elif defined(__i386__)
#define ISALIGNED(a) ((((uintptr_t)(a)) & 0xf) == 8)
#elif defined(__arm__) || defined(__arm64__)
#define ISALIGNED(a) ((((uintptr_t)(a)) & 0x1) == 0)
#endif

    if (!INSTACK(frame) || !ISALIGNED(frame)) {
        return 0;
    }

    // skip itself and caller
    while (skip--) {
        next = *(uintptr_t *)frame;
        frame = next;
        if (!INSTACK(frame) /* || !ISALIGNED(frame)*/) {
            return 0;
        }
    }

    while (max--) {
        next = *(uintptr_t *)frame;
        uintptr_t retaddr = *((uintptr_t *)frame + 1);
        //uintptr_t retaddr2 = 0;
        //uintptr_t next2 = pthread_stack_frame_decode_np(frame, &retaddr2);
        if (retaddr == 0) {
            return nb;
        }
#if __has_feature(ptrauth_calls)
        //buffer[nb++] = (uintptr_t)ptrauth_strip((void *)retaddr, ptrauth_key_return_address); // PAC strip
        buffer[nb++] = (retaddr & 0x0fffffffff); // PAC strip
#elif defined(__arm__) || defined(__arm64__)
        buffer[nb++] = (retaddr & 0x0fffffffff); // PAC strip
#else
        buffer[nb++] = retaddr;
#endif

        if (!INSTACK(next) /* || !ISALIGNED(next) || next <= frame*/) {
//            return nb;
            break;
        }

        frame = next;
    }
    
    if (matrix_async_stack_enable) {
        hmd_async_stack_record_t *async_stack = hmd_async_stack_trace_mach_thread(mach_thread_self());
        
        int tmp = max;
        if (async_stack != NULL) {
            for (int i=async_stack->skip_length; i < async_stack->length && (tmp > 0); i++){
                tmp = tmp-1;
                uintptr_t retaddr = (uintptr_t)(async_stack->backtrace[i]);
#if __has_feature(ptrauth_calls)
                //buffer[nb++] = (uintptr_t)ptrauth_strip((void *)retaddr, ptrauth_key_return_address); // PAC strip
                buffer[nb++] = (retaddr & 0x0fffffffff); // PAC strip
#elif defined(__arm__) || defined(__arm64__)
                buffer[nb++] = (retaddr & 0x0fffffffff); // PAC strip
#else
                buffer[nb++] = retaddr;
#endif
            }
        }
    }
    

#undef INSTACK
#undef ISALIGNED

    return nb;
}

memory_logging_event_buffer *__new_event_buffer_and_lock(thread_id t_id) {
    memory_logging_event_buffer *event_buffer = memory_logging_event_buffer_pool_new_buffer(s_buffer_pool, t_id);
    if (event_buffer == NULL) {
        matrix_stop_logging = true;
        s_logging_is_enable = false;
        return NULL;
    }
    memory_logging_event_buffer_lock(event_buffer);
    memory_logging_event_buffer_list_push_back(s_buffer_list, event_buffer);
    pthread_setspecific(s_event_buffer_key, event_buffer);
    return event_buffer;
}

void __memory_event_callback(
uint32_t type_flags, uintptr_t zone_ptr, uintptr_t arg2, uintptr_t arg3, uintptr_t return_val, uint32_t num_hot_to_skip) {
    uintptr_t size = 0;
    uintptr_t ptr_arg = 0;
    bool is_alloc = false;
    
    if (matrix_stop_logging) {
        return;
    }

    uint32_t alias = 0;
    VM_GET_FLAGS_ALIAS(type_flags, alias);
    // skip all VM allocation events from malloc_zone
    if (alias >= VM_MEMORY_MALLOC && alias <= VM_MEMORY_MALLOC_NANO) {
        return;
    }
    
    if (alias == VM_MEMORY_STACK) {
        return;
    }
    // skip allocation events from mapped_file
//    if (type_flags & memory_logging_type_mapped_file_or_shared_mem) {
//        return;
//    }

    thread_info_for_logging_t thread_info;
    thread_info.value = current_thread_info_for_logging();

    if (thread_info.detail.is_ignore) {
        // Prevent a thread from deadlocking against itself if vm_allocate() or malloc()
        // is called below here, from woking thread or dumping thread
        return;
    }

    // check incoming data
    if ((type_flags & memory_logging_type_alloc) && (type_flags & memory_logging_type_dealloc)) {
        size = arg3;
        ptr_arg = arg2; // the original pointer
        if (ptr_arg == return_val) {
            return; // realloc had no effect, skipping
        }
        if (ptr_arg == 0) { // realloc(NULL, size) same as malloc(size)
            type_flags ^= memory_logging_type_dealloc;
        } else {
            // realloc(arg1, arg2) -> result is same as free(arg1); malloc(arg2) -> result
            __memory_event_callback(memory_logging_type_dealloc, zone_ptr, ptr_arg, (uintptr_t)0, (uintptr_t)0, num_hot_to_skip + 1);
            __memory_event_callback(memory_logging_type_alloc, zone_ptr, size, (uintptr_t)0, return_val, num_hot_to_skip + 1);
            return;
        }
    }
    if ((type_flags & memory_logging_type_dealloc) || (type_flags & memory_logging_type_vm_deallocate)) {
        size = arg3;
        ptr_arg = arg2;
        if (ptr_arg == 0) {
            return; // free(nil)
        }
    }
    if ((type_flags & memory_logging_type_alloc) || (type_flags & memory_logging_type_vm_allocate)) {
        if (return_val == 0 || return_val == (uintptr_t)MAP_FAILED) {
            return;
        }
        size = arg2;
        is_alloc = true;
    }

    //type_flags &= memory_logging_valid_type_flags;
    
    //record vc index for every alloc/vm_allocate memory
    uint8_t vc_name_index = get_current_vc_name_index();
    if (vc_name_index > 0) {
        type_flags &= alloca_type_mask;
        type_flags |= (vc_name_index << 16);
    }
    
    thread_id t_id = thread_info.detail.t_id;
    memory_logging_event_buffer *event_buffer = (memory_logging_event_buffer *)pthread_getspecific(s_event_buffer_key);
    if (event_buffer == NULL || event_buffer->t_id != t_id) {
        event_buffer = __new_event_buffer_and_lock(t_id);
    } else {
        memory_logging_event_buffer_lock(event_buffer);

        // check t_id again
        if (event_buffer->t_id != t_id) {
            memory_logging_event_buffer_unlock(event_buffer);

            event_buffer = __new_event_buffer_and_lock(t_id);
        }
    }
    if (event_buffer == NULL) {
        return;
    }
    // gather stack, only alloc type
    if (is_alloc) {
        if (memory_logging_event_buffer_is_full(event_buffer, dump_call_stacks == 1)) {
            memory_logging_event_buffer_unlock(event_buffer);

            event_buffer = __new_event_buffer_and_lock(t_id);
        }
        
        if (event_buffer == NULL) {
            return;
        }

        memory_logging_event *new_event = memory_logging_event_buffer_new_event(event_buffer);
        new_event->address = return_val;
        new_event->size = (uint32_t)size;
        new_event->object_type = 0;
        new_event->type_flags = type_flags;
        new_event->event_type = EventType_Alloc;
        new_event->time_stamp = current_timestamp;
        if (dump_call_stacks == 1) {
            new_event->stack_size = __thread_stack_pcs(new_event->stacks, STACK_LOGGING_MAX_STACK_SIZE, num_hot_to_skip);
            new_event->event_size = (uint16_t)write_size_by_event(new_event);
            memory_logging_event_buffer_update_write_index_with_size(event_buffer, new_event->event_size);
        } else {
            new_event->stack_size = 0;
            new_event->event_size = MEMORY_LOGGING_EVENT_SIMPLE_SIZE;
            memory_logging_event_buffer_update_write_index_with_size(event_buffer, MEMORY_LOGGING_EVENT_SIMPLE_SIZE);
        }
    } else {
        // compaction
        memory_logging_event *last_event = memory_logging_event_buffer_last_event(event_buffer);
        if (last_event != NULL && last_event->address == ptr_arg) {
            if ((last_event->type_flags & memory_logging_type_alloc) && (type_flags & memory_logging_type_dealloc)) {
                // skip events
                memory_logging_event_buffer_update_to_last_write_index(event_buffer);
                memory_logging_event_buffer_unlock(event_buffer);
                return;
            } else if ((last_event->type_flags & memory_logging_type_vm_allocate) && (type_flags & memory_logging_type_vm_deallocate)) {
                // skip events
                memory_logging_event_buffer_update_to_last_write_index(event_buffer);
                memory_logging_event_buffer_unlock(event_buffer);
                return;
            }
        }

        if (memory_logging_event_buffer_is_full(event_buffer)) {
            memory_logging_event_buffer_unlock(event_buffer);

            event_buffer = __new_event_buffer_and_lock(t_id);
        }
        
        if (event_buffer == NULL) {
            return;
        }

        memory_logging_event *new_event = memory_logging_event_buffer_new_event(event_buffer);
        new_event->address = ptr_arg;
        new_event->type_flags = type_flags;
        new_event->event_size = MEMORY_LOGGING_EVENT_SIMPLE_SIZE;
        new_event->event_type = EventType_Free;

        memory_logging_event_buffer_update_write_index_with_size(event_buffer, MEMORY_LOGGING_EVENT_SIMPLE_SIZE);
    }

    memory_logging_event_buffer_unlock(event_buffer);
}

void __memory_event_update_object(uint64_t address, uint32_t new_type) {
    if (!s_logging_is_enable) {
        return;
    }

    thread_info_for_logging_t thread_info;
    thread_info.value = current_thread_info_for_logging();

    if (thread_info.detail.is_ignore) {
        return;
    }

    thread_id t_id = thread_info.detail.t_id;
    memory_logging_event_buffer *event_buffer = (memory_logging_event_buffer *)pthread_getspecific(s_event_buffer_key);
    if (event_buffer == NULL || event_buffer->t_id != t_id) {
        event_buffer = __new_event_buffer_and_lock(t_id);
    } else {
        memory_logging_event_buffer_lock(event_buffer);

        // check t_id again
        if (event_buffer->t_id != t_id) {
            memory_logging_event_buffer_unlock(event_buffer);

            event_buffer = __new_event_buffer_and_lock(t_id);
        }
    }
    
    if (event_buffer == NULL) {
        return;
    }
    
    if (dump_call_stacks == 2) {
        // compaction
        memory_logging_event *last_event = memory_logging_event_buffer_last_event(event_buffer);
        if (last_event != NULL && last_event->address == address) {
            if (last_event->type_flags & memory_logging_type_alloc) {
                // skip events
                uint32_t size = last_event->size;
                uint32_t type_flags = last_event->type_flags;
                memory_logging_event_buffer_update_to_last_write_index(event_buffer);

                if (memory_logging_event_buffer_is_full(event_buffer, true)) {
                    memory_logging_event_buffer_unlock(event_buffer);

                    event_buffer = __new_event_buffer_and_lock(t_id);
                }
                
                if (event_buffer == NULL) {
                    return;
                }
                memory_logging_event *new_event = memory_logging_event_buffer_new_event(event_buffer);
                new_event->address = address;
                new_event->size = size;
                new_event->object_type = new_type;
                new_event->type_flags = type_flags;
                new_event->stack_size = __thread_stack_pcs(new_event->stacks, STACK_LOGGING_MAX_STACK_SIZE, 1);
                new_event->event_size = (uint16_t)write_size_by_event(new_event);
                new_event->event_type = EventType_Alloc;
                memory_logging_event_buffer_update_write_index_with_size(event_buffer, new_event->event_size);

                memory_logging_event_buffer_unlock(event_buffer);
                return;
            }
        }

        if (memory_logging_event_buffer_is_full(event_buffer, true)) {
            memory_logging_event_buffer_unlock(event_buffer);

            event_buffer = __new_event_buffer_and_lock(t_id);
        }
        
        if (event_buffer == NULL) {
            return;
        }
        memory_logging_event *new_event = memory_logging_event_buffer_new_event(event_buffer);
        new_event->address = address;
        new_event->object_type = new_type;
        uint8_t vc_name_index = get_current_vc_name_index();
        new_event->type_flags = (vc_name_index << 16);
        new_event->stack_size = __thread_stack_pcs(new_event->stacks, STACK_LOGGING_MAX_STACK_SIZE, 1);
        new_event->event_size = (uint16_t)write_size_by_event(new_event);
        new_event->event_type = EventType_Update;
        memory_logging_event_buffer_update_write_index_with_size(event_buffer, new_event->event_size);

        memory_logging_event_buffer_unlock(event_buffer);
    } else {
        // compaction
        memory_logging_event *last_event = memory_logging_event_buffer_last_event(event_buffer);
        if (last_event != NULL && last_event->address == address) {
            if (last_event->type_flags & memory_logging_type_alloc) {
                // skip events
                last_event->object_type = new_type;
                memory_logging_event_buffer_unlock(event_buffer);
                return;
            }
        }

        if (memory_logging_event_buffer_is_full(event_buffer)) {
            memory_logging_event_buffer_unlock(event_buffer);

            event_buffer = __new_event_buffer_and_lock(t_id);
        }

        if (event_buffer == NULL) {
            return;
        }
        memory_logging_event *new_event = memory_logging_event_buffer_new_event(event_buffer);
        new_event->address = address;
        new_event->object_type = new_type;
        uint8_t vc_name_index = get_current_vc_name_index();
        new_event->type_flags = (vc_name_index << 16);
        new_event->stack_size = 0;
        new_event->event_size = MEMORY_LOGGING_EVENT_SIMPLE_SIZE;
        new_event->event_type = EventType_Update;
        memory_logging_event_buffer_update_write_index_with_size(event_buffer, MEMORY_LOGGING_EVENT_SIMPLE_SIZE);

        memory_logging_event_buffer_unlock(event_buffer);
    }
}

#pragma mark - Writing Process
namespace {
    long getCurrentTime()
    {
        struct timeval tv;
        gettimeofday(&tv,NULL);
        return tv.tv_sec * 1000 + tv.tv_usec / 1000;
    }
}

void *__memory_event_writing_thread(void *param) {
    pthread_setname_np("Memory Logging");
    
    double customDumpMinInterval = getMatrixMinGenerateMinuteInterval();
    int customDumpMaxTimes = getMatrixMaxTimesPerDay();
    double customDumpTimeStamp = 0;
    int customDumpCount = 0;

    set_curr_thread_ignore_logging(true); // for preventing deadlock'ing on memory logging on a single thread

    s_working_thread_id = current_thread_id();
    log_internal_without_this_thread(s_working_thread_id);

    int usleep_time = 0;

    // Wait for enable_memory_logging finished
    while (s_logging_is_enable == false) {
        usleep(10000);
    }

    while (s_logging_is_enable) {
        bool thread_is_woken = false;
        
        long start_time = getCurrentTime();
        
        memory_logging_event_buffer *event_buffer = memory_logging_event_buffer_list_pop_all(s_buffer_list);
        while (event_buffer != NULL) {
            memory_logging_event_buffer_lock(event_buffer);
            event_buffer->t_id = 0;
            memory_logging_event_buffer_unlock(event_buffer);

            memory_logging_event_buffer_compress(event_buffer);
            memory_logging_event *curr_event = (memory_logging_event *)memory_logging_event_buffer_begin(event_buffer);

            while (curr_event != NULL) {
                if (curr_event->event_type == EventType_Alloc) {
                    if (curr_event->stack_size > 0) {
                        if (is_stack_frames_should_skip(curr_event->stacks, curr_event->stack_size, curr_event->size) == false) {
                            // unique stack in memory
                            uint32_t stack_identifier = add_stack_frames_in_table(s_stack_frames_writer, curr_event->stacks, curr_event->stack_size);

                            // Try to get vm memory type from type_flags
                            uint32_t object_type = curr_event->object_type;
                            if (object_type == 0) {
                                VM_GET_FLAGS_ALIAS(curr_event->type_flags, object_type);
                            }
                            if (is_get_event_time) {
                                allocation_event_db_add_with_timestamp(s_allocation_event_writer,
                                                        curr_event->address,
                                                        curr_event->type_flags,
                                                        object_type,
                                                        curr_event->size,
                                                        stack_identifier,
                                                        curr_event->time_stamp);
                            } else {
                                allocation_event_db_add(s_allocation_event_writer,
                                                        curr_event->address,
                                                        curr_event->type_flags,
                                                        object_type,
                                                        curr_event->size,
                                                        stack_identifier);
                            }
                        }
                    } else {
                        // Try to get vm memory type from type_flags
                        uint32_t object_type = curr_event->object_type;
                        if (object_type == 0) {
                            VM_GET_FLAGS_ALIAS(curr_event->type_flags, object_type);
                        }
                        if (is_get_event_time) {
                            allocation_event_db_add_with_timestamp(s_allocation_event_writer,
                                                                   curr_event->address,
                                                                   curr_event->type_flags,
                                                                   object_type,
                                                                   curr_event->size,
                                                                   0,
                                                                   curr_event->time_stamp);
                        } else {
                            allocation_event_db_add(s_allocation_event_writer,
                                                    curr_event->address,
                                                    curr_event->type_flags,
                                                    object_type,
                                                    curr_event->size,
                                                    0);
                        }
                    }
                } else if (curr_event->event_type == EventType_Free) {
                    allocation_event_db_del(s_allocation_event_writer, curr_event->address, curr_event->type_flags);
                } else if (curr_event->event_type == EventType_Update) {
                    if (curr_event->stack_size > 0) {
                        if (is_stack_frames_should_skip(curr_event->stacks, curr_event->stack_size, curr_event->size) == false) {
                            // unique stack in memory
                            uint32_t stack_identifier = add_stack_frames_in_table(s_stack_frames_writer, curr_event->stacks, curr_event->stack_size);

                            allocation_event_db_update_object_type_and_stack_identifier(s_allocation_event_writer,
                                                                                        curr_event->address,
                                                                                        curr_event->object_type,
                                                                                        stack_identifier);
                        } else {
                            allocation_event_db_update_object_type(s_allocation_event_writer, curr_event->address, curr_event->object_type);
                        }
                    } else {
                        allocation_event_db_update_object_type(s_allocation_event_writer, curr_event->address, curr_event->object_type);
                    }
                } else if (curr_event->event_type != EventType_Invalid) {
                    heimdallr_disable_memory_logging("Matrix event type invalid");
                    report_error(MS_ERRC_DATA_CORRUPTED);
                    __malloc_printf("Data corrupted?!");

                    break;
                    // Restore abort()?
                }

                if (s_logging_is_enable == false) {
                    break;
                }

                curr_event = memory_logging_event_buffer_next(event_buffer, curr_event);
            }

            if (s_logging_is_enable == false) {
                break;
            }

            memory_logging_event_buffer *next_event_buffer = event_buffer->next_event_buffer;
            if (memory_logging_event_buffer_pool_free_buffer(s_buffer_pool, event_buffer)) {
                thread_is_woken = true;
            }
            event_buffer = next_event_buffer;
        }

        if (s_logging_is_enable == false) {
            break;
        }

        if (s_memory_dump_callback && s_memory_dump_data == NULL) {
            if (memory_graph_dump == true) {
                s_memory_dump_data = generate_memory_graph_report_i(s_allocation_event_writer,
                                                               s_stack_frames_writer,
                                                               s_dyld_image_info_writer,
                                                               s_object_type_writer,
                                                               s_vc_name_writer,
                                                               s_memory_dump_param);
                memory_graph_dump = false;
                matrix_dump_time_cost = getCurrentTime() - start_time;
                __prepare_dumping_thread();
            } else {
                if (is_get_event_time && time(0) > (customDumpTimeStamp+customDumpMinInterval) && customDumpCount < customDumpMaxTimes) {
                    s_memory_dump_data = generate_summary_report_i(s_allocation_event_writer,
                                                                   s_stack_frames_writer,
                                                                   s_dyld_image_info_writer,
                                                                   s_object_type_writer,
                                                                   s_vc_name_writer,
                                                                   s_memory_dump_param);
                    customDumpTimeStamp = time(0);
                    customDumpCount += 1;
                    matrix_dump_time_cost = getCurrentTime() - start_time;
                    __prepare_dumping_thread();
                } else {
                    s_memory_dump_callback = NULL;
                    s_memory_dump_data = NULL;
                }
            }
        }

        if (thread_is_woken == false) {
            if (usleep_time < 15000) {
                usleep_time += 5000;
            }
            usleep(usleep_time);
        } else {
            usleep_time = 0;
        }
    }

    log_internal_without_this_thread(0);

    usleep(10000000);

    stack_frames_db_close(s_stack_frames_writer);
    s_stack_frames_writer = NULL;

    allocation_event_db_close(s_allocation_event_writer);
    s_allocation_event_writer = NULL;

    dyld_image_info_db_close(s_dyld_image_info_writer);
    s_dyld_image_info_writer = NULL;

    object_type_db_close(s_object_type_writer);
    s_object_type_writer = NULL;
    
    vc_name_db_close(s_vc_name_writer);
    s_vc_name_writer = NULL;
    
    memory_logging_event_buffer_pool_free(s_buffer_pool);
//    s_buffer_pool = NULL;

    memory_logging_event_buffer_list_free(s_buffer_list);
    s_buffer_list = NULL;

    __malloc_printf("memory logging cleanup finished\n");
    delete_current_record();

    return NULL;
}

void *__memory_event_dumping_thread(void *param) {
    pthread_setname_np("Memory Dumping");

    set_curr_thread_ignore_logging(true); // for preventing deadlock'ing on memory logging on a single thread

    void (*memory_dump_callback)(const char *, size_t) = (void (*)(const char *, size_t))param;
    memory_dump_callback(s_memory_dump_data->c_str(), s_memory_dump_data->size());
    
    if (s_memory_dump_time_callback && matrix_dump_time_cost != 0) {
        s_memory_dump_time_callback(matrix_dump_time_cost);
        matrix_dump_time_cost = 0;
    }
    
    s_memory_dump_callback = NULL;
    s_memory_dump_data = NULL;

    return NULL;
}

#pragma mark - Memory Stat Logging Thread

/*!
 @brief This function uses sysctl to check for attached debuggers.
 @link https://developer.apple.com/library/mac/qa/qa1361/_index.html
 @link http://www.coredump.gr/articles/ios-anti-debugging-protections-part-2/
 */
bool is_analysis_tool_running(void) {
    void *flagMallocStackLogging = getenv("MallocStackLogging");
    void *flagMallocStackLoggingNoCompact = getenv("MallocStackLoggingNoCompact");
    //flagMallocScribble = getenv("MallocScribble");
    //flagMallocGuardEdges = getenv("MallocGuardEdges");
    void *flagMallocLogFile = getenv("MallocLogFile");
    //flagMallocErrorAbort = getenv("MallocErrorAbort");
    //flagMallocCorruptionAbort = getenv("MallocCorruptionAbort");
    //flagMallocCheckHeapStart = getenv("MallocCheckHeapStart");
    //flagMallocHelp = getenv("MallocHelp");
    // Compatible with Instruments' Leak
    void *flagOAAllocationStatisticsOutputMask = getenv("OAAllocationStatisticsOutputMask");

    if (flagMallocStackLogging) {
        return true;
    }

    if (flagMallocStackLoggingNoCompact) {
        return true;
    }

    if (flagMallocLogFile) {
        return true;
    }

    if (flagOAAllocationStatisticsOutputMask) {
        return true;
    }

    return false;
}

#pragma mark -
#pragma mark Public Interface

void setTimeStamp() {
    current_timestamp = (uint32_t)time(NULL);
}

int enable_memory_logging(const char *log_dir) {
    err_code = MS_ERRC_SUCCESS;
    setTimeStamp();
    timer.start(1, std::bind(setTimeStamp));
    if (logger_internal_init() == false) {
        return MS_ERRC_WORKING_THREAD_CREATE_FAIL;
    }

    // Check whether there's any analysis tool process logging memory.
    if (is_analysis_tool_running()) {
        return MS_ERRC_ANALYSIS_TOOL_RUNNING;
    }

    s_allocation_event_writer = allocation_event_db_open_or_create(log_dir);
    if (s_allocation_event_writer == NULL) {
        return err_code;
    }

    if (dump_call_stacks != 0) {
        s_stack_frames_writer = stack_frames_db_open_or_create(log_dir);
        if (s_stack_frames_writer == NULL) {
            return err_code;
        }
    }

    s_dyld_image_info_writer = prepare_dyld_image_logger(log_dir);
    if (s_dyld_image_info_writer == NULL) {
        return err_code;
    }
    
    s_buffer_pool = memory_logging_event_buffer_pool_create();
    if (s_buffer_pool == NULL) {
        return err_code;
    }

    s_buffer_list = memory_logging_event_buffer_list_create();
    if (s_buffer_list == NULL) {
        return err_code;
    }
    
    s_object_type_writer = prepare_object_event_logger(log_dir);
    if (s_object_type_writer == NULL) {
        return err_code;
    }

    s_vc_name_writer = prepare_vc_name_logger(log_dir);
    if (s_vc_name_writer == NULL) {
        return err_code;
    }
    
    if (pthread_key_create(&s_event_buffer_key, NULL) != 0) {
        __malloc_printf("pthread_key_create fail");
        return MS_ERRC_WORKING_THREAD_CREATE_FAIL;
    }
    
    s_main_thread_id = mm_main_thread_id_sync();

    if (__prepare_working_thread() == false) {
        __malloc_printf("create writing thread fail");
        return MS_ERRC_WORKING_THREAD_CREATE_FAIL;
    }

    malloc_logger = __memory_event_callback;

#ifndef MEMORY_IGNORE_VMALLOCATE
    if (memory_event_is_enable_vmalloc()) {
        // __syscall_logger
        std::string name;
        memory_event_get_name_one(name);
        syscall_logger = (malloc_logger_t **)dlsym(RTLD_DEFAULT, name.c_str());
        if (syscall_logger != NULL) {
            *syscall_logger = __memory_event_callback;
        }
    }
#endif

    s_logging_is_enable = true;

    return MS_ERRC_SUCCESS;
}

/*
 * Since there a many errors that could cause memory logging to get disabled, this is a convenience method
 * for disabling any future logging in this process and for informing the user.
 */
void disable_memory_logging(void) {
    matrix_stop_logging = true;
    if (!s_logging_is_enable) {
        return;
    }
    
    disable_object_event_logger();
    malloc_logger = NULL;
#ifndef MEMORY_IGNORE_VMALLOCATE
    if (syscall_logger != NULL) {
        *syscall_logger = NULL;
    }
#endif

    // make current logging invalid
    //set_memory_logging_invalid();
    s_logging_is_enable = false;
    log_internal_without_this_thread(0);
    __malloc_printf("memory logging disabled due to previous errors\n");
}

void heimdallr_disable_memory_logging(const char *reason) {
    matrix_stop_logging = true;
    if (!s_logging_is_enable) {
        return;
    }
    malloc_logger = NULL;
    disable_object_event_logger();
    
#ifndef MEMORY_IGNORE_VMALLOCATE
    if (syscall_logger != NULL) {
        *syscall_logger = NULL;
    }
#endif
    report_reason(reason);
    s_logging_is_enable = false;
    
    // make current logging invalid
    //set_memory_logging_invalid();
    log_internal_without_this_thread(0);
    __malloc_printf("memory logging disabled due to previous errors\n");
}

bool memory_dump(void (*callback)(const char *, size_t), summary_report_param param) {
    std::lock_guard<std::mutex> lck(custom_memory_mutex);
    if (!s_logging_is_enable) {
        __malloc_printf("memory logging is disabled\n");
        return false;
    }

    if (s_memory_dump_callback) {
        __malloc_printf("memory_dump_callback is not NULL\n");
        return false;
    }

    s_memory_dump_param = param;
    s_memory_dump_callback = callback;

    return true;
}

void set_memory_dump_time_cost_callback(void (*callback)(long)) {
    s_memory_dump_time_callback = callback;
}

void suspend_memory_logging() {
    matrix_stop_logging = true;
}
void resume_memory_logging() {
    matrix_stop_logging = false;
}

void get_event_time_stamp(bool event_time) {
    is_get_event_time = event_time;
}
