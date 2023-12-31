// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_HEAP_PROFILER_AGENT_H_
#define LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_HEAP_PROFILER_AGENT_H_

#include <memory>

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class InspectorHeapProfilerAgent : public InspectorAgentBase {
 public:
  InspectorHeapProfilerAgent() = default;
  ~InspectorHeapProfilerAgent() override = default;

  void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                  const Json::Value& message) override;
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_HEAP_PROFILER_AGENT_H_
