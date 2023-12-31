// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_TRACING_INSTANCE_COUNTER_TRACE_IMPL_H_
#define LYNX_BASE_TRACING_INSTANCE_COUNTER_TRACE_IMPL_H_

#if LYNX_ENABLE_TRACING
#include <stdint.h>

#include "base/trace_event/instance_counter_trace.h"
#include "tasm/react/element.h"
#include "third_party/fml/thread.h"

namespace lynx {
namespace base {
namespace tracing {

class InstanceCounterTraceImpl : public InstanceCounterTrace::Impl {
 public:
  InstanceCounterTraceImpl();

  virtual ~InstanceCounterTraceImpl() = default;

  virtual void JsHeapMemoryUsedTraceImpl(const uint64_t jsHeapMemory) override;

  static void IncrementNodeCounter(tasm::Element* element);

  static void DecrementNodeCounter(tasm::Element* element);

  static void InitNodeCounter();

 private:
  fml::Thread thread_;
  static uint64_t node_count_;
};

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING
#endif  // LYNX_BASE_TRACING_INSTANCE_COUNTER_TRACE_IMPL_H_
