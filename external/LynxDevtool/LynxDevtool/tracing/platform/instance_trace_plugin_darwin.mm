// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tracing/platform/instance_trace_plugin_darwin.h"

#if LYNX_ENABLE_TRACING
namespace lynx {
namespace base {
namespace tracing {

std::unique_ptr<InstanceCounterTrace::Impl> InstanceTracePluginDarwin::empty_counter_trace_ =
    std::make_unique<InstanceCounterTrace::Impl>();

InstanceTracePluginDarwin::InstanceTracePluginDarwin()
    : counter_trace_impl(std::make_unique<InstanceCounterTraceImpl>()) {}

InstanceTracePluginDarwin::~InstanceTracePluginDarwin() { counter_trace_impl.reset(nullptr); }

void InstanceTracePluginDarwin::DispatchBegin() {
  InstanceCounterTrace::SetImpl(counter_trace_impl.get());
}

void InstanceTracePluginDarwin::DispatchEnd() {
  InstanceCounterTrace::SetImpl(empty_counter_trace_.get());
}

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING
