// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_SYSTEM_INFO_AGENT_H_
#define LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_SYSTEM_INFO_AGENT_H_

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class SystemInfoAgent : public InspectorAgentBase {
 public:
  SystemInfoAgent();
  virtual ~SystemInfoAgent();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (SystemInfoAgent::*PerformanceAgentMethod)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);

  void getInfo(std::shared_ptr<DevToolAgentBase> devtool_agent,
               const Json::Value& message);

  std::map<std::string, PerformanceAgentMethod> functions_map_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_SYSTEM_INFO_AGENT_H_
