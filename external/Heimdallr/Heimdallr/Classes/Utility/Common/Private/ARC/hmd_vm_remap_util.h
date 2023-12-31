//
//  HMDVMRemapUtil.h
//  Heimdallr
//
//  Created by zhouyang11 on 2023/6/25.
//

#ifndef HMDVMRemapUtil_h
#define HMDVMRemapUtil_h

#include <stdio.h>
#include <mach/vm_types.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

bool hmd_vm_remap(void* target_address, void* src_address, vm_size_t size);

#ifdef __cplusplus
} // extern "C"
#endif


#endif /* HMDVMRemapUtil_h */
