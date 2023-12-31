
// Copyright 2020 The Lynx Authors. All rights reserved.

#include "base/debug/backtrace.h"

#include <utility>

namespace {

struct BacktraceState {
  void** current;
  void** end;
};

}  // namespace

namespace lynx {
namespace base {
namespace debug {

BacktraceDelegate* g_backtrace_delegate = nullptr;
void SetBacktraceDelegate(BacktraceDelegate* delegate) {
  if (g_backtrace_delegate) {
    delete g_backtrace_delegate;
  }
  g_backtrace_delegate = delegate;
}
// IOS
std::string GetBacktraceInfo(std::string& error_message) {
  if (g_backtrace_delegate) {
    std::string traceInfo = g_backtrace_delegate->TraceLog(error_message, 2);
    if (!traceInfo.empty()) {
      return traceInfo;
    }
  }
  // in debug
#if OS_IOS
  error_message.append("\n\n");
  constexpr int max = 30;
  void* buffer[max];
  int stack_num = backtrace(buffer, max);
  char** stacktrace = backtrace_symbols(buffer, stack_num);
  if (stacktrace == nullptr) {
    return "";
  }
  // begin from 2 can throw backtrace for AddBackTrace and LynxException
  for (int i = 2; i < stack_num; ++i) {
    // make order begin with 0
    int order = i - 2;
    int offset = order >= 10 ? 3 : 2;
    error_message.append(std::to_string(order))
        .append(stacktrace[i] + offset)
        .append("\n");
  }
  free(stacktrace);
#endif
  return error_message;
}

size_t CaptureBacktrace(void** buffer, size_t max) {
  BacktraceState state = {buffer, buffer + max};
#if OS_ANDROID && JS_ENGINE_TYPE != 1 && JS_ENGINE_TYPE != 0
  auto callback = [](struct _Unwind_Context* context, void* arg) {
    BacktraceState* state = static_cast<BacktraceState*>(arg);
    uintptr_t pc = _Unwind_GetIP(context);
    if (pc) {
      if (state->current == state->end) {
        return _URC_END_OF_STACK;
      } else {
        *state->current++ = reinterpret_cast<void*>(pc);
      }
    }
    return _URC_NO_REASON;
  };
  _Unwind_Backtrace(callback, &state);
#endif
  return state.current - buffer;
}

void DumpBacktrace(void** buffer, size_t count) {
  for (size_t idx = 0; idx < count; ++idx) {
    const void* addr = buffer[idx];
    const char* symbol = "";

    Dl_info info;
    if (dladdr(addr, &info) && info.dli_sname) {
      symbol = info.dli_sname;
    }

    DLOGW("#" << idx << ":" << symbol);
  }
}
void PrintCurrentBacktrace() {
  const size_t max = 30;
  void* buffer[max];

  size_t size = CaptureBacktrace(buffer, max);

  DumpBacktrace(buffer, size);
}
void PrintBacktrace(void** buffer, size_t count) {
  DumpBacktrace(buffer, count);
}
}  // namespace debug
}  // namespace base
}  // namespace lynx
