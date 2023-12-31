// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TRACE_EVENT_INSTANCE_COUNTER_TRACE_H_
#define LYNX_BASE_TRACE_EVENT_INSTANCE_COUNTER_TRACE_H_

#if LYNX_ENABLE_TRACING
#include <stdint.h>

#include "base/base_export.h"
#include "base/compiler_specific.h"

namespace lynx {
namespace base {
namespace tracing {

class InstanceCounterTrace {
 public:
  class Impl {
   public:
    Impl() = default;

    virtual ~Impl() = default;

    virtual void JsHeapMemoryUsedTraceImpl(const uint64_t jsHeapMemory){};
  };

  InstanceCounterTrace() = delete;

  ~InstanceCounterTrace() = delete;

  BASE_EXPORT_FOR_DEVTOOL static void SetImpl(Impl* impl) { impl_ = impl; }

  static void JsHeapMemoryUsedTrace(const uint64_t jsHeapMemory) {
    if (LIKELY(!impl_)) {
      return;
    }
    impl_->JsHeapMemoryUsedTraceImpl(jsHeapMemory);
  }

 private:
  BASE_EXPORT_FOR_DEVTOOL static Impl* impl_;
};

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif

#endif  // LYNX_BASE_TRACE_EVENT_INSTANCE_COUNTER_TRACE_H_
