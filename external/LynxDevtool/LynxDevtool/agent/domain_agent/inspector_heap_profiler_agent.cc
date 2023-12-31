// Copyright 2020 The Lynx Authors. All rights reserved.

#include "agent/domain_agent/inspector_heap_profiler_agent.h"

#include "agent/devtool_agent_base.h"

namespace lynxdev {
namespace devtool {

void InspectorHeapProfilerAgent::CallMethod(
    std::shared_ptr<DevToolAgentBase> devtool_agent,
    const Json::Value& message) {
  devtool_agent->DispatchMessageToJSEngine(message.toStyledString());
}

}  // namespace devtool
}  // namespace lynxdev
