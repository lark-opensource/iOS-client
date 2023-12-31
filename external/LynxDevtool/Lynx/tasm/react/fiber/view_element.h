// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_VIEW_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_VIEW_ELEMENT_H_

#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {

class ElementManager;

class ViewElement : public FiberElement {
 public:
  ViewElement(ElementManager* manager);

  bool is_view() const override { return true; }
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_VIEW_ELEMENT_H_
