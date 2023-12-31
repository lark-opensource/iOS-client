// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/none_element.h"

namespace lynx {
namespace tasm {

NoneElement::NoneElement(ElementManager* manager)
    : FiberElement(manager, "view") {
  is_layout_only_ = true;
  SetStyle(kPropertyIDPosition, lepus::Value("absolute"));
  SetStyle(kPropertyIDDisplay, lepus::Value("none"));
}

}  // namespace tasm
}  // namespace lynx
