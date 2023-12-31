// Copyright 2021 The vmsdk Authors. All rights reserved.

#ifdef __cplusplus
extern "C" {
#endif

#include "monitor/common/vmsdk_monitor.h"
#if OS_ANDROID
#include "monitor/android/vmsdk_monitor_android.h"
#endif
#ifdef OS_IOS
#include "monitor/vmsdk_monitor_ios.h"
#endif

void MonitorEvent(const char* moduleName, const char* bizName,
                  const char* dataKey, const char* dataValue) {
#if OS_ANDROID
  vmsdk::monitor::android::VmSdkMonitorAndroid::MonitorEvent(
      moduleName, bizName, dataKey, dataValue);
#endif

#ifdef OS_IOS
  MonitorEventIOS(moduleName, bizName, dataKey, dataValue);
#endif
}

bool GetSettingsWithKey(const char* key) {
#if OS_ANDROID
  return vmsdk::monitor::android::VmSdkMonitorAndroid::GetSettingsWithKey(key);
#endif

#ifdef OS_IOS
  return GetSettingsFromCacheIOS(key);
#endif
}

#ifdef __cplusplus
}
#endif
