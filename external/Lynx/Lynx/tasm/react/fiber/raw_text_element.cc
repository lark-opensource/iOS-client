// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/raw_text_element.h"

namespace lynx {
namespace tasm {

RawTextElement::RawTextElement(ElementManager* manager)
    : FiberElement(manager, "raw-text") {}

void RawTextElement::SetText(const lepus::Value& text) {
  SetAttribute(kTextAttr, text);
}

}  // namespace tasm
}  // namespace lynx
