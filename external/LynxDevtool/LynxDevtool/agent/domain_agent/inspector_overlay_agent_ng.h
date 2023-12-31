// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_OVERLAY_AGENT_NG_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_OVERLAY_AGENT_NG_H_

#include <memory>
#include <unordered_map>

#include "agent/devtool_agent_base.h"
#include "agent/domain_agent/inspector_agent_base.h"
#include "inspector/style_sheet.h"
#include "tasm/react/element.h"

namespace lynxdev {
namespace devtool {

class DevToolAgentNG;

class InspectorOverlayAgentNG : public InspectorAgentBase {
 public:
  InspectorOverlayAgentNG();
  virtual ~InspectorOverlayAgentNG() = default;
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorOverlayAgentNG::*OverlayAgentMethod)(
      std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& params);

  void HighlightNode(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  void HideHighlight(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  void RestoreOriginNodeInlineStyle(
      std::shared_ptr<DevToolAgentNG> devtool_agent);

  std::map<std::string, OverlayAgentMethod> functions_map_;
  InspectorStyleSheet origin_inline_style_;
  size_t origin_node_id_ = 0;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_DOM_AGENT_H_
