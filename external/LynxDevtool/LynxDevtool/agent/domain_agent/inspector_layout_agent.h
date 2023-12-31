// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_LAYOUT_AGENT_H_
#define LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_LAYOUT_AGENT_H_

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class InspectorLayoutAgent : public InspectorAgentBase {
 public:
  InspectorLayoutAgent();
  virtual ~InspectorLayoutAgent();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorLayoutAgent::*LayoutAgentMethod)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);

  void Enable(std::shared_ptr<DevToolAgentBase> devtool_agent,
              const Json::Value& message);
  void Disable(std::shared_ptr<DevToolAgentBase> devtool_agent,
               const Json::Value& message);
  void DataCollected(std::shared_ptr<DevToolAgentBase> devtool_agent,
                     const Json::Value& message);

  std::map<std::string, LayoutAgentMethod> functions_map_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_LAYOUT_AGENT_H_
