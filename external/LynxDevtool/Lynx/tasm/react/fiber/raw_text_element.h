// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_RAW_TEXT_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_RAW_TEXT_ELEMENT_H_

#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {

class RawTextElement : public FiberElement {
 public:
  RawTextElement(ElementManager* manager);
  bool is_raw_text() const override { return true; }
  void SetText(const lepus::Value& text);

  constexpr const static char* kTextAttr = "text";
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_RAW_TEXT_ELEMENT_H_
