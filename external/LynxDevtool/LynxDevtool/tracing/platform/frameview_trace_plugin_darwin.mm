// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tracing/platform/frameview_trace_plugin_darwin.h"
#import "LynxFrameViewTrace.h"

#if LYNX_ENABLE_TRACING
namespace lynx {
namespace base {
namespace tracing {

void FrameViewTracePluginDarwin::DispatchBegin() {
  [[LynxFrameViewTrace shareInstance] startFrameViewTrace];
}

void FrameViewTracePluginDarwin::DispatchEnd() {
  [[LynxFrameViewTrace shareInstance] stopFrameViewTrace];
}

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING
