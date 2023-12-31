//
//  file_fragment_c.c
//  Heimdallr-a123673f
//
//  Created by zhouyang11 on 2022/10/18.
//

#include "hmd_mmap_allocator.h"
#include <unordered_map>
#include <pthread/pthread.h>
#include <memory>

#import "hmd_file_fragment.h"
#import "hmd_virtual_memory_macro.h"
#import "HMDALogProtocol.h"

using namespace HMDMemoryAllocator;
using namespace std;

using HMDMemoryAllocatorMap = unordered_map<const char*, MemoryAllocator*>;

namespace  {

#if HMDSlardarMallocMultiInstance == 0
MemoryAllocator *allocator_instance = NULL;
#endif

pthread_rwlock_t* global_rwmutex() {
    static pthread_rwlock_t mutex = PTHREAD_RWLOCK_INITIALIZER;
    return &mutex;
}

HMDMemoryAllocatorMap* global_allocator_map() {
    static HMDMemoryAllocatorMap* global_map = new HMDMemoryAllocatorMap();
    return global_map;
}
}

MemoryAllocator*
find_allocator(const char* identifier) {
    MemoryAllocator *res = NULL;
#if HMDSlardarMallocMultiInstance == 1
    pthread_rwlock_rdlock(global_rwmutex());
    auto it = global_allocator_map()->find(identifier);
    if (it == global_allocator_map()->end()) {
        HMD_ALOG_PROTOCOL_ERROR_TAG("Heimdallr", "[MemoryAllocator] with identifier %s used before initialized ", identifier);
        ff_assert(0);
        res = NULL;
    }else {
        res = it->second;
    }
    pthread_rwlock_unlock(global_rwmutex());
#else
    res = allocator_instance;
#endif
    return res;
}

bool hmd_mmap_memory_allocator_init(MemoryAllocatorConfig config) {
    ff_print_start();
#if HMDSlardarMallocMultiInstance == 1
    pthread_rwlock_rdlock(global_rwmutex());
    if (global_allocator_map()->find(config.identifier) != global_allocator_map()->end()) {
        HMD_ALOG_PROTOCOL_ERROR_TAG("Heimdallr", "[MemoryAllocator] with identifier %s initialized twice", config.identifier);
        ff_assert(0);
        pthread_rwlock_unlock(global_rwmutex());
        return false;
    }
    pthread_rwlock_unlock(global_rwmutex());
#endif
    auto allocator = new MemoryAllocator(config);
    int error_code = allocator->error_code();
    if (error_code != 0) {
        ff_printf("ff-initilize fail with code %d\n", error_code);
        return false;
    }
#if HMDSlardarMallocMultiInstance == 0
    allocator_instance = allocator;
#else
    pthread_rwlock_wrlock(global_rwmutex());
    global_allocator_map()->emplace(config.identifier, allocator);
    pthread_rwlock_unlock(global_rwmutex());
#endif
    return true;
}

void hmd_mmap_memory_allocator_destory(const char* _Nonnull identifier) {
    pthread_rwlock_rdlock(global_rwmutex());
    auto it = global_allocator_map()->find(identifier);
    if (it == global_allocator_map()->end()) {
        HMD_ALOG_PROTOCOL_ERROR_TAG("Heimdallr", "[MemoryAllocator] with identifier %s not exist", identifier);
        ff_assert(0);
        pthread_rwlock_unlock(global_rwmutex());
        return;
    }
    pthread_rwlock_unlock(global_rwmutex());
    pthread_rwlock_wrlock(global_rwmutex());
    global_allocator_map()->erase(it);
    pthread_rwlock_unlock(global_rwmutex());
    delete it->second;
}

void* hmd_mmap_memory_alloc(const char* identifier, void * __unused, size_t size, int __unused, int __unused, int __unused, off_t __unused) {
    if (size == 0) {
        return NULL;
    }
    auto allocator = find_allocator(identifier);
    return allocator->malloc(size);
}

void hmd_mmap_memory_free(const char* identifier, void* addr, size_t size) {
    if (addr == NULL) {
        return;
    }
    auto allocator = find_allocator(identifier);
    allocator->free(addr, size);
}

HMDMMapAllocatorStatus hmd_mmap_allocator_status(const char* identifier) {
    auto allocator = find_allocator(identifier);
    MemoryAllocatStatus status = allocator->status();
    ff_printf("ff- status availiable size = %fM, used size = %fM\n", status.first*1.0/k_mb, status.second*1.0/k_mb);
    return {status.first, status.second};
}

bool hmd_mmap_memory_allocator_check_address(const char* _Nonnull identifier, uintptr_t address, size_t size) {
    auto allocator = find_allocator(identifier);
    return allocator->check_address(address, size);
}

void hmd_mmap_memory_allocator_enumerator(const char* _Nonnull identifier) {
    auto allocator = find_allocator(identifier);
    allocator->enumerate_tree();
}

