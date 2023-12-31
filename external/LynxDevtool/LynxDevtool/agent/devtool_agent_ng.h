// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_DEVTOOL_AGENT_NG_H
#define LYNX_INSPECTOR_DEVTOOL_AGENT_NG_H

#include <memory>
#include <unordered_map>

#include "devtool_agent_base.h"
#include "domain_agent/inspector_agent_base.h"
#include "third_party/fml/thread.h"
#include "third_party/jsoncpp/include/json/json.h"

namespace lynx {
namespace tasm {
class Element;
}
}  // namespace lynx

namespace lynxdev {
namespace devtool {

class DevToolAgentNG : public DevToolAgentBase {
 public:
  DevToolAgentNG();
  virtual void DispatchJsonMessage(const Json::Value& msg) override;
  virtual void DispatchConsoleMessage(
      const lynx::piper::ConsoleMessage& message) override;
  virtual void Call(const std::string& function,
                    const std::string& params) override;

  virtual void SendJsonResponse(const Json::Value& data) override;
  virtual void SendResponseAsync(const Json::Value& data) override;
  virtual void SendResponseAsync(lynx::base::closure closure) override;

  virtual void ResponseError(int id, const std::string& error) override;
  virtual void ResponseOK(int id) override;

  virtual intptr_t GetLynxDevtoolFunction() override;
  virtual void ResetTreeRoot() override;

  virtual void RunOnAgentThread(lynx::base::closure closure) override;

  void OnDocumentUpdated();
  void OnElementNodeAdded(lynx::tasm::Element* ptr);
  void OnElementNodeRemoved(lynx::tasm::Element* ptr);
  void OnElementNodeMoved(lynx::tasm::Element* ptr);
  void OnElementDataModelSetted(lynx::tasm::Element* ptr,
                                intptr_t new_node_ptr);
  void OnCSSStyleSheetAdded(lynx::tasm::Element* ptr);
  void OnLayoutPerformanceCollected(const std::string& performanceStr);
  void OnComponentUselessUpdate(const std::string* const component_name,
                                const lynx::lepus::Value* const properties);
  void OnSetNativeProps(lynx::tasm::Element* ptr, const std::string& name,
                        const std::string& value, bool is_style);

  void EndReplayTest(const std::string& file_path);
  void SendLayoutTree();
  void SendUITree();

  void DiffID(lynx::tasm::Element* ptr, intptr_t new_node_ptr);
  void DiffAttr(lynx::tasm::Element* ptr, intptr_t new_node_ptr);
  void DiffClass(lynx::tasm::Element* ptr, intptr_t new_node_ptr);
  void DiffStyle(lynx::tasm::Element* ptr, intptr_t new_node_ptr);

  lynx::tasm::Element* GetRoot();
  lynx::tasm::Element* GetElementById(lynx::tasm::Element* root,
                                      size_t indexId);
  void GetElementPtrMatchingStyleSheet(std::vector<lynx::tasm::Element*>& res,
                                       lynx::tasm::Element* root,
                                       const std::string& style_sheet_name);
  bool GetElementPtrMatchingForCascadedStyleSheet(
      std::vector<lynx::tasm::Element*>& res, lynx::tasm::Element* root,
      const std::string& name, const std::string& style_sheet_name);
  void GetElementByType(InspectorElementType type,
                        std::vector<lynx::tasm::Element*>& res,
                        lynx::tasm::Element* root);

 protected:
  lynx::fml::Thread& GetAgentThread();
  void Attach();
  void Attach(const std::string& domain_key);

  lynx::tasm::Element* element_root_;
  std::unordered_map<std::string, std::unique_ptr<InspectorAgentBase>>
      agent_map_;
};

}  // namespace devtool
}  // namespace lynxdev

#endif
