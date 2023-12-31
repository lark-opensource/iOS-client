//
//  HMDCrashDynamicData.c
//  Pods
//
//  Created by yuanzhangjing on 2019/12/8.
//

#include "HMDCrashDynamicData.h"
#include "HMDCrashAsyncContainer.hpp"
#include <stdatomic.h>

static hmd_async_dict dict;
static volatile atomic_bool once_token;

void hmd_crash_init_dynamic_data(void) {
    if (atomic_load_explicit(&once_token,memory_order_acquire)) {
        return;
    }
    hmd_nasync_dict_init(&dict, true);
    atomic_store_explicit(&once_token,true,memory_order_release);
}

bool hmd_crash_dynamic_data_has_setup(void) {
    return atomic_load_explicit(&once_token,memory_order_acquire);
}

void hmd_crash_store_dynamic_data(const char *key, const char *value) {
    if (!hmd_crash_dynamic_data_has_setup()) {
        return;
    }
    hmd_nasync_dict_update(&dict, key, value);
}

void hmd_crash_remove_dynamic_data(const char *key) {
    if (!hmd_crash_dynamic_data_has_setup()) {
        return;
    }
    hmd_nasync_dict_remove(&dict, key);
}

void hmd_crash_async_enumerate_entries(hmd_async_dict_callback callback, void *ctx) {
    if (!hmd_crash_dynamic_data_has_setup()) {
        return;
    }
    hmd_async_enumerate_entries(&dict, callback, ctx);
}
