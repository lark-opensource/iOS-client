// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_INSTANCE_TRACE_PLUGIN_DARWIN_H__
#define LYNX_DEVTOOL_INSTANCE_TRACE_PLUGIN_DARWIN_H__

#if LYNX_ENABLE_TRACING

#include "base/trace_event/trace_controller.h"
#include "tracing/instance_counter_trace_impl.h"

namespace lynx {
namespace base {
namespace tracing {

class InstanceTracePluginDarwin : public TracePlugin {
 public:
  InstanceTracePluginDarwin();
  virtual ~InstanceTracePluginDarwin();
  virtual void DispatchBegin() override;
  virtual void DispatchEnd() override;

 private:
  static std::unique_ptr<InstanceCounterTrace::Impl> empty_counter_trace_;
  std::unique_ptr<InstanceCounterTrace::Impl> counter_trace_impl;
};

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING
#endif  // LYNX_DEVTOOL_INSTANCE_TRACE_PLUGIN_DARWIN_H__
