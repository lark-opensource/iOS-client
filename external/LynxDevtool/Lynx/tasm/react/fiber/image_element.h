// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_IMAGE_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_IMAGE_ELEMENT_H_

#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {

class ImageElement : public FiberElement {
 public:
  ImageElement(ElementManager* manager, const lepus::String& tag)
      : FiberElement(manager, tag) {}
  bool is_image() const override { return true; }

  void OnNodeAdded(FiberElement* child) override;

  bool DisableFlattenWithOpacity();

  // convert the tag to inline-text, it is not reversible
  void ConvertToInlineImage();

 private:
  static constexpr const char* kInlineImageTag = "inline-image";
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_IMAGE_ELEMENT_H_
