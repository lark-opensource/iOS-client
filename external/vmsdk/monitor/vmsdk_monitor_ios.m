// Copyright 2022 The vmsdk Authors. All rights reserved.

#ifndef VMSDK_MONITOR_IOS_H
#define VMSDK_MONITOR_IOS_H

#import "monitor/vmsdk_monitor_ios.h"

#include "monitor/VmsdkMonitor.h"
#include "monitor/VmsdkSettingsManager.h"

void MonitorEventIOS(const char *moduleName, const char *bizName, const char *dataKey,
                     const char *dataValue) {
  if (moduleName == NULL || bizName == NULL || dataKey == NULL || dataValue == NULL) {
    return;
  }
  NSString *module_name = [NSString stringWithCString:moduleName encoding:NSUTF8StringEncoding];
  NSString *biz_name = [NSString stringWithCString:bizName encoding:NSUTF8StringEncoding];
  NSString *data_key = [NSString stringWithCString:dataKey encoding:NSUTF8StringEncoding];
  NSString *data_value = [NSString stringWithCString:dataValue encoding:NSUTF8StringEncoding];

  NSLog(@"===VMSDK MonitorEventIOS=== module_name: %@ biz_name: %@, data_key: %@, data_value: %@",
        module_name, biz_name, data_key, data_value);

  NSDictionary *category = @{@"biz_name" : biz_name, data_key : data_value};
  [VmsdkMonitor monitorEventStatic:module_name metric:NULL category:category extra:NULL];
}

bool GetSettingsFromCacheIOS(const char *key) {
  NSString *settings_key = [NSString stringWithCString:key encoding:NSUTF8StringEncoding];
  return [[VmsdkSettingsManager shareInstance] getSettingsFromCache:settings_key];
}

#endif  // VMSDK_MONITOR_IOS_H
