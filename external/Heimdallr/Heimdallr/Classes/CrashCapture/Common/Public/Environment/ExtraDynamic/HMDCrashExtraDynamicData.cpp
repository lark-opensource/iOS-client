//
//  HMDCrashExtraDynamicData.cpp
//  Pods
//
//  Created by bytedance on 2020/7/29.
//

#include "HMDMacro.h"
#include "HMDCrashExtraDynamicData.h"
#include "HMDCrashAsyncContainer.hpp"
#include <unordered_set>
#include <stdatomic.h>
#include <pthread.h>

[[clang::no_destroy]] static std::unordered_set<hmd_crash_dynamic_data_callback> callbacks;
static pthread_rwlock_t lock = PTHREAD_RWLOCK_INITIALIZER;
static volatile atomic_bool has_callbacks;

bool hmd_crash_has_extra_dynamic_data_callback(void)
{
    return atomic_load_explicit(&has_callbacks, memory_order_acquire);
}

void hmd_crash_extra_dynamic_data_add_callback(hmd_crash_dynamic_data_callback callback)
{
    if (callback) {
        pthread_rwlock_wrlock(&lock);
        callbacks.insert(callback);
        atomic_store_explicit(&has_callbacks, true, memory_order_release);
        pthread_rwlock_unlock(&lock);
    }
}

void hmd_crash_extra_dynamic_data_remove_callback(hmd_crash_dynamic_data_callback callback)
{
    if (callback) {
        pthread_rwlock_wrlock(&lock);
        callbacks.erase(callback);
        bool is_empty = callbacks.empty();
        atomic_store_explicit(&has_callbacks, !is_empty, memory_order_release);
        pthread_rwlock_unlock(&lock);
    }
}

void hmd_crash_async_enumerate_extra_dynamic_data(uint64_t crash_time,
                                                  uint64_t fault_address,
                                                  thread_t current_thread,
                                                  thread_t crash_thread,
                                                  extra_dynamic_data_callback callback,
                                                  void * ctx)
{
    if (NULL == callback) DEBUG_RETURN_NONE;
    
    if (pthread_rwlock_tryrdlock(&lock) != 0) return;
    
    for (auto iterator = callbacks.begin(); iterator != callbacks.end(); iterator++) {
        char * key = NULL;
        char * value = NULL;
        
        hmd_crash_dynamic_data_callback _Nullable data_callback = *iterator;
        
        if(data_callback == NULL) DEBUG_RETURN_NONE;
        
        data_callback(&key, &value, crash_time, fault_address, current_thread, crash_thread);
        
        if (key && value) {
            callback(key, value, ctx);
        }
    }
    pthread_rwlock_unlock(&lock);
}
