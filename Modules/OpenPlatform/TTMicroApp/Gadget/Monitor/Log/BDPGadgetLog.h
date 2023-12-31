//
//  BDPGadgetLog.h
//  TTMicroApp
//
//  Created by xingjinhao on 2021/12/16.
//

#import <Foundation/Foundation.h>
#import <ECOInfra/BDPLog.h>

#define gadgetTag @"[Gadget]"

/* 提供宏定义的参数类型代码提示 */
void BDPGadgetLogDebug(NSString * _Nullable _format, ...);
void BDPGadgetLogInfo(NSString * _Nullable _format, ...);
void BDPGadgetLogWarn(NSString * _Nullable _format, ...);
void BDPGadgetLogError(NSString * _Nullable _format, ...);
void BDPGadgetLogTagDebug(NSString * _Nullable _tag, NSString * _Nullable _format, ...);
void BDGadgetPLogTagInfo(NSString * _Nullable _tag, NSString * _Nullable _format, ...);
void BDPGadgetLogTagWarn(NSString * _Nullable _tag, NSString * _Nullable _format, ...);
void BDPGadgetLogTagError(NSString * _Nullable _tag, NSString * _Nullable _format, ...);
void BDPGadgetDebugNSLog(NSString * _Nullable _format, ...);

/// Debug
#define BDPGadgetLogDebug(_format, ...)   if (BDPDebugLogEnable) { BDPLog(BDPLogLevelDebug, gadgetTag, nil, _format, ##__VA_ARGS__) }

/// Info
#define BDPGadgetLogInfo(_format, ...)    BDPLog(BDPLogLevelInfo, gadgetTag, nil, _format, ##__VA_ARGS__)

/// Warn
#define BDPGadgetLogWarn(_format, ...)    BDPLog(BDPLogLevelWarn, gadgetTag, nil, _format, ##__VA_ARGS__)

/// Error
#define BDPGadgetLogError(_format, ...)   BDPLog(BDPLogLevelError, gadgetTag, nil, _format, ##__VA_ARGS__)

/// Tag Debug
#define BDPGadgetLogTagDebug(_tag, _format, ...)  if (BDPDebugLogEnable) { BDPLog(BDPLogLevelDebug, [gadgetTag stringByAppendingString: _tag], nil, _format, ##__VA_ARGS__) }

/// Tag Info
#define BDPGadgetLogTagInfo(_tag, _format, ...)   BDPLog(BDPLogLevelInfo, [gadgetTag stringByAppendingString: _tag], nil, _format, ##__VA_ARGS__)

/// Tag Warn
#define BDPGadgetLogTagWarn(_tag, _format, ...)   BDPLog(BDPLogLevelWarn, [gadgetTag stringByAppendingString: _tag], nil, _format, ##__VA_ARGS__)

/// Tag Error
#define BDPGadgetLogTagError(_tag, _format, ...)  BDPLog(BDPLogLevelError, [gadgetTag stringByAppendingString: _tag], nil, _format, ##__VA_ARGS__)

/// Local
#if DEBUG
#define BDPGadgetDebugNSLog(_format, ... ) NSLog([gadgetTag stringByAppendingString: _format], ##__VA_ARGS__)
#else
#define BDPGadgetDebugNSLog(_format, ... )
#endif
