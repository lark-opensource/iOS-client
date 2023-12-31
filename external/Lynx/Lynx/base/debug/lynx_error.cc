// Copyright 2023 The Lynx Authors. All rights reserved.
#include "base/debug/lynx_error.h"

#include "base/compiler_specific.h"
#include "base/lynx_env.h"
#include "base/string/string_utils.h"

#if !defined(OS_WIN)
#include "base/debug/backtrace.h"
#endif

#if defined(OS_IOS) && defined(__i386__)
#include "base/threading/thread_local.h"
#endif

#if defined(BUILD_LEPUS) || defined(OS_WIN)
#include <cstdarg>
#endif

namespace lynx {

namespace base {

namespace {

std::string AddBackTrace(std::string& error_message) {
#if OS_IOS
  return lynx::base::debug::GetBacktraceInfo(error_message);
#elif OS_ANDROID
  // This is a workaround to avoid crash online,
  // but offline we still need this information, even if it may crash.
  // The root cause is the compatibility of the unwind library(llvm, gnu).
  // TODO(zhangfacheng): Remove this once there is a radical solution.
  // TODO(zhengsenyao):  Decoupling to LynxEnv.
  if (!lynx::base::LynxEnv::GetInstance().IsDevtoolEnabled()) {
    return error_message;
  }
  error_message.append("\n\n");
  constexpr int max = 30;
  void* buffer[max];
  ALLOW_UNUSED_LOCAL(buffer);
  size_t size = base::debug::CaptureBacktrace(buffer, max);
  int order = 0;
  for (size_t i = 0; i < size; ++i) {
    Dl_info info;
    // skip first backtrace can capture for LynxException
    if (dladdr(buffer[i], &info) && info.dli_sname && order++) {
      error_message.append(std::to_string(order - 2)).append(" ");
      if (info.dli_fname) {
        int pos = 0;
        int curr = 0;
        while (info.dli_fname[curr] != '\0') {
          if (info.dli_fname[curr++] == '/') {
            pos = curr;
          }
        }
        error_message.append(info.dli_fname + pos).append(" ");
      }

      error_message.append(info.dli_sname).append("\n");
    }
  }
  return error_message;
#else
  return error_message;
#endif
}

}  // namespace

LynxError::LynxError(int error_code, const char* format, ...)
    : error_code_(error_code) {
  va_list args;
  va_start(args, format);
  error_message_ = FormatStringWithVaList(format, args);
  va_end(args);
  error_message_ = AddBackTrace(error_message_);
  LOGI("LynxError occurs error_code:" << error_code
                                      << " error_message:" << error_message_);
}

ErrorStorage& ErrorStorage::GetInstance() {
#if defined(OS_IOS) && defined(__i386__)
  // constructor is private, so must pass here
  static ThreadLocal<ErrorStorage> instance([] { return new ErrorStorage; });
#else
  static thread_local ErrorStorage instance;
#endif
  return instance;
}

}  // namespace base
}  // namespace lynx
