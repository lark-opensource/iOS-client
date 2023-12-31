// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxLog.h"
#import "LynxEnv.h"
#import "LynxTraceEvent.h"
#include "base/Darwin/logging_darwin.h"
#include "base/debug/lynx_assert.h"

#define LOCKED(...)             \
  @synchronized(gDelegateDic) { \
    __VA_ARGS__;                \
  }

@implementation LynxLogObserver

- (instancetype)initWithLogFunction:(LynxLogFunction)logFunction
                        minLogLevel:(LynxLogLevel)minLogLevel {
  if (self = [super init]) {
    self.logFunction = logFunction;
    self.minLogLevel = minLogLevel;
    self.acceptSource = NSIntegerMax;
    self.acceptRuntimeId = -1;
    self.shouldFormatMessage = true;
  }
  return self;
}

@end

static NSInteger gDefaultDelegateId = -1;
static NSInteger gCurrentId = 0;
static NSInteger gDefaultRuntimeId = -1;
static NSMutableDictionary *gDelegateDic = [[NSMutableDictionary alloc] init];
static LynxLogLevel gAlogMinLevel = LynxLogLevelInfo;
static bool gIsJSLogsFromExternalChannelsOpen = false;
static LynxLogDelegate *gDebugLoggingDelegate;

void SetDebugLoggingDelegate(LynxLogDelegate *delegate) { gDebugLoggingDelegate = delegate; }

void PrintLogMessageForDebug(LynxLogLevel level, NSString *message,
                             int64_t runtimeId = gDefaultRuntimeId) {
  if (gDebugLoggingDelegate == nullptr || level < gDebugLoggingDelegate.minLogLevel) {
    return;
  }
  LynxLogFunction logFunction = gDebugLoggingDelegate.logFunction;
  if (logFunction == nil) {
    return;
  }
  NSString *msgWithRid = message;
  if (runtimeId != gDefaultRuntimeId) {
    msgWithRid = [NSString stringWithFormat:@"argRuntimeId:%lld&%@", runtimeId, message];
  }
  logFunction(level, msgWithRid);
}

// turn off by default
// JS logs form external channels: recorded by business developers (mostly front-end)
void SetJSLogsFromExternalChannels(bool isOpen) { gIsJSLogsFromExternalChannelsOpen = isOpen; }

namespace lynx {
namespace base {
namespace logging {
namespace {
NSArray<LynxLogDelegate *> *GetLoggingDelegates(void) { LOCKED(return [gDelegateDic allValues]); }
}  // namespace

bool IsExternalChannel(lynx::base::logging::LogChannel channelType) {
  return gIsJSLogsFromExternalChannelsOpen &&
         channelType == lynx::base::logging::LOG_CHANNEL_LYNX_EXTERNAL;
}

// Implementation of this function in the <base/Darwin/logging_darwin.h> file.
void PrintLogMessageByLogDelegate(LogMessage *msg) {
  LynxLogLevel level = (LynxLogLevel)msg->severity();
  NSString *message = gDebugLoggingDelegate.shouldFormatMessage
                          ? [NSString stringWithUTF8String:msg->stream().str().c_str()]
                          : [[NSString stringWithUTF8String:msg->stream().str().c_str()]
                                substringFromIndex:msg->messageStart()];
  // print native's log to hybrid devtool for debug
  PrintLogMessageForDebug(level, message, msg->runtimeId());

  NSArray<LynxLogDelegate *> *delegates = GetLoggingDelegates();
  for (LynxLogDelegate *delegate in delegates) {
    LynxLogFunction logFunction = delegate.logFunction;
    if (logFunction == nil || level < delegate.minLogLevel ||
        (delegate.acceptRuntimeId >= 0 && delegate.acceptRuntimeId != msg->runtimeId())) {
      continue;
    }
    message = delegate.shouldFormatMessage
                  ? [NSString stringWithUTF8String:msg->stream().str().c_str()]
                  : [[NSString stringWithUTF8String:msg->stream().str().c_str()]
                        substringFromIndex:msg->messageStart()];
    if (message == nil) {
      return;
    }
    // only upload external JS logs and console.report to logging delegate
    switch (msg->source()) {
      case LOG_SOURCE_JS:
        if (IsExternalChannel(msg->ChannelType()) && (delegate.acceptSource & LynxLogSourceJS)) {
          logFunction(level, message);
        }
        break;
      case LOG_SOURCE_JS_EXT:
        logFunction(level, message);
        break;
      default:
        break;
    }
  }
}

}  // namespace logging
}  // namespace base
}  // namespace lynx

NSInteger AddLoggingDelegate(LynxLogDelegate *delegate) {
  NSInteger delegateId = ++gCurrentId;
  LOCKED([gDelegateDic setObject:delegate forKey:@(delegateId)]);
  return delegateId;
}

LynxLogDelegate *GetLoggingDelegate(NSInteger delegateId) {
  LOCKED(return [gDelegateDic objectForKey:@(delegateId)]);
}

void RemoveLoggingDelegate(NSInteger delegateId) {
  LOCKED([gDelegateDic removeObjectForKey:@(delegateId)]);
}

void SetMinimumLoggingLevel(LynxLogLevel minLogLevel) {
  [[maybe_unused]] static constexpr const char *kLogLevelName[] = {
      "LynxLogLevelVerbose", "LynxLogLevelDebug", "LynxLogLevelInfo",
      "LynxLogLevelWarning", "LynxLogLevelError", "LynxLogLevelFatal"};
  if (gAlogMinLevel < minLogLevel) {
    gAlogMinLevel = minLogLevel;
    lynx::base::logging::SetLynxLogMinLevel(static_cast<int>(minLogLevel));
    NSLog(@"W/lynx: Reset minimum log level as %s", kLogLevelName[gAlogMinLevel]);
  } else {
    NSLog(@"W/lynx: Please set a log level higher than %s to filter lynx logs!",
          kLogLevelName[gAlogMinLevel]);
  }
}

LynxLogLevel GetMinimumLoggingLevel(void) { return gAlogMinLevel; }

NSInteger LynxAddLogObserver(LynxLogFunction logFunction, LynxLogLevel minLogLevel) {
  LynxLogDelegate *delegate = [[LynxLogDelegate alloc] initWithLogFunction:logFunction
                                                               minLogLevel:minLogLevel];
  return AddLoggingDelegate(delegate);
}

NSInteger LynxAddLogObserverByModel(LynxLogObserver *observer) {
  return AddLoggingDelegate(observer);
}

LynxLogObserver *LynxGetLogObserver(NSInteger observerId) { return GetLoggingDelegate(observerId); }

void LynxRemoveLogObserver(NSInteger observerId) { RemoveLoggingDelegate(observerId); }

NSArray<LynxLogObserver *> *LynxGetLogObservers() { LOCKED(return [gDelegateDic allValues]); }

void LynxSetLogFunction(LynxLogFunction logFunction) {
  LynxLogDelegate *delegate = [[LynxLogDelegate alloc] initWithLogFunction:logFunction
                                                               minLogLevel:LynxLogLevelInfo];
  gDefaultDelegateId = AddLoggingDelegate(delegate);
}

LynxLogFunction LynxGetLogFunction(void) {
  LynxLogDelegate *delegate = GetLoggingDelegate(gDefaultDelegateId);
  if (!delegate) {
    return LynxDefaultLogFunction;
  }
  return delegate.logFunction;
}

void LynxSetMinLogLevel(LynxLogLevel minLogLevel) {
  LynxLogDelegate *delegate = GetLoggingDelegate(gDefaultDelegateId);
  if (delegate) {
    delegate.minLogLevel = minLogLevel;
  }
  SetMinimumLoggingLevel(minLogLevel);
}

LynxLogLevel LynxGetMinLogLevel(void) {
  LynxLogDelegate *delegate = GetLoggingDelegate(gDefaultDelegateId);
  if (delegate) {
    return delegate.minLogLevel;
  }
  return LynxLogLevelInfo;
}

LynxLogFunction LynxDefaultLogFunction = ^(LynxLogLevel level, NSString *message) {
  NSLog(@"%s/lynx: %@", lynx::base::logging::kLynxLogLevels[level], message);
};

void _LynxLogInternal(LynxLogLevel level, NSString *format, ...) {
  LYNX_TRACE_SECTION(LYNX_TRACE_CATEGORY_WRAPPER, @"_LynxLogInternal")
  va_list args;
  va_start(args, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  // print log to Alog
  if (level >= gAlogMinLevel) {
    lynx::base::logging::InternalLogNative((int)level, [message UTF8String]);
  }

  // print log to hybrid devtool for debug
  PrintLogMessageForDebug(level, message);

  LYNX_TRACE_END_SECTION(LYNX_TRACE_CATEGORY_WRAPPER)
}

void _LynxErrorInfo(NSInteger errorCode, NSString *format, ...) {
  va_list args;
  va_start(args, format);
  NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
  va_end(args);
  LynxInfo(static_cast<int>(errorCode), message.UTF8String);
}

void _LynxErrorWarning(bool expression, NSInteger errorCode, NSString *format, ...) {
  if (!expression) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    LynxWarning(expression, static_cast<int>(errorCode), message.UTF8String);
  }
}

void _LynxErrorFatal(bool expression, NSInteger errorCode, NSString *format, ...) {
  if (!expression) {
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    LynxFatal(expression, static_cast<int>(errorCode), message.UTF8String);
  }
}
