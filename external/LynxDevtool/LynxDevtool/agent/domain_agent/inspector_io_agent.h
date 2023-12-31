// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_IO_AGENT_H_
#define LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_IO_AGENT_H_

#include <memory>

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class InspectorIOAgent : public InspectorAgentBase {
 public:
  InspectorIOAgent();

  virtual ~InspectorIOAgent();

  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  using IOAgentMethod = void (InspectorIOAgent::*)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);
  std::map<std::string, IOAgentMethod> functions_map_;
  void Read(std::shared_ptr<DevToolAgentBase> devtool_agent,
            const Json::Value& message);
  void Close(std::shared_ptr<DevToolAgentBase> devtool_agent,
             const Json::Value& message);
  void ResolveBlob(std::shared_ptr<DevToolAgentBase> devtool_agent,
                   const Json::Value& message);
};

}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_INSPECTOR_IO_AGENT_H_
