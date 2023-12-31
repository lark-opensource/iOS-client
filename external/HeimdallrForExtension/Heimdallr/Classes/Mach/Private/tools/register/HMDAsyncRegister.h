//
//  HMDAsyncRegister.h
//  Heimdallr
//
//  Created by yuanzhangjing on 2020/1/22.
//

#ifndef HMDAsyncRegister_h
#define HMDAsyncRegister_h

#include <stdio.h>
#include "hmd_types.h"

#ifdef __cplusplus
extern "C" {
#endif

int hmd_num_registers(void);

const char* hmd_register_name(const int regNumber);

uintptr_t hmd_register_value(const hmd_thread_state_t* const context, const int regNumber);

int hmd_num_exception_registers(void);

const char* hmd_exception_register_name(const int regNumber);

uintptr_t hmd_exception_register_value(const hmd_thread_state_t* const context, const int regNumber);


#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDAsyncRegister_h */
