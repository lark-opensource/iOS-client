// Copyright 2022 The Lynx Authors. All rights reserved.

#include "base/Darwin/logging_darwin.h"
#include "base/log/alog_wrapper.h"
#include "base/lynx_env.h"

#if __has_include("BDALog/BDAgileLog.h")
#include "BDALog/BDAgileLog.h"
#define BD_ALOG_ENABLED 1
#endif

namespace lynx {
namespace base {
namespace logging {
namespace {

#ifdef BD_ALOG_ENABLED
[[maybe_unused]] void BDAlogWrite(unsigned int level, const char *tag, const char *format) {
  if (format == nullptr) {
    return;
  }
  BDLoggerInfo info;

  info.filename = "";
  info.tag = tag;
  info.line = -1;
  info.func_name = "";
  struct timeval tv;
  gettimeofday(&tv, NULL);
  info.timeval = tv;
  info.level = static_cast<kBDALogLevel>(level);

  _alog_write_macro(&info, format);
}
#endif  // BD_ALOG_ENABLED

alog_write_func_ptr GetAlogWriteFuncAddr() {
#ifdef BD_ALOG_ENABLED
  return alog_write_func_ptr(&BDAlogWrite);
#else
  return nullptr;
#endif
}

bool InitAlogNative() {
  static bool s_has_inited_alog = false;
  if (!s_has_inited_alog) {
    alog_write_func_ptr alog_write_func = GetAlogWriteFuncAddr();
    if (lynx::base::InitAlog(alog_write_func)) {
      s_has_inited_alog = true;
    }
  }
  return s_has_inited_alog;
}

void PrintLogMessageByAlog(int level, const char *message) {
  if (InitAlogNative()) {
    if (level < ALOG_LEVEL_VERBOSE || level > ALOG_LEVEL_FATAL) {
      return;
    }
    static constexpr const char *kTag = "lynx";
    // use ALog to print native logMessage
    ALogWrite(level, kTag, message);
  } else {
    // use system log to print native logMessage
    NSLog(@"%s/lynx: %@", kLynxLogLevels[level], [NSString stringWithUTF8String:message]);
  }
}

}  // namespace

void SetLynxLogMinLevel(int min_level) { SetMinLogLevel(min_level); }

void InternalLogNative(int level, const char *message) { PrintLogMessageByAlog(level, message); }

// Implementation of the Log function in the <logging.h> file.
void Log(LogMessage *msg) {
  // 1. all logs are logged to the delegate and ALog for debug.
  if (base::LynxEnv::GetInstance().IsDevtoolEnabled()) {
    PrintLogMessageByAlog(msg->severity(), msg->stream().str().c_str());
#ifndef LYNX_UNIT_TEST
    PrintLogMessageByLogDelegate(msg);
#endif
    return;
  }
  // 2. only native logs output to ALog for release.
  if (msg->source() == logging::LOG_SOURCE_NATIVE) {
    PrintLogMessageByAlog(msg->severity(), msg->stream().str().c_str());
    return;
  }
  // 3. console.alog output to Alog and console.report output to delegate for release.
  if (msg->source() == logging::LOG_SOURCE_JS_EXT) {
    if (msg->severity() == logging::LOG_INFO) {
      // console.alog output to Alog
      ALogWriteE("lynx", msg->stream().str().c_str());
    } else {
#ifndef LYNX_UNIT_TEST
      // console.report output to delegate
      PrintLogMessageByLogDelegate(msg);
#endif
    }
  }
}

}  // namespace logging
}  // namespace base
}  // namespace lynx
