// Copyright 2017 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_BASE_BEBUG_BACKTRACE_H_
#define VMSDK_BASE_BEBUG_BACKTRACE_H_

#include <dlfcn.h>
#include <unwind.h>

#include <iomanip>
#include <iostream>
#include <sstream>

#include "basic/compiler_specific.h"
#include "basic/log/logging.h"
#if OS_IOS
#include "execinfo.h"
#endif

namespace {

struct BacktraceState {
  void **current;
  void **end;
};

}  // namespace
namespace vmsdk {
namespace general {
namespace debug {

class BacktraceDelegate {
 public:
  virtual ~BacktraceDelegate() {}
  virtual std::string TraceLog(std::string &msg, int skipDepth) = 0;
};

void SetBacktraceDelegate(std::unique_ptr<BacktraceDelegate> delegate);

// IOS
std::string GetBacktraceInfo(std::string &error_message);

size_t CaptureBacktrace(void **buffer, size_t max);

void DumpBacktrace(void **buffer, size_t count);

void PrintCurrentBacktrace();
void PrintBacktrace(void **buffer, size_t count);

}  // namespace debug
}  // namespace general
}  // namespace vmsdk

#endif  // ANDROID_BACKTRACE_H
