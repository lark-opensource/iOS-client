//
//  HMDCrashExtraDynamicData.hpp
//  Pods
//
//  Created by bytedance on 2020/7/29.
//

#ifndef HMDCrashExtraDynamicData_hpp
#define HMDCrashExtraDynamicData_hpp

#include <mach/machine.h>
#include <mach/mach_types.h>

typedef void (* _Nullable hmd_crash_dynamic_data_callback)(char ** _Nullable dynamic_key, char ** _Nullable dynamic_data, uint64_t crash_time, uint64_t fault_address, thread_t current_thread, thread_t crash_thread);
typedef void (* _Nullable extra_dynamic_data_callback)(const char * _Nullable key, const char * _Nullable value, void * _Nullable ctx);

#ifdef __cplusplus
extern "C" {
#endif
    
    bool hmd_crash_has_extra_dynamic_data_callback(void);
    void hmd_crash_extra_dynamic_data_add_callback(hmd_crash_dynamic_data_callback callback);
    void hmd_crash_extra_dynamic_data_remove_callback(hmd_crash_dynamic_data_callback callback);

    void hmd_crash_async_enumerate_extra_dynamic_data(uint64_t crash_time, uint64_t fault_address, thread_t current_thread, thread_t crash_thread, extra_dynamic_data_callback callback, void *ctx);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashExtraDynamicData_hpp */
