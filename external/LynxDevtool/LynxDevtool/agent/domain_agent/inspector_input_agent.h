// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_INPUT_AGENT_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_INPUT_AGENT_H_

#include <memory>
#include <unordered_map>

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class InspectorManager;

class InspectorInputAgent : public InspectorAgentBase {
 public:
  InspectorInputAgent();
  virtual ~InspectorInputAgent();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorInputAgent::*InputAgentMethod)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& params);

  void EmulateTouchFromMouseEvent(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);

  std::map<std::string, InputAgentMethod> functions_map_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_INPUT_AGENT_H_
