//
//  HMDCrashDynamicData.h
//  Pods
//
//  Created by yuanzhangjing on 2019/12/8.
//

#ifndef HMDCrashDynamicData_h
#define HMDCrashDynamicData_h

#include <stdio.h>
#include <stdbool.h>
#include "HMDCrashAsyncContainer.hpp"
#ifdef __cplusplus
extern "C" {
#endif

    void hmd_crash_init_dynamic_data(void);
    bool hmd_crash_dynamic_data_has_setup(void);
    void hmd_crash_store_dynamic_data(const char *key, const char *value);
    void hmd_crash_remove_dynamic_data(const char *key);
    void hmd_crash_async_enumerate_entries(hmd_async_dict_callback callback, void *ctx);

#ifdef __cplusplus
} // extern "C"
#endif

#endif /* HMDCrashDynamicData_h */
