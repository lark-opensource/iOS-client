//
//  OPMacros.h
//  LarkOPInterface
//
//  Created by yinyuan on 2020/5/21.
//

#ifndef OPMacros_h
#define OPMacros_h

#import "AssertionConfigForTest.h"

typedef NS_ENUM(NSUInteger, OPLogLevel) {
    OPLogLevelDebug = 1,
    OPLogLevelInfo  = 2,
    OPLogLevelWarn  = 3,
    OPLogLevelError = 4,
    OPLogLevelFatal = 5
};

#ifdef __IPHONE_13_0
#define __OP_FILE_NAME__ __FILE_NAME__
#else
#define __OP_FILE_NAME__ __FILE__
#endif

#define OPLog(level, _format, ...) _OPLog(level, nil, __OP_FILE_NAME__, __FUNCTION__, __LINE__, [NSString stringWithFormat:_format, ##__VA_ARGS__, nil]);

#define OPLogInfo(_format, ...) _OPLog(OPLogLevelInfo, nil, __OP_FILE_NAME__, __FUNCTION__, __LINE__, [NSString stringWithFormat:_format, ##__VA_ARGS__, nil]);
#define OPLogWarn(_format, ...) _OPLog(OPLogLevelWarn, nil, __OP_FILE_NAME__, __FUNCTION__, __LINE__, [NSString stringWithFormat:_format, ##__VA_ARGS__, nil]);
#define OPLogError(_format, ...) _OPLog(OPLogLevelError, nil, __OP_FILE_NAME__, __FUNCTION__, __LINE__, [NSString stringWithFormat:_format, ##__VA_ARGS__, nil]);

FOUNDATION_EXPORT void _OPLog(OPLogLevel level, NSString* tag, const char* _Nullable filename, const char* _Nullable func_name, int line, NSString * _Nullable content); // not for direct use

FOUNDATION_EXPORT id _OPBoxValue(_Nullable id defaulValue, const char * _Nullable type, ...);   // not for direct use

#define OPAssert(_format, ...)   do { if([AssertionConfigForTest isEnable]) { NSAssert(_format, ##__VA_ARGS__); } } while(0);

#endif /* OPMacros_h */
