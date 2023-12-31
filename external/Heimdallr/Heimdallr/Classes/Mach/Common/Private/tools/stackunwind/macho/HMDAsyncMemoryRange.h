//
//  HMDAsyncMemoryRange.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/2.
//

#ifndef HMDAsyncMemoryRange_h
#define HMDAsyncMemoryRange_h

#include <stdio.h>
#include "hmd_types.h"

#ifdef __cplusplus
extern "C" {
#endif


typedef struct hmd_async_mem_range
{
    hmd_vm_address_t addr;
    hmd_vm_size_t size;
} hmd_async_mem_range;

void * hmd_async_mem_range_pointer(hmd_async_mem_range range,hmd_vm_off_t offset,hmd_vm_size_t size);

bool hmd_async_mem_range_verify(hmd_async_mem_range range,hmd_vm_address_t addr,hmd_vm_size_t size);

bool hmd_async_mem_range_verify_offset(hmd_async_mem_range range,hmd_vm_address_t addr,hmd_vm_off_t offset,hmd_vm_size_t size);

//bool hmd_async_mem_range_init(hmd_async_mem_range *range,hmd_vm_address_t addr,hmd_vm_size_t size);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDAsyncMemoryRange_h */
