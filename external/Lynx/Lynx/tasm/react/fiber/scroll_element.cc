// Copyright 2022 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/scroll_element.h"

#include "tasm/react/element_manager.h"

namespace lynx {
namespace tasm {

void ScrollElement::OnNodeAdded(FiberElement* child) {
  // Scroll's child should not be layout only.
  child->MarkCanBeLayoutOnly(false);
}

void ScrollElement::SetAttributeInternal(const lepus::String& key,
                                         const lepus::Value& value) {
  FiberElement::SetAttributeInternal(key, value);

  StyleMap attr_styles;
  constexpr const static char kScrollX[] = "scroll-x";
  constexpr const static char kScrollY[] = "scroll-y";
  constexpr const static char kScrollXReverse[] = "scroll-x-reverse";
  constexpr const static char kScrollYReverse[] = "scroll-y-reverse";
  constexpr const static char kTrue[] = "true";
  if (key.IsEquals(kScrollX) && value.String()->IsEqual(kTrue)) {
    attr_styles.insert_or_assign(
        kPropertyIDLinearOrientation,
        CSSValue::MakeEnum(
            static_cast<int>(starlight::LinearOrientationType::kHorizontal)));
    element_manager()->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
  } else if (key.IsEquals(kScrollY) && value.String()->IsEqual(kTrue)) {
    attr_styles.insert_or_assign(
        kPropertyIDLinearOrientation,
        CSSValue::MakeEnum(
            static_cast<int>(starlight::LinearOrientationType::kVertical)));
    element_manager()->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
  } else if (key.IsEquals(kScrollXReverse) && value.String()->IsEqual(kTrue)) {
    attr_styles.insert_or_assign(
        kPropertyIDLinearOrientation,
        CSSValue::MakeEnum(static_cast<int>(
            starlight::LinearOrientationType::kHorizontalReverse)));
    element_manager()->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
  } else if (key.IsEquals(kScrollYReverse) && value.String()->IsEqual(kTrue)) {
    attr_styles.insert_or_assign(
        kPropertyIDLinearOrientation,
        CSSValue::MakeEnum(static_cast<int>(
            starlight::LinearOrientationType::kVerticalReverse)));
    element_manager()->UpdateLayoutNodeAttribute(
        layout_node_, starlight::LayoutAttribute::kScroll, lepus::Value(true));
  }
  SetStyle(attr_styles);
}

}  // namespace tasm
}  // namespace lynx
