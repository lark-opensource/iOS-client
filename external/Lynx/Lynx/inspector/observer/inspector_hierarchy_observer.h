// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_OBSERVER_INSPECTOR_HIERARCHY_OBSERVER_H_
#define LYNX_INSPECTOR_OBSERVER_INSPECTOR_HIERARCHY_OBSERVER_H_

#include <map>
#include <memory>
#include <string>

#include "tasm/observer/ui_impl_observer.h"
#include "tasm/react/element_manager.h"

namespace lynx {

namespace tasm {
class Element;
}  // namespace tasm

namespace devtool {

class InspectorManager;

class InspectorUIImplObserver : public tasm::UIImplObserver {
 public:
  InspectorUIImplObserver() = default;
  ~InspectorUIImplObserver() override = default;
  virtual void OnElementDataModelSetted(
      tasm::Element* ptr, tasm::AttributeHolder* new_node_ptr) override;
  void SetInspectorManager(std::shared_ptr<InspectorManager> ptr);

 private:
  std::weak_ptr<InspectorManager> inspector_manager_wp_;
};

class InspectorHierarchyObserver : public tasm::HierarchyObserver {
 public:
  InspectorHierarchyObserver() = default;
  ~InspectorHierarchyObserver() override = default;

  intptr_t GetLynxDevtoolFunction() override;

  void OnDocumentUpdated() override;
  void OnElementNodeAdded(tasm::Element* ptr) override;
  void OnElementNodeRemoved(tasm::Element* ptr) override;
  void OnElementNodeMoved(tasm::Element* ptr) override;
  void OnCSSStyleSheetAdded(tasm::Element* ptr) override;
  void OnElementDataModelSetted(tasm::Element* ptr,
                                tasm::AttributeHolder* new_node_ptr) override;
  void OnLayoutPerformanceCollected(std::string& performanceStr) override;
  void OnComponentUselessUpdate(const std::string& component_name,
                                const lepus::Value& properties) override;
  void OnSetNativeProps(tasm::Element* ptr, const std::string& name,
                        const std::string& value, bool is_style) override;

  void SetInspectorManager(std::shared_ptr<InspectorManager> ptr);
  void EnsureUIImplObserver() override;

 private:
  std::shared_ptr<InspectorUIImplObserver> inspector_uiimpl_observer_;
  std::weak_ptr<InspectorManager> inspector_manager_wp_;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_OBSERVER_INSPECTOR_HIERARCHY_OBSERVER_H_
