// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_FRAMEVIEW_TRACE_PLUGIN_DARWIN_H__
#define LYNX_DEVTOOL_FRAMEVIEW_TRACE_PLUGIN_DARWIN_H__

#if LYNX_ENABLE_TRACING

#include "base/trace_event/trace_controller.h"

namespace lynx {
namespace base {
namespace tracing {

class FrameViewTracePluginDarwin : public TracePlugin {
 public:
  FrameViewTracePluginDarwin() = default;
  virtual ~FrameViewTracePluginDarwin() = default;
  virtual void DispatchBegin() override;
  virtual void DispatchEnd() override;
};

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING
#endif  // LYNX_DEVTOOL_FRAMEVIEW_TRACE_PLUGIN_DARWIN_H__
