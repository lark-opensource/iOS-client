// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_SCROLL_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_SCROLL_ELEMENT_H_

#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {

class ScrollElement : public FiberElement {
 public:
  ScrollElement(ElementManager* manager, const lepus::String& tag)
      : FiberElement(manager, tag) {}
  bool is_scroll_view() const override { return true; }

 protected:
  void OnNodeAdded(FiberElement* child) override;
  void SetAttributeInternal(const lepus::String& key,
                            const lepus::Value& value) override;
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_SCROLL_ELEMENT_H_
