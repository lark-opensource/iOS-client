// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_COMPONENT_AGENT_H_
#define LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_COMPONENT_AGENT_H_

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class InspectorComponentAgent : public InspectorAgentBase {
 public:
  InspectorComponentAgent();
  virtual ~InspectorComponentAgent();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorComponentAgent::*ComponentAgentMethod)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);

  void UselessUpdate(std::shared_ptr<DevToolAgentBase> devtool_agent,
                     const Json::Value& message);

  std::map<std::string, ComponentAgentMethod> functions_map_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_COMPONENT_AGENT_H_
