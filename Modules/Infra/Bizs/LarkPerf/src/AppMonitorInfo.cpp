//
//  AppMonitorInfo.cpp
//  LarkPerf
//
//  Created by qihongye on 2020/6/23.
//

#include "AppMonitorInfoPrivate.h"

#include <stdio.h>
#include <atomic>
#include <mutex>

typedef struct AppMonitorInfo {
    double startupTimeStamp;
    std::atomic<double> enterForegroundTimeStamp;
} AppMonitorInfo;

AppMonitorInfo appMonitorInfo = { 0 };

std::once_flag m_flag;

extern "C" {
    LOCAL const double app_monitor_get_startup_timestamp() {
        return appMonitorInfo.startupTimeStamp;
    };

    LOCAL void app_monitor_set_startup_timestamp(const double timeStamp) {
        std::call_once(m_flag, [timeStamp](){
            appMonitorInfo.startupTimeStamp = timeStamp;
        });
    };

    LOCAL const double app_monitor_get_enter_foreground_timestamp() {
        return appMonitorInfo.enterForegroundTimeStamp.load();
    };

    LOCAL void app_monitor_set_enter_foreground_timestamp(const double timeStamp) {
        appMonitorInfo.enterForegroundTimeStamp = timeStamp;
    };
}
