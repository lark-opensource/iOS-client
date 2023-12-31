//
//  BDPLog.h
//  ECOInfra
//
//  Created by Meng on 2021/3/30.
//

#import <Foundation/Foundation.h>
#import "BDPMacros.h"

#ifndef Infra_BDPLog_h
#define Infra_BDPLog_h

extern BOOL BDPDebugLogEnable;   // 允许Release下临时打开Debug日志

/*-------------------- BDPLogLevel ------------------*/
typedef NS_ENUM(NSUInteger, BDPLogLevel) {
    BDPLogLevelDebug    = 1,    // Detailed information on the flow through the system.
    BDPLogLevelInfo     = 2,    // Interesting runtime events (startup/shutdown), should be conservative and keep to a minimum.
    BDPLogLevelWarn     = 3,    // Other runtime situations that are undesirable or unexpected, but not necessarily "wrong".
    BDPLogLevelError    = 4,    // Other runtime errors or unexpected conditions.
};

/*------------------ Inteface Define ----------------*/
/* 提供宏定义的参数类型代码提示 */
void BDPLogDebug(NSString * _Nullable _format, ...);
void BDPLogInfo(NSString * _Nullable _format, ...);
void BDPLogWarn(NSString * _Nullable _format, ...);
void BDPLogError(NSString * _Nullable _format, ...);
void BDPLogTagDebug(NSString * _Nullable _tag, NSString * _Nullable _format, ...);
void BDPLogTagInfo(NSString * _Nullable _tag, NSString * _Nullable _format, ...);
void BDPLogTagWarn(NSString * _Nullable _tag, NSString * _Nullable _format, ...);
void BDPLogTagError(NSString * _Nullable _tag, NSString * _Nullable _format, ...);

/*----------------------- Level ---------------------*/

/// Debug
#define BDPLogDebug(_format, ...)   if (BDPDebugLogEnable) { BDPLog(BDPLogLevelDebug, nil, nil, _format, ##__VA_ARGS__) }

/// Info
#define BDPLogInfo(_format, ...)    BDPLog(BDPLogLevelInfo, nil, nil, _format, ##__VA_ARGS__)

/// Warn
#define BDPLogWarn(_format, ...)    BDPLog(BDPLogLevelWarn, nil, nil, _format, ##__VA_ARGS__)

/// Error
#define BDPLogError(_format, ...)   BDPLog(BDPLogLevelError, nil, nil, _format, ##__VA_ARGS__)

/*----------------------- TAG ---------------------*/

/// Tag Debug
#define BDPLogTagDebug(_tag, _format, ...)  if (BDPDebugLogEnable) { BDPLog(BDPLogLevelDebug, _tag, nil, _format, ##__VA_ARGS__) }

/// Tag Info
#define BDPLogTagInfo(_tag, _format, ...)   BDPLog(BDPLogLevelInfo, _tag, nil, _format, ##__VA_ARGS__)

/// Tag Warn
#define BDPLogTagWarn(_tag, _format, ...)   BDPLog(BDPLogLevelWarn, _tag, nil, _format, ##__VA_ARGS__)

/// Tag Error
#define BDPLogTagError(_tag, _format, ...)  BDPLog(BDPLogLevelError, _tag, nil, _format, ##__VA_ARGS__)
/*----------------------- TRACING ---------------------*/

/// Tag Debug
#define BDPLogTracingDebug(_tag, _tracing, _format, ...)  if (BDPDebugLogEnable) { BDPLog(BDPLogLevelDebug, _tag, _tracing, _format, ##__VA_ARGS__) }

/// Tag Info
#define BDPLogTracingInfo(_tag, _tracing, _format, ...)   BDPLog(BDPLogLevelInfo, _tag, _tracing, _format, ##__VA_ARGS__)

/// Tag Warn
#define BDPLogTracingWarn(_tag, _tracing, _format, ...)   BDPLog(BDPLogLevelWarn, _tag, _tracing, _format, ##__VA_ARGS__)

/// Tag Error
#define BDPLogTracingError(_tag, _tracing, _format, ...)  BDPLog(BDPLogLevelError, _tag, _tracing, _format, ##__VA_ARGS__)


/*---------------------- Assert --------------------*/
#define BDPAssertWithLog(_format, ...)   do { BDPLog(BDPLogLevelError, nil, nil, _format, ##__VA_ARGS__); NSAssert(NO, _format, ##__VA_ARGS__); } while(0);

/*---------------------- Private --------------------*/
/// Level Tag
#ifdef __IPHONE_13_0
#define __BDP_FILE_NAME__ __FILE_NAME__
#else
#define __BDP_FILE_NAME__ __FILE__
#endif

#define BDPLog(_level, _tag, _tracing, _format, ...) _ECOInfraFoundationLog(_level, _tag, _tracing, __BDP_FILE_NAME__, __FUNCTION__, __LINE__, [NSString stringWithFormat:_format, ##__VA_ARGS__, nil]);

FOUNDATION_EXPORT NSString* BDPLogLevelString(BDPLogLevel level);

FOUNDATION_EXPORT void _ECOInfraFoundationLog(BDPLogLevel level, NSString * tag, NSString *tracing, const char* filename, const char* func_name, int line, NSString *content);
#endif /* Infra_BDPLog_h */
