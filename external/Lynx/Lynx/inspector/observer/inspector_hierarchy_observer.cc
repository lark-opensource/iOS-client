// Copyright 2019 The Lynx Authors. All rights reserved.

#include "inspector/observer/inspector_hierarchy_observer.h"

#include <cstdarg>
#include <queue>
#include <vector>

#include "inspector/inspector_manager.h"
#include "tasm/base/tasm_constants.h"

namespace lynx {
namespace devtool {

namespace {

//
// Convert a variable number of parameters to json string
//
//  parameters:
//  count: number of parameters, which must be exactly correct, otherwise it
//  will cause undefined behavior
//   ...: variable parameters whose types are all intptr_t
//
//  return value:
//  converted json string
std::string ToJsonArrayString(int count, ...) {
  std::string res = "[";
  va_list args;
  va_start(args, count);
  for (int i = 0; i < count; i++) {
    res += lepus::to_string(va_arg(args, intptr_t));
    res += ",";
  }
  va_end(args);

  res += "]";
  return res;
}
}  // namespace

void InspectorUIImplObserver::OnElementDataModelSetted(
    tasm::Element* ptr, tasm::AttributeHolder* new_node_ptr) {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call("OnElementDataModelSetted",
                  ToJsonArrayString(2, reinterpret_cast<intptr_t>(ptr),
                                    reinterpret_cast<uintptr_t>(new_node_ptr)));
  }
}

void InspectorUIImplObserver::SetInspectorManager(
    std::shared_ptr<InspectorManager> ptr) {
  inspector_manager_wp_ = ptr;
}

intptr_t InspectorHierarchyObserver::GetLynxDevtoolFunction() {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    return manager->GetLynxDevtoolFunction();
  } else {
    return 0;
  }
}

void InspectorHierarchyObserver::OnDocumentUpdated() {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call(tasm::kOnDocumentUpdated, ToJsonArrayString(0));
  }
}

void InspectorHierarchyObserver::OnElementNodeAdded(tasm::Element* ptr) {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call("OnElementNodeAdded",
                  ToJsonArrayString(1, reinterpret_cast<intptr_t>(ptr)));
  }
}

void InspectorHierarchyObserver::OnElementNodeRemoved(tasm::Element* ptr) {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call("OnElementNodeRemoved",
                  ToJsonArrayString(1, reinterpret_cast<intptr_t>(ptr)));
  }
}

void InspectorHierarchyObserver::OnElementNodeMoved(tasm::Element* ptr) {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call("OnElementNodeMoved",
                  ToJsonArrayString(1, reinterpret_cast<intptr_t>(ptr)));
  }
}

void InspectorHierarchyObserver::OnCSSStyleSheetAdded(tasm::Element* ptr) {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call("OnCSSStyleSheetAdded",
                  ToJsonArrayString(1, reinterpret_cast<intptr_t>(ptr)));
  }
}

void InspectorHierarchyObserver::OnLayoutPerformanceCollected(
    std::string& performanceStr) {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call("OnLayoutPerformanceCollected", performanceStr);
  }
}

void InspectorHierarchyObserver::OnComponentUselessUpdate(
    const std::string& component_name, const lepus::Value& properties) {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call(
        "OnComponentUselessUpdate",
        ToJsonArrayString(2, reinterpret_cast<intptr_t>(&component_name),
                          reinterpret_cast<intptr_t>(&properties)));
  }
}

void InspectorHierarchyObserver::OnSetNativeProps(tasm::Element* ptr,
                                                  const std::string& name,
                                                  const std::string& value,
                                                  bool is_style) {
  auto manager = inspector_manager_wp_.lock();
  if (manager != nullptr) {
    manager->Call("OnSetNativeProps",
                  ToJsonArrayString(4, reinterpret_cast<intptr_t>(ptr),
                                    reinterpret_cast<intptr_t>(&name),
                                    reinterpret_cast<intptr_t>(&value),
                                    reinterpret_cast<intptr_t>(&is_style)));
  }
}

void InspectorHierarchyObserver::OnElementDataModelSetted(
    tasm::Element* ptr, tasm::AttributeHolder* new_node_ptr) {
  if (inspector_uiimpl_observer_) {
    inspector_uiimpl_observer_->OnElementDataModelSetted(ptr, new_node_ptr);
  }
}

void InspectorHierarchyObserver::SetInspectorManager(
    std::shared_ptr<InspectorManager> ptr) {
  inspector_manager_wp_ = ptr;
}

void InspectorHierarchyObserver::EnsureUIImplObserver() {
  if (inspector_uiimpl_observer_ == nullptr) {
    inspector_uiimpl_observer_ = std::make_shared<InspectorUIImplObserver>();
    inspector_uiimpl_observer_->SetInspectorManager(
        inspector_manager_wp_.lock());
  }
}

}  // namespace devtool
}  // namespace lynx
