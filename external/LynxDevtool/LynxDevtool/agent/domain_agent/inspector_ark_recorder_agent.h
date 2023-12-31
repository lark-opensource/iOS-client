// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_ARK_RECORDER_AGENT_H_
#define LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_ARK_RECORDER_AGENT_H_

#include <memory>
#include <unordered_map>

#include "agent/domain_agent/inspector_agent_base.h"
#include "base/log/logging.h"

namespace lynxdev {
namespace devtool {

class InspectorArkRecorderAgent : public InspectorAgentBase {
 public:
  InspectorArkRecorderAgent();
  virtual ~InspectorArkRecorderAgent() override = default;
  void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                  const Json::Value& message) override;

 private:
  using InspectorArkRecorderAgentMethod = void (InspectorArkRecorderAgent::*)(
      const std::shared_ptr<DevToolAgentBase>& devtool_agent,
      const Json::Value& message);
  void Start(const std::shared_ptr<DevToolAgentBase>& devtool_agent,
             const Json::Value& message);
  void End(const std::shared_ptr<DevToolAgentBase>& devtool_agent,
           const Json::Value& message);
  std::unordered_map<std::string, InspectorArkRecorderAgentMethod>
      functions_map_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif /* LYNX_DEVTOOL_AGENT_DOMAIN_AGENT_ARK_RECORDER_AGENT_H_ */
