//
//  HMDCrashException_dynamicData.h
//  Pods
//
//  Created by someone on someday
//

#ifndef HMDCrashException_dynamicData_h
#define HMDCrashException_dynamicData_h

#include <mach/mach.h>
#include <stdbool.h>
#include <stdint.h>

#include "HMDCrashHeader.h"

EXTERN_C

bool hmd_exception_dynamic_create_file(void);

void hmd_exception_dynamic_write_dynamic_info(void);

void hmd_exception_dynamic_write_extra_dynamic_info(uint64_t crash_time,
                                                    uint64_t fault_address,
                                                    thread_t current_thread,
                                                    thread_t crash_thread);

void hmd_exception_dynamic_write_vid(uint64_t crash_time,
                                    uint64_t fault_address,
                                    thread_t current_thread,
                                            thread_t crash_thread);

void hmd_exception_dynamic_write_save_files(void);

void hmd_exception_dynamic_write_game_script_stack(uint64_t crash_time,
                                                   uint64_t fault_address,
                                                   thread_t current_thread,
                                                   thread_t crash_thread);

bool hmd_exception_close_dynamic_data_file(void);

EXTERN_C_END

#endif /* HMDCrashException_dynamicData_h */
