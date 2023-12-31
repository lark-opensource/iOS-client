//
//  HMDRecordCleanALog.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/11/17.
//

#import "HMDRecordCleanALog.h"
#include <stdbool.h>
#include "HMDALogProtocol.h"

void hmdPerfReportClearModuleDataALog(const char *moduleName) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr performance data report success and clear reported data,module name: %s .", moduleName);
    }
}

void hmdPerfReportClearDataALog(void) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr performance data report success and clear reported data.");
    }
}

void hmdDebugRealReportClearModuleDataALog(const char *moduleName) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr DebugReal(cloud command) performance data report success and clear reported data,module name: %s .", moduleName);
    }
}

void hmdDebugRealReportClearDataALog(void) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr DebugReal(cloud command) performance data report success and clear reported data.");
    }
}

void hmdDBClearModuleNeedlessReportDataALog(const char *moduleName) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr the database size out of threshold and clear needless report data, module name: %s .", moduleName);
    }
}

void hmdDBClearModuleThresholdDataALog(const char *moduleName) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr the database size out of threshold and clear module data by priority, module name: %s .", moduleName);
    }
}

void hmdDBClearThresholdDataALog(void) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr the database size out of threshold and clear module data by priority.");
    }
}

void hmdSizeLimitPerfReportClearModuleDataALog(const char *moduleName) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr performance data size limited report success and clear reported data,module name: %s .", moduleName);
    }
}

void hmdSizeLimitPerfReportClearDataALog(void) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr performance data size limited report success and clear reported data.");
    }
}

void hmdPerfDropModuleAllDataALog(const char *moduleName, const char *aid) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr performance data drop module all data and cache,module name: %s appID: %s.", moduleName, aid);
    }
}

void hmdPerfDropAllDataALog(void) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr performance data drop module all data and cache.");
    }
}

void hmdPerfDropDataALog(void) {
    if (hmd_log_enable()) {
        HMD_ALOG_PROTOCOL_INFO_TAG("Heimdallr", "Heimdallr performance data drop module data.");
    }
}
