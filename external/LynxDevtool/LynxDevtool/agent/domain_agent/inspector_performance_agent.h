// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_PERFORMANCE_AGENT_H_
#define LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_PERFORMANCE_AGENT_H_

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class InspectorPerformanceAgent : public InspectorAgentBase {
 public:
  InspectorPerformanceAgent();
  virtual ~InspectorPerformanceAgent();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorPerformanceAgent::*PerformanceAgentMethod)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);

  void Enable(std::shared_ptr<DevToolAgentBase> devtool_agent,
              const Json::Value& message);
  void Disable(std::shared_ptr<DevToolAgentBase> devtool_agent,
               const Json::Value& message);
  void getMetrics(std::shared_ptr<DevToolAgentBase> devtool_agent,
                  const Json::Value& message);
  void getAllTimingInfo(std::shared_ptr<DevToolAgentBase> devtool_agent,
                        const Json::Value& message);
  bool ready_;
  std::map<std::string, PerformanceAgentMethod> functions_map_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_PERFORMANCE_AGENT_H_
