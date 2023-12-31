// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_DOM_AGENT_NG_H_
#define LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_DOM_AGENT_NG_H_

#include <memory>
#include <unordered_map>

#include "agent/domain_agent/inspector_agent_base.h"

namespace lynxdev {
namespace devtool {

class DevToolAgentNG;

class InspectorDOMAgentNG : public InspectorAgentBase {
 public:
  InspectorDOMAgentNG();
  virtual ~InspectorDOMAgentNG();
  virtual void CallMethod(std::shared_ptr<DevToolAgentBase> devtool_agent,
                          const Json::Value& message) override;

 private:
  typedef void (InspectorDOMAgentNG::*DOMAgentMethod)(
      std::shared_ptr<DevToolAgentNG> devtool_agent, const Json::Value& params);

  void Enable(std::shared_ptr<DevToolAgentNG> devtool_agent,
              const Json::Value& message);
  void Disable(std::shared_ptr<DevToolAgentNG> devtool_agent,
               const Json::Value& message);
  void EnableDomTree(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  void DisableDomTree(std::shared_ptr<DevToolAgentNG> devtool_agent,
                      const Json::Value& message);
  void GetDocument(std::shared_ptr<DevToolAgentNG> devtool_agent,
                   const Json::Value& message);
  void GetDocumentWithBoxModel(std::shared_ptr<DevToolAgentNG> devtool_agent,
                               const Json::Value& message);
  void RequestChildNodes(std::shared_ptr<DevToolAgentNG> devtool_agent,
                         const Json::Value& message);
  void GetBoxModel(std::shared_ptr<DevToolAgentNG> devtool_agent,
                   const Json::Value& message);
  void SetAttributesAsText(std::shared_ptr<DevToolAgentNG> devtool_agent,
                           const Json::Value& message);
  void AttributeModified(std::shared_ptr<DevToolAgentNG> devtool_agent,
                         const Json::Value& message);
  void MarkUndoableState(std::shared_ptr<DevToolAgentNG> devtool_agent,
                         const Json::Value& message);
  void CharacterDataModified(std::shared_ptr<DevToolAgentNG> devtool_agent,
                             const Json::Value& message);
  void DocumentUpdated(std::shared_ptr<DevToolAgentNG> devtool_agent,
                       const Json::Value& message);
  void AttributeRemoved(std::shared_ptr<DevToolAgentNG> devtool_agent,
                        const Json::Value& message);
  void ChildNodeInserted(std::shared_ptr<DevToolAgentNG> devtool_agent,
                         const Json::Value& message);
  void ChildNodeRemoved(std::shared_ptr<DevToolAgentNG> devtool_agent,
                        const Json::Value& message);
  void GetNodeForLocation(std::shared_ptr<DevToolAgentNG> devtool_agent,
                          const Json::Value& message);
  void PushNodesByBackendIdsToFrontend(
      std::shared_ptr<DevToolAgentNG> devtool_agent,
      const Json::Value& message);
  void RemoveNode(std::shared_ptr<DevToolAgentNG> devtool_agent,
                  const Json::Value& message);
  void CopyTo(std::shared_ptr<DevToolAgentNG> devtool_agent,
              const Json::Value& message);
  void MoveTo(std::shared_ptr<DevToolAgentNG> devtool_agent,
              const Json::Value& message);
  void GetOuterHTML(std::shared_ptr<DevToolAgentNG> devtool_agent,
                    const Json::Value& message);
  void SetOuterHTML(std::shared_ptr<DevToolAgentNG> devtool_agent,
                    const Json::Value& message);
  void SetInspectedNode(std::shared_ptr<DevToolAgentNG> devtool_agent,
                        const Json::Value& message);
  void QuerySelector(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  void QuerySelectorAll(std::shared_ptr<DevToolAgentNG> devtool_agent,
                        const Json::Value& message);
  void InnerText(std::shared_ptr<DevToolAgentNG> devtool_agent,
                 const Json::Value& message);
  void GetAttributes(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  Json::Value GetAttributesImpl(std::shared_ptr<DevToolAgentNG> devtool_agent,
                                size_t node_id);
  void PerformSearch(std::shared_ptr<DevToolAgentNG> devtool_agent,
                     const Json::Value& message);
  void GetSearchResults(std::shared_ptr<DevToolAgentNG> devtool_agent,
                        const Json::Value& message);
  void DiscardSearchResults(std::shared_ptr<DevToolAgentNG> devtool_agent,
                            const Json::Value& message);
  void ScrollIntoViewIfNeeded(std::shared_ptr<DevToolAgentNG> devtool_agent,
                              const Json::Value& message);

  std::unordered_map<uint64_t, std::vector<int>> search_results_;
  std::map<std::string, DOMAgentMethod> functions_map_;
};
}  // namespace devtool
}  // namespace lynxdev

#endif  // LYNX_INSPECTOR_DOMAIN_AGENT_INSPECTOR_DOM_AGENT_H_
