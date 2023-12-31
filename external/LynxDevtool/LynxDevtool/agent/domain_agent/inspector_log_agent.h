// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_LOG_AGENT_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_LOG_AGENT_H_

#include <unordered_map>

#include "agent/domain_agent/inspector_agent_base.h"
#include "jsbridge/bindings/console_message_postman.h"

namespace lynxdev {
namespace devtool {

class InspectorLogAgent : public InspectorAgentBase {
 public:
  InspectorLogAgent();
  virtual ~InspectorLogAgent();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;
  void SendLog(std::shared_ptr<DevToolAgentBase> devtool_agent,
               const lynx::piper::ConsoleMessage& message);

 private:
  typedef void (InspectorLogAgent::*LogAgentMethod)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);
  void FireCacheLogs(std::shared_ptr<DevToolAgentBase> devtool_agent);
  void PostLog(std::shared_ptr<DevToolAgentBase> devtool_agent,
               const lynx::piper::ConsoleMessage& message);
  void Enable(std::shared_ptr<DevToolAgentBase> devtool_agent,
              const Json::Value& message);
  void Disable(std::shared_ptr<DevToolAgentBase> devtool_agent,
               const Json::Value& message);
  void EntryAdded(std::shared_ptr<DevToolAgentBase> devtool_agent,
                  const Json::Value& message);
  void StartViolationsReport(std::shared_ptr<DevToolAgentBase> devtool_agent,
                             const Json::Value& message);

  bool ready_;
  std::vector<lynx::piper::ConsoleMessage> logMessageQueue_;
  std::map<std::string, LogAgentMethod> functions_map_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_LOG_AGENT_H_
