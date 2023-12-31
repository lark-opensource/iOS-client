//
//  HMDRecordCleanALog.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/11/17.
//

#ifdef __cplusplus
extern "C" {
#endif

void hmdPerfReportClearModuleDataALog(const char *moduleName);
void hmdPerfReportClearDataALog(void);
void hmdDebugRealReportClearModuleDataALog(const char *moduleName);
void hmdDebugRealReportClearDataALog(void);
void hmdDBClearModuleNeedlessReportDataALog(const char *moduleName);
void hmdDBClearModuleThresholdDataALog(const char *moduleName);
void hmdDBClearThresholdDataALog(void);
void hmdSizeLimitPerfReportClearModuleDataALog(const char *moduleName);
void hmdSizeLimitPerfReportClearDataALog(void);
void hmdPerfDropModuleAllDataALog(const char *moduleName, const char *aid);
void hmdPerfDropAllDataALog(void);
void hmdPerfDropDataALog(void);

#ifdef __cplusplus
} // extern "C"
#endif
