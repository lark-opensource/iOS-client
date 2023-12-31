//
//  HMDCrashExtraDynamicData.h
//  Pods
//
//  Created by bytedance on 2020/7/29.
//

#ifndef HMDCrashExtraDynamicData_h
#define HMDCrashExtraDynamicData_h

#include <mach/machine.h>
#include <mach/mach_types.h>
#include "HMDPublicMacro.h"

HMD_EXTERN_SCOPE_BEGIN

typedef void (*hmd_crash_dynamic_data_callback)
    (char * _Nullable * _Nonnull dynamic_key,
     char * _Nullable * _Nonnull dynamic_data,
     uint64_t crash_time,
     uint64_t fault_address,
     thread_t current_thread,
     thread_t crash_thread);

typedef void (*extra_dynamic_data_callback)(const char * _Nullable key,
                                            const char * _Nullable value,
                                            void * _Nullable ctx);
    
bool hmd_crash_has_extra_dynamic_data_callback(void);

void hmd_crash_extra_dynamic_data_add_callback(hmd_crash_dynamic_data_callback _Nullable callback);

void hmd_crash_extra_dynamic_data_remove_callback(hmd_crash_dynamic_data_callback _Nullable callback);

void hmd_crash_async_enumerate_extra_dynamic_data(uint64_t crash_time,
                                                  uint64_t fault_address,
                                                  thread_t current_thread,
                                                  thread_t crash_thread,
                                                  extra_dynamic_data_callback _Nonnull callback,
                                                  void * _Nullable ctx);

HMD_EXTERN_SCOPE_END

#endif /* HMDCrashExtraDynamicData_h */
