// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_LYNX_AGENT_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_LYNX_AGENT_H_

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class DevToolAgentNG;

class InspectorLynxAgentNG : public InspectorAgentBase {
 public:
  InspectorLynxAgentNG();
  virtual ~InspectorLynxAgentNG();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorLynxAgentNG::*LynxAgentMethod)(
      std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& params);

  void GetProperties(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  void GetData(std::shared_ptr<DevToolAgentNG> devtool_agent,
               const Json::Value& message);
  void GetComponentId(std::shared_ptr<DevToolAgentNG> devtool_agent,
                      const Json::Value& message);
  void GetLynxViewRectToWindow(std::shared_ptr<DevToolAgentNG> devtool_agent,
                               const Json::Value& message);
  void GetLynxVersion(std::shared_ptr<DevToolAgentNG> devtool_agent,
                      const Json::Value& message);

  void TransferData(std::shared_ptr<DevToolAgentNG> devtool_agent,
                    const Json::Value& message);

  void SetTraceMode(std::shared_ptr<DevToolAgentNG> devtool_agent,
                    const Json::Value& message);

  void GetScreenshot(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);

  std::map<std::string, LynxAgentMethod> functions_map_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif
