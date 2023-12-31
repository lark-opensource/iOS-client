// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_RUNTIME_AGENT_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_RUNTIME_AGENT_H_

#include <unordered_map>

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class InspectorRuntimeAgent : public InspectorAgentBase {
 public:
  InspectorRuntimeAgent();
  virtual ~InspectorRuntimeAgent();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorRuntimeAgent::*RuntimeAgentMethod)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& params);
  void Enable(std::shared_ptr<DevToolAgentBase> devtool_agent,
              const Json::Value& message);

  std::map<std::string, RuntimeAgentMethod> functions_map_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_RUNTIME_AGENT_H_
