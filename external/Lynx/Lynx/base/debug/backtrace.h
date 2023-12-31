// Copyright 2017 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_DEBUG_BACKTRACE_H_
#define LYNX_BASE_DEBUG_BACKTRACE_H_

#include <dlfcn.h>
#include <unwind.h>

#include <iomanip>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>

#include "base/compiler_specific.h"
#include "base/log/logging.h"
#if OS_IOS
#include "execinfo.h"
#endif

namespace lynx {
namespace base {
namespace debug {

class BacktraceDelegate {
 public:
  virtual ~BacktraceDelegate() {}
  virtual std::string TraceLog(std::string& msg, int skipDepth) = 0;
};

void SetBacktraceDelegate(BacktraceDelegate* delegate);

// IOS
std::string GetBacktraceInfo(std::string& error_message);

size_t CaptureBacktrace(void** buffer, size_t max);

void DumpBacktrace(void** buffer, size_t count);

void PrintCurrentBacktrace();
void PrintBacktrace(void** buffer, size_t count);

}  // namespace debug
}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_DEBUG_BACKTRACE_H_
