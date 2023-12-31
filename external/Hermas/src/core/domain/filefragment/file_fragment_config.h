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

#ifdef  DEBUG
#define FileFragmentLogEnable
#endif

#ifdef FileFragmentLogEnable
#define ff_printf(...) printf(__VA_ARGS__)
#define ff_assert(x) assert(x)
#else
#define ff_printf(...)
#define ff_assert(x)
#endif

#include <stdint.h>
#include <assert.h>
#include <malloc/malloc.h>

int const memory_block_size_bit = sizeof(int32_t);
int const memory_block_size_offset = 1;
int const memory_block_inuse_bit = sizeof(char);
int const memory_block_inuse_offset = 0;

struct FFFileFragmentConfig {
    const char* file_path;      // 文件路径
    size_t file_min_capacity = 5*k_mb; // 初始大小，单位字节
    size_t file_grow_step = 5*k_mb; // 文件扩容最小单元，单位字节
};

#endif /* ff_allocater_config_h */
