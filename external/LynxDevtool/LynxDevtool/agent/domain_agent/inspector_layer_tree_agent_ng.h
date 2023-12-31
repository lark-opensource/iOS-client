// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_LAYERTREE_AGENT_NG_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_LAYERTREE_AGENT_NG_H_

#include <unordered_map>

#include "Lynx/tasm/react/element.h"
#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class DevToolAgentNG;

class InspectorLayerTreeAgentNG : public InspectorAgentBase {
 public:
  InspectorLayerTreeAgentNG();
  virtual ~InspectorLayerTreeAgentNG() = default;
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorLayerTreeAgentNG::*LayerTreeAgentMethod)(
      std::shared_ptr<DevToolAgentNG> devtool_agent,
      const Json::Value& message);

  void Enable(std::shared_ptr<DevToolAgentNG> devtool_agent,
              const Json::Value& message);
  void Disable(std::shared_ptr<DevToolAgentNG> devtool_agent,
               const Json::Value& message);
  void CompositingReasons(std::shared_ptr<DevToolAgentNG> devtool_agent,
                          const Json::Value& message);
  void LayerTreeDidChange(std::shared_ptr<DevToolAgentNG> devtool_agent,
                          const Json::Value& message);
  void LayerPainted(std::shared_ptr<DevToolAgentNG> devtool_agent,
                    const Json::Value& message);

  Json::Value GetLayerContentFromElement(lynx::tasm::Element*);
  Json::Value GetLayoutInfoFromElement(lynx::tasm::Element*);
  Json::Value BuildLayerTreeFromElement(lynx::tasm::Element*);

 private:
  std::map<std::string, LayerTreeAgentMethod> functions_map_;
  bool enabled_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_LAYERTREE_AGENT_H_
