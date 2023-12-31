// Copyright 2021 The Lynx Authors. All rights reserved.

#include "tasm/react/fiber/text_element.h"

#include "tasm/react/element_manager.h"
#include "tasm/react/fiber/image_element.h"
#include "tasm/react/fiber/raw_text_element.h"

namespace lynx {
namespace tasm {

TextElement::TextElement(ElementManager* manager, const lepus::String& tag)
    : FiberElement(manager, tag) {
  SetDefaultOverflow(element_manager_->GetDefaultTextOverflow());
}

void TextElement::SetStyleInternal(CSSPropertyID id,
                                   const tasm::CSSValue& value,
                                   bool force_update) {
  FiberElement::SetStyleInternal(id, value, force_update);

  if (id == kPropertyIDFontFamily) {
    ResolveAndFlushFontFaces(value.AsString());
  }
}

void TextElement::OnNodeAdded(FiberElement* child) {
  if (child->is_text()) {
    static_cast<TextElement*>(child)->ConvertToInlineText();
  } else if (child->is_image()) {
    static_cast<ImageElement*>(child)->ConvertToInlineImage();
  }
}

void TextElement::SetAttributeInternal(const lepus::String& key,
                                       const lepus::Value& value) {
  StyleMap attr_styles;
  // sometimes, text-overflow is used as attribute, so we need to parse the
  // value as CSS style here. it's better to mark such kind of attribute as
  // internal attributes, which may be processed as const IDs
  if (key.IsEqual("text-overflow")) {
    tasm::UnitHandler::Process(kPropertyIDTextOverflow, value, attr_styles,
                               element_manager_->GetCSSParserConfigs());
    for (const auto& style : attr_styles) {
      ResolveStyleValue(style.first, style.second, false);
    }
    has_layout_only_props_ = false;
  } else if (key.IsEqual("text")) {
    // if setNativeProps with key "text" on TextElement, we need to update it's
    // children.
    if (!children().empty() && children().begin()->Get()->is_raw_text()) {
      RawTextElement* raw_text =
          static_cast<RawTextElement*>(children().begin()->Get());
      raw_text->SetText(value);
    }
  } else {
    FiberElement::SetAttributeInternal(key, value);
  }
}

void TextElement::ConvertToInlineText() {
  if (tag_.IsEqual(kXTextTag)) {
    tag_ = kXInlineTextTag;
  } else {
    tag_ = kInlineTextTag;
  }
  data_model()->set_tag(kInlineTextTag);
  MarkAsInline();
}

void TextElement::ResolveAndFlushFontFaces(const lepus::String& font_family) {
  auto* fragment = GetRelatedCSSFragment();
  if (fragment && !fragment->fontfaces().empty() &&
      !fragment->HasFontFacesResolved()) {
    // FIXME(linxs): parse the font face according to font_family, instead of
    // flushing all font faces
    SetFontFaces(fragment->fontfaces());
    fragment->MarkFontFacesResolved(true);
  }
}

}  // namespace tasm
}  // namespace lynx
