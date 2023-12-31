// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_UITREE_AGENT_NG_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_UITREE_AGENT_NG_H_

#include <unordered_map>

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class DevToolAgentNG;

class InspectorUITreeAgent : public InspectorAgentBase {
 public:
  InspectorUITreeAgent();
  virtual ~InspectorUITreeAgent() = default;
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorUITreeAgent::*UITreeAgentMethod)(
      std::shared_ptr<DevToolAgentNG> devtool_agent,
      const Json::Value& message);
  void Enable(std::shared_ptr<DevToolAgentNG> devtool_agent,
              const Json::Value& message);
  void Disable(std::shared_ptr<DevToolAgentNG> devtool_agent,
               const Json::Value& message);
  void GetLynxUITree(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  void GetUIInfoForNode(std::shared_ptr<DevToolAgentNG> devtool_agent,
                        const Json::Value& message);
  void SetUIStyle(std::shared_ptr<DevToolAgentNG> devtool_agent,
                  const Json::Value& message);
  void GetUINodeForLocation(std::shared_ptr<DevToolAgentNG> devtool_agent,
                            const Json::Value& message);

 private:
  std::map<std::string, UITreeAgentMethod> functions_map_;
  bool enabled_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_LAYERTREE_AGENT_H_
