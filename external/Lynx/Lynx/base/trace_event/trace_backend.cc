// Copyright 2020 The Lynx Authors. All rights reserved.

#include "base/trace_event/trace_backend.h"

#include "base/compiler_specific.h"
#include "base/log/logging.h"
#include "base/threading/task_runner_manufactor.h"
#include "base/trace_event/trace_event.h"
#include "config/config.h"

#if LYNX_ENABLE_TRACING
extern "C" void SetTraceLoggerImpl(
    lynx::base::tracing::TraceBackend::Impl *impl) {
  lynx::base::tracing::TraceBackend::SetImpl(impl);
}
#endif

namespace lynx {
namespace base {
namespace tracing {

TraceBackend::Impl *TraceBackend::impl_;

}  // namespace tracing
}  // namespace base
}  // namespace lynx

#if LYNX_ENABLE_TRACING

#if defined(ENABLE_INSTRUMENT) && ENABLE_INSTRUMENT

extern "C" {
__attribute__((no_instrument_function)) void __cyg_profile_func_enter(
    void *this_fn, void *call_site) {
  char name[16];
  snprintf(name, 16, "%p", this_fn);
  TRACE_EVENT_BEGIN("lynx", name);
}

__attribute__((no_instrument_function)) void __cyg_profile_func_exit(
    void *this_fn, void *call_site) {
  TRACE_EVENT_END("lynx");
}
}

#endif  // ENABLE_INSTRUMENT

#endif  // LYNX_ENABLE_TRACING
