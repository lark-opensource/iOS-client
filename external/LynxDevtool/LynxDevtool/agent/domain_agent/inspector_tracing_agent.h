// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_TRACING_AGENT_H_
#define LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_TRACING_AGENT_H_

#include <memory>

#include "agent/domain_agent/inspector_agent_base.h"
#include "base/log/logging.h"

namespace lynxdev {
namespace devtool {

class InspectorTracingAgent : public InspectorAgentBase {
 public:
  InspectorTracingAgent();

  virtual ~InspectorTracingAgent();

  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  using TracingAgentMethod = void (InspectorTracingAgent::*)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);
  std::map<std::string, TracingAgentMethod> functions_map_;
#if LYNX_ENABLE_TRACING
  int tracing_session_id_;
#endif
  void Start(std::shared_ptr<DevToolAgentBase> devtool_agent,
             const Json::Value& message);
  void End(std::shared_ptr<DevToolAgentBase> devtool_agent,
           const Json::Value& message);
  void GetCategories(std::shared_ptr<DevToolAgentBase> devtool_agent,
                     const Json::Value& message);
  void RecordClockSyncMarker(std::shared_ptr<DevToolAgentBase> devtool_agent,
                             const Json::Value& message);
  void RequestMemoryDump(std::shared_ptr<DevToolAgentBase> devtool_agent,
                         const Json::Value& message);
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_TRACING_AGENT_H_
