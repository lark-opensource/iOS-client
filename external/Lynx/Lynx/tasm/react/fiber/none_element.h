// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_NONE_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_NONE_ELEMENT_H_

#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {

class NoneElement : public FiberElement {
 public:
  NoneElement(ElementManager* manager);
  bool is_none() const override { return true; }
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_NONE_ELEMENT_H_
