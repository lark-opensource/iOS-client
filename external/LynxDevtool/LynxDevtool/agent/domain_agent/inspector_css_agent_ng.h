// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_CSS_AGENT_NG_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_CSS_AGENT_NG_H_

#include <memory>
#include <set>
#include <unordered_map>

#include "agent/domain_agent/inspector_agent_base.h"
#include "tasm/react/element.h"

namespace lynxdev {
namespace devtool {

class DevToolAgentNG;

class InspectorCSSAgentNG : public InspectorAgentBase {
 public:
  InspectorCSSAgentNG();
  virtual ~InspectorCSSAgentNG();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorCSSAgentNG::*CSSAgentMethod)(
      std::shared_ptr<DevToolAgentNG> devtool_agent,
      const Json::Value& message);

  void Enable(std::shared_ptr<DevToolAgentNG> devtool_agent,
              const Json::Value& message);
  void Disable(std::shared_ptr<DevToolAgentNG> devtool_agent,
               const Json::Value& message);
  void GetMatchedStylesForNode(std::shared_ptr<DevToolAgentNG> devtool_agent,
                               const Json::Value& message);
  void GetComputedStyleForNode(std::shared_ptr<DevToolAgentNG> devtool_agent,
                               const Json::Value& message);
  void GetInlineStylesForNode(std::shared_ptr<DevToolAgentNG> devtool_agent,
                              const Json::Value& message);
  void SetStyleTexts(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  void GetStyleSheetText(std::shared_ptr<DevToolAgentNG> devtool_agent,
                         const Json::Value& message);
  void GetBackgroundColors(std::shared_ptr<DevToolAgentNG> devtool_agent,
                           const Json::Value& message);
  void StyleSheetChanged(std::shared_ptr<DevToolAgentNG> devtool_agent,
                         const Json::Value& message);
  void StyleSheetAdded(std::shared_ptr<DevToolAgentNG> devtool_agent,
                       const Json::Value& message);
  void StyleSheetRemoved(std::shared_ptr<DevToolAgentNG> devtool_agent,
                         const Json::Value& message);
  void DispatchMessage(std::shared_ptr<DevToolAgentNG> devtool_agent,
                       lynx::tasm::Element* ptr, const std::string& sheet_id);
  void SetStyleSheetText(std::shared_ptr<DevToolAgentNG> devtool_agent,
                         const Json::Value& message);
  void CreateStyleSheet(std::shared_ptr<DevToolAgentNG> devtool_agent,
                        const Json::Value& message);
  void AddRule(std::shared_ptr<DevToolAgentNG> devtool_agent,
               const Json::Value& message);
  void StartRuleUsageTracking(std::shared_ptr<DevToolAgentNG> devtool_agent,
                              const Json::Value& message);
  void UpdateRuleUsageTracking(std::shared_ptr<DevToolAgentNG> devtool_agent,
                               const Json::Value& message);
  void StopRuleUsageTracking(std::shared_ptr<DevToolAgentNG> devtool_agent,
                             const Json::Value& message);
  void CollectDomTreeCssUsage(
      const std::shared_ptr<DevToolAgentNG>& devtool_agent,
      Json::Value& rule_usage_array, const std::string& stylesheet_id,
      const std::string& content);
  Json::Value GetUsageItem(const std::string& stylesheet_id,
                           const std::string& content,
                           const std::string& selector);

  std::map<std::string, CSSAgentMethod> functions_map_;

  std::set<std::string> css_used_selector_;
  bool rule_usage_tracking_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_CSS_AGENT_H_
