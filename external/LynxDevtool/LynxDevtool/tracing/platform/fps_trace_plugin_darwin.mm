// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tracing/platform/fps_trace_plugin_darwin.h"
#import "LynxFPSTrace.h"

#if LYNX_ENABLE_TRACING
namespace lynx {
namespace base {
namespace tracing {

void FPSTracePluginDarwin::DispatchBegin() { [[LynxFPSTrace shareInstance] startFPSTrace]; }

void FPSTracePluginDarwin::DispatchEnd() { [[LynxFPSTrace shareInstance] stopFPSTrace]; }

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif  // LYNX_ENABLE_TRACING
