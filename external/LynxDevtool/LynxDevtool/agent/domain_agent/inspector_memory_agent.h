// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef ANDROID_INSPECTOR_MEMORY_AGENT_H
#define ANDROID_INSPECTOR_MEMORY_AGENT_H

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class InspectorMemoryAgent : public InspectorAgentBase {
 public:
  InspectorMemoryAgent();
  virtual ~InspectorMemoryAgent();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorMemoryAgent::*MemoryAgentMethod)(
      std::shared_ptr<DevToolAgentBase> devtool_agent,
      const Json::Value& message);

  void GetAppMemoryInfo(std::shared_ptr<DevToolAgentBase> devtool_agent,
                        const Json::Value& message);
  void StartTracing(std::shared_ptr<DevToolAgentBase> devtoolagent,
                    const Json::Value& message);
  void StopTracing(std::shared_ptr<DevToolAgentBase> devtoolagent,
                   const Json::Value& message);
  void StartDump(std::shared_ptr<DevToolAgentBase> devtoolagent,
                 const Json::Value& message);

  std::map<std::string, MemoryAgentMethod> functions_map_;
};

}  // namespace devtool
}  // namespace lynxdev
#endif  // ANDROID_INSPECTOR_MEMORY_AGENT_H
