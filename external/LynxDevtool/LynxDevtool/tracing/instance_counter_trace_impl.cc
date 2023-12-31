// Copyright 2020 The Lynx Authors. All rights reserved.

#include "tracing/instance_counter_trace_impl.h"

#if LYNX_ENABLE_TRACING
#include <vector>

#include "tracing/trace_event_devtool.h"

namespace lynx {
namespace base {
namespace tracing {

uint64_t InstanceCounterTraceImpl::node_count_ = 0;

InstanceCounterTrace::Impl* __attribute__((weak)) InstanceCounterTrace::impl_;

InstanceCounterTraceImpl::InstanceCounterTraceImpl()
    : thread_("CrRendererMain") {}

void InstanceCounterTraceImpl::JsHeapMemoryUsedTraceImpl(
    const uint64_t jsHeapMemory) {
  thread_.GetTaskRunner()->PostTask([jsHeapMemory] {
    TRACE_EVENT_DEVTOOL(
        LYNX_TRACE_CATEGORY_DEVTOOL_TIMELINE, "UpdateCounters",
        [=](TraceEvent* event) {
          auto* legacy_event = event->set_legacy_event();
          legacy_event->set_phase('I');
          legacy_event->set_unscoped_id(1);
          auto* debug = event->add_debug_annotations();
          std::string data =
              R"({"jsHeapSizeUsed":)" + std::to_string(jsHeapMemory);
          data += R"(,"nodes":)" + std::to_string(node_count_) + "}";
          debug->set_name("data");
          debug->set_legacy_json_value(data);
        });
  });
}

void InstanceCounterTraceImpl::IncrementNodeCounter(tasm::Element* element) {
  if (element == nullptr) {
    return;
  }
  node_count_++;
  for (auto& i : element->GetChild()) {
    IncrementNodeCounter(i);
  }
}

void InstanceCounterTraceImpl::DecrementNodeCounter(tasm::Element* element) {
  if (element == nullptr) {
    return;
  }
  node_count_--;
  for (auto& i : element->GetChild()) {
    DecrementNodeCounter(i);
  }
}

void InstanceCounterTraceImpl::InitNodeCounter() { node_count_ = 0; }

}  // namespace tracing
}  // namespace base
}  // namespace lynx
#endif
