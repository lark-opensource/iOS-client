//
//  ff_allocater_config.h
//  file_fragment
//
//  Created by zhouyang11 on 2021/10/12.
//

#ifndef ff_allocater_config_h
#define ff_allocater_config_h

#define k_mb (1024*1024)
#define k_gb (1024L*1024L*1024L)

#if DEBUG
//#define hmd_memory_map_log_enable
#endif

#ifdef hmd_memory_map_log_enable
#define ff_assert(x) assert(x)
#define ff_break __builtin_trap()
#define ff_printf(format,...)  \
printf(format,##__VA_ARGS__);    \
ff_log(format,##__VA_ARGS__)
#else
#define ff_assert(x)
#define ff_break
#define ff_printf(format,...) ff_log(format,##__VA_ARGS__)
#endif

// bytest开关
//#define HMDBytestDefine

#ifdef HMDBytestDefine
#define ff_print_start()         hmd_memory_log_start()
#define ff_log(format,...)  hmd_memory_log_to_file(format,##__VA_ARGS__)
#define ff_print_end()            hmd_memory_log_end()
#define ff_enumerate_tree() enumerate_tree()
#else
#define ff_print_start()
#define ff_log(format,...)
#define ff_print_end()
#define ff_enumerate_tree()
#endif

// 切换多实例开关
#define HMDSlardarMallocMultiInstance 0

#define allocate_file_entry_memory (file_map_entry_t)malloc_zone_calloc(HMDMMapAllocator::g_malloc_zone(), 1, sizeof(file_map_entry))
#define deallocate_file_entry_memory(x) malloc_zone_free(HMDMMapAllocator::g_malloc_zone(), x)
#define allocate_memory_block_memory (file_map_entry_t)malloc_zone_calloc(HMDMMapAllocator::g_malloc_zone(), 1, sizeof(file_map_entry))

#include <stdint.h>
#include <assert.h>
#include "hmd_mmap_allocator.h"

#endif /* ff_allocater_config_h */
