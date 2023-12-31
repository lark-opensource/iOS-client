// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef ANDROID_INSPECTOR_TEMPLATE_AGENT_H
#define ANDROID_INSPECTOR_TEMPLATE_AGENT_H

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class InspectorTemplateAgent : public InspectorAgentBase {
 public:
  InspectorTemplateAgent();
  virtual ~InspectorTemplateAgent();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorTemplateAgent::*TemplateAgentMethod)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);
  void GetTemplateData(std::shared_ptr<DevToolAgentBase> devtool_agent,
                       const Json::Value& message);
  void GetTemplateConfigInfo(std::shared_ptr<DevToolAgentBase> devtool_agent,
                             const Json::Value& message);
  void GetTemplateApiInfo(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message);

  std::map<std::string, TemplateAgentMethod> functions_map_;
};

}  // namespace devtool
}  // namespace lynxdev
#endif  // ANDROID_INSPECTOR_TEMPLATE_AGENT_H
