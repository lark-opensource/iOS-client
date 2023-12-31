//
//  file_fragment_c.h
//  Heimdallr-a123673f
//
//  Created by zhouyang11 on 2022/10/18.
//

#ifndef file_fragment_c_h
#define file_fragment_c_h

#include <stdio.h>
#include "HMDSlardarMallocOptimizeConfig.h"

#define __unused __attribute__((__unused__))

struct HMDMMapAllocatorStatus {
    size_t availiable_size;
    size_t used_size;
};

typedef struct HMDMMapAllocatorStatus HMDMMapAllocatorStatus;
typedef struct HMDMMapAllocatorConfig MemoryAllocatorConfig;

#define hmd_alloc(identifier, x) hmd_mmap_memory_alloc(identifier, NULL, x, 0, 0, 0, 0)
#define hmd_free(identifier, ptr, size) hmd_mmap_memory_free(identifier, ptr, size)

#ifdef __cplusplus
extern "C" {
#endif

bool  hmd_mmap_memory_allocator_init(MemoryAllocatorConfig config);
void* _Nullable hmd_mmap_memory_alloc(const char* _Nonnull identifier, void * __unused _Nullable, size_t, int __unused, int __unused, int __unused, off_t __unused);
void  hmd_mmap_memory_free(const char* _Nonnull identifier, void*_Nullable, size_t);
HMDMMapAllocatorStatus  hmd_mmap_allocator_status(const char* _Nonnull identifier);
bool hmd_mmap_memory_allocator_check_address(const char* _Nonnull identifier, uintptr_t address, size_t size);
void hmd_mmap_memory_allocator_destory(const char* _Nonnull identifier);
void hmd_mmap_memory_allocator_enumerator(const char* _Nonnull identifier);
#ifdef __cplusplus
} // extern "C"
#endif


#endif /* file_fragment_c_h */
