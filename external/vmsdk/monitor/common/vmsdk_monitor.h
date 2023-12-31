// Copyright 2022 The vmsdk Authors. All rights reserved.

#ifndef VMSDK_MONITOR_H
#define VMSDK_MONITOR_H

#ifdef __cplusplus
extern "C" {
#endif

#define MODULE_PRIMJS "primjs"
#define MODULE_QUICK "quickjs"

#define MODULE_NAPI "napi"
#define DEFAULT_BIZ_NAME "unknown_biz_name"
#define MODULE_VMSDK_WASM "VmsdkWasm"

void MonitorEvent(const char* moduleName, const char* bizName,
                  const char* dataKey, const char* dataValue);
bool GetSettingsWithKey(const char* key);

#ifdef __cplusplus
}
#endif

#endif  // VMSDK_MONITOR_ANDROID_H
