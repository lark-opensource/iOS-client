//
//  HMDCrashSDKLog.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/10.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashSDKLog_h
#define HMDCrashSDKLog_h

#include <stdbool.h>
#include "HMDCrashSDKLog_Namespace.h"

__BEGIN_DECLS

/**
 This should be used before any log

 @param path any inter dir should already created
 @return true if open success, false to log SDK
 */
 bool OpenSDK(const char *path);

/**
 This should be used after the OpenSDK

 @param level level string to describe
 @param format same as printf
 */
void SDKLogStr(const char *level, const char *file, int line, const char *format, ...);

void SDKLogBaseStr(const char *format, ...);

__END_DECLS
//__FILE_NAME__和Xcode版本有关，这里需要写个条件编译宏
#ifdef __FILE_NAME__
#define __HMD_FILE_NAME__ __FILE_NAME__
#else
#define __HMD_FILE_NAME__ __FILE__
#endif

#define SDKLog_basic(format, ...) SDKLogBaseStr(format, ## __VA_ARGS__)
#define SDKLog(format, ...)       SDKLogStr("INFO ", __HMD_FILE_NAME__, __LINE__, format, ## __VA_ARGS__)
#define SDKLog_warn(format, ...)  SDKLogStr("WARN ", __HMD_FILE_NAME__, __LINE__, format, ## __VA_ARGS__)
#define SDKLog_error(format, ...) SDKLogStr("ERROR", __HMD_FILE_NAME__, __LINE__, format, ## __VA_ARGS__)

#endif /* HMDCrashSDKLog_h */
