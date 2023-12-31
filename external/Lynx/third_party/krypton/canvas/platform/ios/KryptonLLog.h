//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef CANVAS_PLATFORM_IOS_KRYPTONLLOG_H_
#define CANVAS_PLATFORM_IOS_KRYPTONLLOG_H_

#import "LynxLog.h"

#define KRYPTON_LLog(...) _KryptonLogInternal(LynxLogLevelInfo, __VA_ARGS__)
#define KRYPTON_LLogInfo(...) _KryptonLogInternal(LynxLogLevelInfo, __VA_ARGS__)
#define KRYPTON_LLogWarn(...) _KryptonLogInternal(LynxLogLevelWarn, __VA_ARGS__)
#define KRYPTON_LLogError(...) _KryptonLogInternal(LynxLogLevelError, __VA_ARGS__)
#define KRYPTON_LLogFatal(...) _KryptonLogInternal(LynxLogLevelInfoFatal, __VA_ARGS__)
#define KRYPTON_LLogReport(...) _KryptonLogInternal(LynxLogLevelInfoReport, __VA_ARGS__)

void _KryptonLogInternal(LynxLogLevel, NSString *, ...);
#endif  // CANVAS_PLATFORM_IOS_KRYPTONLLOG_H_
