//
//  HMDOOMCrashSDKLog.h
//  Pods
//
//  Created by bytedance on 2020/3/5.
//

#ifndef HMDOOMCrashSDKLog_h
#define HMDOOMCrashSDKLog_h

#include <stdbool.h>

__BEGIN_DECLS

/**
 This should be used before any log

 @param path any inter dir should already created
 @return true if open success, false to log SDK
 */
 bool hmd_oom_crash_open_log(const char * _Nonnull path);

/**
 This should be used after the hmd_oom_crash_open_log

 @param level level string to describe
 @param format same as printf
 */
void hmd_oom_crash_log_str(const char * _Nonnull level, const char * _Nonnull file, int line, const char * _Nullable format, ...);

void hmd_oom_crash_close_log(void);

__END_DECLS

#ifdef __FILE_NAME__
#define __OOMCRASH_FILE_NAME__ __FILE_NAME__
#else
#define __OOMCRASH_FILE_NAME__ __FILE__
#endif

#define OOMLog(format, ...)       hmd_oom_crash_log_str("INFO ", __OOMCRASH_FILE_NAME__, __LINE__, format, ## __VA_ARGS__)
#define OOMLog_warn(format, ...)  hmd_oom_crash_log_str("WARN ", __OOMCRASH_FILE_NAME__, __LINE__, format, ## __VA_ARGS__)
#define OOMLog_error(format, ...) hmd_oom_crash_log_str("ERROR", __OOMCRASH_FILE_NAME__, __LINE__, format, ## __VA_ARGS__)


#endif /* HMDOOMCrashSDKLog_h */
