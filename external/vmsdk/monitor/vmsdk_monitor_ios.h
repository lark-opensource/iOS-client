// Copyright 2022 The vmsdk Authors. All rights reserved.

#ifndef VMSDK_MONITOR_IOS_H
#define VMSDK_MONITOR_IOS_H

/**
 * native module event upload method
 * @param moduleName Native module name: quick, napi
 * @param bizName business name: lynx, effect
 * @param dataKey key
 * @param dataValue value
 */
void MonitorEventIOS(const char* moduleName, const char* bizName,
                     const char* dataKey, const char* dataValue);

bool GetSettingsFromCacheIOS(const char* key);

#endif  // VMSDK_MONITOR_IOS_H
