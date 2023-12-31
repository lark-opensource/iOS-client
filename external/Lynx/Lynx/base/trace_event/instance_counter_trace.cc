// Copyright 2021 The Lynx Authors. All rights reserved.

#include "base/trace_event/instance_counter_trace.h"

#if LYNX_ENABLE_TRACING
namespace lynx {
namespace base {
namespace tracing {

InstanceCounterTrace::Impl* InstanceCounterTrace::impl_;

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif
