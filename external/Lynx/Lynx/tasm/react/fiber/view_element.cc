// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/view_element.h"

#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

ViewElement::ViewElement(ElementManager* manager)
    : FiberElement(manager, "view") {
  SetDefaultOverflow(element_manager_->GetDefaultOverflowVisible());
  MarkCanBeLayoutOnly(true);
}

}  // namespace tasm
}  // namespace lynx
