//
//  HMDSlardarMallocOptimizeConfig.h
//  Pods
//
//  Created by zhouyang11 on 2023/11/16.
//

#ifndef HMDSlardarMallocOptimizeConfig_h
#define HMDSlardarMallocOptimizeConfig_h

#include <stdbool.h>

typedef enum : int8_t {
    HMDMMapMlockTypeDefault,
    HMDMMapMlockTypeSliceLock,      // 分块mlock，和mlock_slice_count关联，性能↑，内存压力↑
    HMDMMapMlockTypeDynamicLock,    // 动态mlock，malloc+mlock, free+munlock，性能↓，内存压力↓
    HMDMMapMlockTypeNoLock,         // 无锁
} HMDMMapMlockType;


typedef struct HMDMMapAllocatorConfig {
    const char* _Nullable file_path;    //default at tmp/hmd_mmap_allocator_tmp/memory_file
    size_t file_max_size;               // byte
    size_t file_grow_step;              // byte
    size_t file_initial_size;           // byte
    int8_t mlock_slice_count;           // per mlock scope is (block_total_size / mlock_slice_count)
    HMDMMapMlockType mlockType;         // mlock type
    bool page_aligned;                  // alloc/dealloc need page align
    bool use_anony_map_after_file_exhaust;
    bool need_internal_mutex_lock;
    const char* _Nullable remapped_tag_array; // seperate by ","
    const char* _Nonnull identifier;    // unique identifier of every instance
} MemoryAllocatorConfig;

typedef enum : int8_t {
    HMDNanoOptimizeResultDefault,
    HMDNanoOptimizeResultSuccess,
    HMDNanoOptimizeResultMemcmpFail,
    HMDNanoOptimizeResultNanoVersionNotMatch,
    HMDNanoOptimizeResultFileOperateFail,
    HMDNanoOptimizeResultMmapFail,
    HMDNanoOptimizeResultRemapFail
} HMDNanoOptimizeResult;

typedef struct hmd_nanozone_optimize_config{
    size_t optimize_size;
    bool need_mlock;
}hmd_nanozone_optimize_config;

#endif /* HMDSlardarMallocOptimizeConfig_h */
