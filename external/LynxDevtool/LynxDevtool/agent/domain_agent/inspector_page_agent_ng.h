// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_PAGE_AGENT_NG_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_PAGE_AGENT_NG_H_

#include <memory>
#include <unordered_map>

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class DevToolAgentNG;

class InspectorPageAgentNG : public InspectorAgentBase {
 public:
  InspectorPageAgentNG();
  virtual ~InspectorPageAgentNG();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorPageAgentNG::*PageAgentMethod)(
      std::shared_ptr<DevToolAgentNG> devtool_agent,
      const Json::Value& message);
  void Enable(std::shared_ptr<DevToolAgentNG> devtool_agent,
              const Json::Value& message);
  void CanScreencast(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  void CanEmulate(std::shared_ptr<DevToolAgentNG> devtool_agent,
                  const Json::Value& message);
  void GetResourceTree(std::shared_ptr<DevToolAgentNG> devtool_agent,
                       const Json::Value& message);
  void GetResourceContent(std::shared_ptr<DevToolAgentNG> devtool_agent,
                          const Json::Value& message);
  void GetNavigationHistory(std::shared_ptr<DevToolAgentNG> devtool_agent,
                            const Json::Value& message);
  void SetShowViewportSizeOnResize(
      std::shared_ptr<DevToolAgentNG> devtool_agent,
      const Json::Value& message);
  void StartScreencast(std::shared_ptr<DevToolAgentNG> devtool_agent,
                       const Json::Value& message);
  void StopScreencast(std::shared_ptr<DevToolAgentNG> devtool_agent,
                      const Json::Value& message);
  void ScreencastFrameAck(std::shared_ptr<DevToolAgentNG> devtool_agent,
                          const Json::Value& message);
  void ScreencastVisibilityChanged(
      std::shared_ptr<DevToolAgentNG> devtool_agent,
      const Json::Value& message);
  void Reload(std::shared_ptr<DevToolAgentNG> devtool_agent,
              const Json::Value& message);
  void Navigate(std::shared_ptr<DevToolAgentNG> devtool_agent,
                const Json::Value& message);

  void NotifExecutionContext(std::shared_ptr<DevToolAgentNG> devtool_agent);
  void SendWelcomeMessage(std::shared_ptr<DevToolAgentNG> devtool_agent);
  void TriggerFrameNavigated(
      const std::shared_ptr<DevToolAgentNG>& devtool_agent);

  std::map<std::string, PageAgentMethod> functions_map_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_PAGE_AGENT_NG_H_
