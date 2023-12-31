// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/image_element.h"

namespace lynx {
namespace tasm {

void ImageElement::OnNodeAdded(FiberElement* child) {
  LOGE("image element can not any child!!!");
}

bool ImageElement::DisableFlattenWithOpacity() { return false; }

void ImageElement::ConvertToInlineImage() {
  tag_ = kInlineImageTag;
  data_model()->set_tag(kInlineImageTag);
  MarkAsInline();
}

}  // namespace tasm
}  // namespace lynx
