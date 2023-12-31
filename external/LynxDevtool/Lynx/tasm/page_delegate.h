// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_PAGE_DELEGATE_H_
#define LYNX_TASM_PAGE_DELEGATE_H_

#include <memory>
#include <string>

#include "lepus/value.h"

namespace lynx {
namespace tasm {

// delegate use for VirtualPage and RadonPage
class PageDelegate {
 public:
  PageDelegate() = default;
  virtual ~PageDelegate() = default;

  virtual void OnComponentActivity(const std::string &action,
                                   const std::string &component_id,
                                   const std::string &parent_component_id,
                                   const std::string &path,
                                   const std::string &entry_name,
                                   const lepus::Value &data) = 0;
  virtual void OnComponentPropertiesChanged(const std::string &component_id,
                                            const lepus::Value &properties) = 0;
  virtual void OnReactComponentRender(const std::string &id,
                                      const lepus::Value &props,
                                      const lepus::Value &data,
                                      bool should_component_update) = 0;
  virtual void OnReactComponentDidUpdate(const std::string &id) = 0;
  virtual void OnReactComponentDidCatch(const std::string &id,
                                        const lepus::Value &error) = 0;

  virtual void OnComponentDataSetChanged(const std::string &component_id,
                                         const lepus::Value &data_set) = 0;
  virtual void OnComponentSelectorChanged(const std::string &component_id,
                                          const lepus::Value &instance) = 0;
  virtual void OnReactComponentCreated(const std::string &entry_name,
                                       const std::string &path,
                                       const std::string &id,
                                       const lepus::Value &props,
                                       const lepus::Value &data,
                                       const std::string &parent_id,
                                       bool force_flush) = 0;
  virtual void OnReactComponentUnmount(const std::string &id) = 0;
  virtual void OnReactCardRender(const lepus::Value &data,
                                 bool should_component_update,
                                 bool force_layout) = 0;
  virtual void OnReactCardDidUpdate() = 0;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_PAGE_DELEGATE_H_
