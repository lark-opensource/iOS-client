// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_PAGE_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_PAGE_ELEMENT_H_

#include "tasm/react/fiber/component_element.h"

namespace lynx {
namespace tasm {

class ElementManager;

class PageElement : public ComponentElement {
 public:
  PageElement(ElementManager* manager, const lepus::String& component_id,
              int32_t css_id);

  bool is_page() const override { return true; }

  virtual bool FlushActionsAsRoot() override;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_PAGE_ELEMENT_H_
