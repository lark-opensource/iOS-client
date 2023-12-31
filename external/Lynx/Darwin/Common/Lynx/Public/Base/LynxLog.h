// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef DARWIN_COMMON_LYNX_BASE_LYNXLOG_H_
#define DARWIN_COMMON_LYNX_BASE_LYNXLOG_H_

#import <Foundation/Foundation.h>
#import "LynxDefines.h"

#define LLog(...) _LynxLog(LynxLogLevelInfo, __VA_ARGS__)
#define LLogVerbose(...) _LynxLog(LynxLogLevelVerbose, __VA_ARGS__)
#define LLogDebug(...) _LynxLog(LynxLogLevelDebug, __VA_ARGS__)
#define LLogInfo(...) _LynxLog(LynxLogLevelInfo, __VA_ARGS__)
#define LLogWarn(...) _LynxLog(LynxLogLevelWarning, __VA_ARGS__)
#define LLogError(...) _LynxLog(LynxLogLevelError, __VA_ARGS__)
#define LLogReport(...) _LynxLog(LynxLogLevelError, __VA_ARGS__)
#define LLogFatal(...) _LynxLog(LynxLogLevelFatal, __VA_ARGS__)

// just provide for .m, same as LynxFatal/LynxWarning/LynxInfo in lynx_assert.h
#define LErrInfo(errCode, ...) _LynxErrorInfo(errCode, __VA_ARGS__)
#define LErrWarn(expression, errCode, ...) _LynxErrorWarning(expression, errCode, __VA_ARGS__)
#define LErrFatal(expression, errCode, ...) _LynxErrorFatal(expression, errCode, __VA_ARGS__)

typedef NS_ENUM(NSInteger, LynxLogLevel) {
  // LynxLogLevelReport is deprecated
  LynxLogLevelReport = -1,

  LynxLogLevelVerbose = 0,
  LynxLogLevelDebug = 1,
  LynxLogLevelInfo = 2,
  LynxLogLevelWarning = 3,
  LynxLogLevelError = 4,
  LynxLogLevelFatal = 5
};

typedef NS_OPTIONS(NSInteger, LynxLogSource) {
  LynxLogSourceNaitve = 1 << 0,
  LynxLogSourceJS = 1 << 1,
};

typedef void (^LynxLogFunction)(LynxLogLevel level, NSString *message);

@interface LynxLogObserver : NSObject

@property(nonatomic, copy) LynxLogFunction logFunction;
@property(nonatomic, assign) LynxLogLevel minLogLevel;
@property(nonatomic, assign) BOOL shouldFormatMessage;    // 默认为YES
@property(nonatomic, assign) LynxLogSource acceptSource;  // 默认为全部
@property(nonatomic, assign) NSInteger acceptRuntimeId;  // -1为接收全部runtime log，默认为-1

- (instancetype)initWithLogFunction:(LynxLogFunction)logFunction
                        minLogLevel:(LynxLogLevel)minLogLevel;

@end

// LynxLogDelegate is recommended and LynxLogObserver is prohibited.
typedef LynxLogObserver LynxLogDelegate;

LYNX_EXTERN void SetDebugLoggingDelegate(LynxLogDelegate *delegate);

LYNX_EXTERN NSInteger AddLoggingDelegate(LynxLogDelegate *delegate);
LYNX_EXTERN LynxLogDelegate *GetLoggingDelegate(NSInteger delegateId);
LYNX_EXTERN void RemoveLoggingDelegate(NSInteger delegateId);
LYNX_EXTERN void SetMinimumLoggingLevel(LynxLogLevel minLogLevel);
LYNX_EXTERN void SetJSLogsFromExternalChannels(bool isOpen);
LYNX_EXTERN LynxLogLevel GetMinimumLoggingLevel(void);

extern LynxLogFunction LynxDefaultLogFunction;

LYNX_EXTERN void LynxSetLogFunction(LynxLogFunction logFunction)
    __attribute__((deprecated("Use AddLoggingDelegate instead.")));
LYNX_EXTERN LynxLogFunction LynxGetLogFunction(void);

// deprecated: use AddLoggingDelegate instead.
LYNX_EXTERN NSInteger LynxAddLogObserver(LynxLogFunction logFunction, LynxLogLevel minLogLevel);
// deprecated: use AddLoggingDelegate instead.
LYNX_EXTERN NSInteger LynxAddLogObserverByModel(LynxLogObserver *observer);
// deprecated: use GetLoggingDelegate instead.
LYNX_EXTERN LynxLogObserver *LynxGetLogObserver(NSInteger observerId);
// deprecated: use RemoveLoggingDelegate instead.
LYNX_EXTERN void LynxRemoveLogObserver(NSInteger observerId);
LYNX_EXTERN NSArray<LynxLogObserver *> *LynxGetLogObservers(void);
LYNX_EXTERN void LynxSetMinLogLevel(LynxLogLevel minLogLevel)
    __attribute__((deprecated("Use SetMinimumLoggingLevel instead.")));
// deprecated: use GetMinimumLoggingLevel instead.
LYNX_EXTERN LynxLogLevel LynxGetMinLogLevel(void);

#define _LynxLog(log_level, ...) _LynxLogInternal(log_level, __VA_ARGS__)
LYNX_EXTERN void _LynxLogInternal(LynxLogLevel, NSString *, ...) NS_FORMAT_FUNCTION(2, 3);

#define _LynxErrorInfo(errCode, ...) _LynxErrorInfoInternal(errCode, __VA_ARGS__)
LYNX_EXTERN void _LynxErrorInfoInternal(NSInteger, NSString *, ...);

#define _LynxErrorWarning(expression, errCode, ...) \
  _LynxErrorWarningInternal(expression, errCode, __VA_ARGS__)
LYNX_EXTERN void _LynxErrorWarningInternal(bool, NSInteger, NSString *, ...);

#define _LynxErrorFatal(expression, errCode, ...) \
  _LynxErrorFatalInternal(expression, errCode, __VA_ARGS__)
LYNX_EXTERN void _LynxErrorFatalInternal(bool, NSInteger, NSString *, ...);

#pragma mark - Debug Log
#define LYNX_DEBUG_LOG(TAG, FORMAT, ...)                                        \
  do {                                                                          \
    fprintf(stderr, #TAG ", %s, %s\n", [NSStringFromSelector(_cmd) UTF8String], \
            [[[NSString stringWithFormat:FORMAT, ##__VA_ARGS__]                 \
                stringByReplacingOccurrencesOfString:@"\n"                      \
                                          withString:@""] UTF8String]);         \
  } while (0);

#endif  // DARWIN_COMMON_LYNX_BASE_LYNXLOG_H_
