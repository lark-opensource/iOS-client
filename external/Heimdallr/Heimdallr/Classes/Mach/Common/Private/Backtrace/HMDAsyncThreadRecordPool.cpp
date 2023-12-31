//
//  HMDAsyncThreadRecordPool.c
//  Pods
//
//  Created by wangyinhui on 2022/9/14.
//
#include <stdlib.h>
#include <pthread.h>
#include <mach/vm_map.h>
#include <mach/mach_init.h>
#include <map>

#include "HMDAsyncThreadRecordPool.h"


#define HMD_MAX_ASYNC_STACK_POOL_SIZE 2000
#define HMD_MAX_ASYNC_STACK_THREAD_USED_RECORD_COUNT 20


typedef struct hmd_async_stack_free_slots {
    size_t free_slot_length;
    size_t *free_record_indexes;
    pthread_mutex_t lock;
    size_t pool_size;
} hmd_async_stack_free_slots_t;

//contiguous array to store records.
static hmd_async_stack_record_t * hmd_async_stack_record_pool;
//store free index of record pool.
static hmd_async_stack_free_slots_t hmd_async_stack_record_slot;
//store the number of records currently not released by all threads
static std::map<thread_t, size_t> hmd_async_stack_thread_used_record_count_map;


bool hmd_init_async_stack_pool(size_t pool_size) {
    if (pool_size > HMD_MAX_ASYNC_STACK_POOL_SIZE) {
        pool_size = HMD_MAX_ASYNC_STACK_POOL_SIZE;
    }
    
    // Vm alloca max size will be used, But we will use it gradually and it will not take up too much physical memory.
    vm_address_t address = 0;
    size_t allocation_size = round_page(HMD_MAX_ASYNC_STACK_POOL_SIZE * sizeof(hmd_async_stack_record_t));
    kern_return_t kr = vm_allocate(mach_task_self(), &address, allocation_size, VM_FLAGS_ANYWHERE);
    
    if (kr != KERN_SUCCESS) {
        return false;
    }
    
    hmd_async_stack_record_pool = (hmd_async_stack_record_t *) address;
    if (!hmd_async_stack_record_pool) {
        return false;
    }
    
    hmd_async_stack_record_slot.free_slot_length = pool_size;
    hmd_async_stack_record_slot.pool_size = pool_size;
    hmd_async_stack_record_slot.free_record_indexes = (size_t *) calloc(HMD_MAX_ASYNC_STACK_POOL_SIZE, sizeof(size_t));
    if (!hmd_async_stack_record_slot.free_record_indexes) {
        vm_deallocate(mach_task_self(), address, allocation_size);
        hmd_async_stack_record_pool = NULL;
        return false;
    }
    for (int i=0; i<pool_size; i++) {
        hmd_async_stack_record_pool[i].pool_index = i;
        hmd_async_stack_record_slot.free_record_indexes[i] = i;
    }
    pthread_mutex_init(&hmd_async_stack_record_slot.lock, NULL);
    return true;
}

hmd_async_stack_record_t* hmd_allocate_async_stack_pool_record(thread_t tid) {
    pthread_mutex_lock(&hmd_async_stack_record_slot.lock);
    
    auto it = hmd_async_stack_thread_used_record_count_map.find(tid);
    if (it != hmd_async_stack_thread_used_record_count_map.end()) {
        if (it->second >= HMD_MAX_ASYNC_STACK_THREAD_USED_RECORD_COUNT) {
            //thread used too much records with out free, before these records are released, allocation is prohibited
            pthread_mutex_unlock(&hmd_async_stack_record_slot.lock);
            return NULL;
        }else {
            it->second++;
        }
    }else {
        hmd_async_stack_thread_used_record_count_map[tid] = 1;
    }
    
    if(hmd_async_stack_record_slot.free_slot_length == 0) {
        //free pool use up,we will occupation 20 pages physical memory
        int new_pool_size = (int)(round_page(hmd_async_stack_record_slot.pool_size * sizeof(hmd_async_stack_record_t)) + 20*PAGE_SIZE) /sizeof(hmd_async_stack_record_t);

        if (new_pool_size <= HMD_MAX_ASYNC_STACK_POOL_SIZE) {
            for (size_t i=hmd_async_stack_record_slot.pool_size; i<new_pool_size; i++) {
                hmd_async_stack_record_pool[i].pool_index = (int)i;
                hmd_async_stack_record_slot.free_record_indexes[i-hmd_async_stack_record_slot.pool_size] = i;
            }
            hmd_async_stack_record_slot.free_slot_length = new_pool_size - hmd_async_stack_record_slot.pool_size;
            hmd_async_stack_record_slot.pool_size = new_pool_size;
        }else {
            pthread_mutex_unlock(&hmd_async_stack_record_slot.lock);
            return NULL;
        }
    }
    if(hmd_async_stack_record_slot.free_slot_length > HMD_MAX_ASYNC_STACK_POOL_SIZE) {
        pthread_mutex_unlock(&hmd_async_stack_record_slot.lock);
        return NULL;
    }
    size_t free_index = hmd_async_stack_record_slot.free_record_indexes[--hmd_async_stack_record_slot.free_slot_length];
    if (free_index >= hmd_async_stack_record_slot.pool_size) {
        pthread_mutex_unlock(&hmd_async_stack_record_slot.lock);
        return NULL;
    }
    pthread_mutex_unlock(&hmd_async_stack_record_slot.lock);
    return &hmd_async_stack_record_pool[free_index];
}

void hmd_free_async_stack_pool_record(hmd_async_stack_record_t* record) {
    if(!record) {
        return;
    }
    size_t pool_index = record->pool_index;
    if(pool_index >= hmd_async_stack_record_slot.pool_size) {
        return;
    }
    hmd_async_stack_record_pool[pool_index].valid = false;
    
    pthread_mutex_lock(&hmd_async_stack_record_slot.lock);
    
    auto it = hmd_async_stack_thread_used_record_count_map.find(record->pre_thread);
    if (it != hmd_async_stack_thread_used_record_count_map.end()) {
        it->second--;
    }
    
    hmd_async_stack_record_slot.free_record_indexes[hmd_async_stack_record_slot.free_slot_length++] = pool_index;
    
    pthread_mutex_unlock(&hmd_async_stack_record_slot.lock);
}

hmd_async_stack_record_t* hmd_get_async_stack_pool_record_mach_thread(thread_t thread) {
    if (hmd_async_stack_record_pool) {
        for (int i=0; i<hmd_async_stack_record_slot.pool_size; i++) {
            if (hmd_async_stack_record_pool[i].thread == thread) {
                if (hmd_async_stack_record_pool[i].length > HMD_MAX_ASYNC_STACK_LENGTH) {
                    return NULL;
                }
                return &hmd_async_stack_record_pool[i];
            }
        }
    }
    return NULL;
}

hmd_async_stack_record_t* hmd_get_async_stack_pool_record_pthread(pthread_t thread) {
    if (hmd_async_stack_record_pool) {
        for (int i=0; i<hmd_async_stack_record_slot.pool_size; i++) {
            if (hmd_async_stack_record_pool[i].pthread == thread) {
                if (hmd_async_stack_record_pool[i].length > HMD_MAX_ASYNC_STACK_LENGTH) {
                    return NULL;
                }
                return &hmd_async_stack_record_pool[i];
            }
        }
    }
    return NULL;
}










