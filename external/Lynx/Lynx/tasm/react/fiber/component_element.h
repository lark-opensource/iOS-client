// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_COMPONENT_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_COMPONENT_ELEMENT_H_

#include <memory>

#include "base/base_export.h"
#include "css/css_fragment_decorator.h"
#include "css/css_style_sheet_manager.h"
#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {

class ComponentElement : public FiberElement {
 public:
  ComponentElement(ElementManager* manager, const lepus::String& component_id,
                   int32_t css_id, const lepus::String& entry_name,
                   const lepus::String& name, const lepus::String& path);
  ComponentElement(ElementManager* manager, const lepus::String& component_id,
                   int32_t css_id, const lepus::String& entry_name,
                   const lepus::String& name, const lepus::String& path,
                   const lepus::String& tag_name);

  virtual ~ComponentElement();

  bool is_component() const override { return true; }

  void set_component_id(const lepus::String& component_id);

  lepus::String& component_id() { return component_id_; }

  lepus::String& component_name() { return name_; }

  lepus::String& component_path() { return path_; }

  lepus::String& component_entry() { return entry_name_; }

  void set_style_sheet_manager(std::shared_ptr<CSSStyleSheetManager> manager) {
    css_style_sheet_manager_ = manager;
  }

  std::shared_ptr<CSSStyleSheetManager> style_sheet_manage() {
    return css_style_sheet_manager_;
  }

  BASE_EXPORT_FOR_DEVTOOL CSSFragment* GetCSSFragment();

 private:
  void UpdateRootCSSVariables(AttributeHolder* holder,
                              const std::shared_ptr<CSSParseToken>& root_token);
  void PrepareForRootCSSVariables();

  lepus::String component_id_{};
  int32_t component_css_id_{-1};
  lepus::String entry_name_{};
  lepus::String name_{};
  lepus::String path_{};
  CSSFragment* fragment_{nullptr};
  std::shared_ptr<CSSFragmentDecorator> style_sheet_{nullptr};
  std::shared_ptr<CSSStyleSheetManager> css_style_sheet_manager_{nullptr};
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_COMPONENT_ELEMENT_H_
