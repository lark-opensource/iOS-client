//
//  SlardarMallocRemap.h
//  Heimdallr
//
//  Created by zhouyang11 on 2022/12/28.
//

#ifndef SlardarMallocRemap_h
#define SlardarMallocRemap_h

#include <stdio.h>
#include <stdbool.h>
#import "hmd_mmap_allocator.h"

#ifdef __cplusplus
extern "C" {
#endif

bool slardar_vm_alloc_start(MemoryAllocatorConfig config);
bool enable_vm_map(MemoryAllocatorConfig config);
bool slardar_memory_remap(const char* identifier, void* src, size_t size);
bool slardar_memory_unmap(const char* identifier, void* src, size_t size);

void vmrecorder_enumerator(const char* identifier);

void slardar_vm_alloc_stop(void);

#ifdef __cplusplus
} // extern "C"
#endif
#endif /* SlardarMallocRemap_h */
