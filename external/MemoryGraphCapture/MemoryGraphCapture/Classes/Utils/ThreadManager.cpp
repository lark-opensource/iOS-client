//
//  ThreadManager.cpp
//  Hello
//
//  Created by brent.shu on 2019/10/22.
//  Copyright © 2019 brent.shu. All rights reserved.
//

#include "ThreadManager.hpp"

#include <pthread.h>
#include <mach/mach.h>
#include <malloc/malloc.h>
#include <thread>
#include <objc/runtime.h>

#ifdef __cplusplus
extern "C" {
#endif
// matrix
__attribute__ ((weak)) void mg_suspend_memory_logging_and_dump_memory(const char *file_uuid) {}
__attribute__ ((weak)) void mg_resume_memory_logging() {}

#ifdef __cplusplus
} // extern "C"
#endif

namespace MemoryGraph {

static thread_t thread_self() {
    thread_t thread_self = mach_thread_self();
    mach_port_deallocate(mach_task_self(), thread_self);
    return thread_self;
}

static bool suspend_other_threads() {
    kern_return_t kr;
    const task_t thisTask = mach_task_self();
    const thread_t thisThread = (thread_t)thread_self();
    thread_act_array_t threads;
    mach_msg_type_number_t numThreads;
    
    if((kr = task_threads(thisTask, &threads, &numThreads)) != KERN_SUCCESS)
    {
        return false;
    }
    
    for(mach_msg_type_number_t i = 0; i < numThreads; i++)
    {
        thread_t thread = threads[i];
        if(thread != thisThread)
        {
            if((kr = thread_suspend(thread)) != KERN_SUCCESS)
            {
                if (i > 0) {
                    for (int j = 0; j < i; ++j) {
                        thread_t thread_need_resume = threads[j];
                        thread_resume(thread_need_resume);
                    }
                }
                return false;
            }
        }
    }
    
    for(mach_msg_type_number_t i = 0; i < numThreads; i++)
    {
        mach_port_deallocate(thisTask, threads[i]);
    }
    vm_deallocate(thisTask, (vm_address_t)threads, sizeof(thread_t) * numThreads);
    return true;
}

static void resume_other_threads() {
    kern_return_t kr;
    const task_t thisTask = mach_task_self();
    const thread_t thisThread = (thread_t)thread_self();
    thread_act_array_t threads;
    mach_msg_type_number_t numThreads;
    
    if((kr = task_threads(thisTask, &threads, &numThreads)) != KERN_SUCCESS)
    {
        return;
    }
    
    mg_resume_memory_logging();
    
    for(mach_msg_type_number_t i = 0; i < numThreads; i++)
    {
        thread_t thread = threads[i];
        if(thread != thisThread)
        {
            if((kr = thread_resume(thread)) != KERN_SUCCESS)
            {
            }
        }
    }
    
    for(mach_msg_type_number_t i = 0; i < numThreads; i++)
    {
        mach_port_deallocate(thisTask, threads[i]);
    }
    vm_deallocate(thisTask, (vm_address_t)threads, sizeof(thread_t) * numThreads);
}

static bool is_lock_safe() {
    // is malloc safe
    auto mem_reader = [](task_t task, vm_address_t remote_address, vm_size_t size, void **local_memory) -> kern_return_t {
        *local_memory = (void*)remote_address;
        return KERN_SUCCESS;
    };
    
    vm_address_t *zones = NULL;
    unsigned int zone_num;
    kern_return_t err = malloc_get_all_zones(mach_task_self(), mem_reader, &zones, &zone_num);
    if (KERN_SUCCESS == err)
    {
        for (int i = 0; i < zone_num; ++i)
        {
            auto zone = (malloc_zone_t *)zones[i];
            if (zone->introspect && zone->introspect->zone_locked && zone->introspect->zone_locked(zone)) {
                return false;
            }
        }
        return true;
    } else {
        return false;
    }
}


ThreadSuspender::ThreadSuspender(const char* file_identify, std::function<bool ()> lockChecker): is_suspended(false) {
    int tryCount = 0;
    // make sure suspend succeed & locks is safe
    while (tryCount < 48) {
        if (suspend_other_threads()) {
            if(is_lock_safe() && lockChecker()) {
                is_suspended = true;
                mg_suspend_memory_logging_and_dump_memory(file_identify);
                break;
            }
            resume_other_threads();
        }
        std::this_thread::yield();
        ++tryCount;
    }
}

ThreadSuspender::~ThreadSuspender() {
    if (is_suspended) {
        resume_other_threads();
    }
}

void
ThreadSuspender::resume() {
    if (is_suspended) {
        resume_other_threads();
        is_suspended = false;
    }
}

} // MemoryGraph
