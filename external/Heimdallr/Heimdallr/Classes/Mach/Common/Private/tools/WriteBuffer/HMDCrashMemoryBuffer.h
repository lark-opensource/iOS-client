//
//  HMDCrashMemoryBuffer.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/20.
//

#ifndef HMDCrashMemoryBuffer_h
#define HMDCrashMemoryBuffer_h

#include <stdio.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

extern const char hmd_crash_hex_array[];

bool hmd_memory_write_int64(char *buffer, int length, int64_t val);

bool hmd_memory_write_uint64(char *buffer, int length, uint64_t val);

bool hmd_memory_write_uint64_hex(char *buffer, int length, uint64_t val);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashMemoryBuffer_h */
