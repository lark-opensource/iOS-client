//
//  HMDThreadManager.cpp
//  Hello
//
//  Created by zhouyang11 on 2021/12/3.
//  Copyright © 2021 zhouyang11. All rights reserved.
//

#include "HMDThreadSuspender.h"
#include <pthread.h>
#include <mach/mach.h>
#include <thread>
#include <objc/runtime.h>

namespace HMDThreadSuspender {

vm_address_t threads_to_be_free = 0;
size_t size_to_be_free = 0;

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
    threads_to_be_free = (vm_address_t)threads;
    size_to_be_free = sizeof(thread_t) * numThreads;
    
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
//    vm_deallocate(thisTask, (vm_address_t)threads, sizeof(thread_t) * numThreads);
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
    if (threads_to_be_free != 0 && size_to_be_free != 0) {
        vm_deallocate(mach_task_self(), threads_to_be_free, size_to_be_free);
        threads_to_be_free = 0;
        size_to_be_free = 0;
    }
}

ThreadSuspender::ThreadSuspender(): is_suspended(false) {
    int tryCount = 0;
    while (tryCount < 48) {
        if (suspend_other_threads()) {
            is_suspended = true;
            break;
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

} // HMDThreadSuspender
