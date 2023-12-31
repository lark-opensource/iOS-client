// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_REACT_FIBER_TEXT_ELEMENT_H_
#define LYNX_TASM_REACT_FIBER_TEXT_ELEMENT_H_

#include "tasm/react/fiber/fiber_element.h"

namespace lynx {
namespace tasm {

class TextElement : public FiberElement {
 public:
  TextElement(ElementManager* manager, const lepus::String& tag);
  bool is_text() const override { return true; }
  void SetStyleInternal(CSSPropertyID id, const tasm::CSSValue& value,
                        bool force_update = false) override;

 protected:
  void OnNodeAdded(FiberElement* child) override;
  void SetAttributeInternal(const lepus::String& key,
                            const lepus::Value& value) override;

 private:
  static constexpr const char* kTextTag = "text";
  static constexpr const char* kInlineTextTag = "inline-text";
  static constexpr const char* kXTextTag = "x-text";
  static constexpr const char* kXInlineTextTag = "x-inline-text";
  // convert the tag to inline-text, it is not reversible
  void ConvertToInlineText();

  void ResolveAndFlushFontFaces(const lepus::String& font_family);
};

}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_REACT_FIBER_TEXT_ELEMENT_H_
