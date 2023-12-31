// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/flex_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

FlexData::FlexData()
    : flex_grow_(DefaultCSSStyle::SL_DEFAULT_FLEX_GROW),
      flex_shrink_(DefaultCSSStyle::SL_DEFAULT_FLEX_SHRINK),
      flex_basis_(DefaultCSSStyle::SL_DEFAULT_FLEX_BASIS()),
      flex_direction_(DefaultCSSStyle::SL_DEFAULT_FLEX_DIRECTION),
      flex_wrap_(DefaultCSSStyle::SL_DEFAULT_FLEX_WRAP),
      justify_content_(DefaultCSSStyle::SL_DEFAULT_JUSTIFY_CONTENT),
      align_items_(DefaultCSSStyle::SL_DEFAULT_ALIGN_ITEMS),
      align_self_(DefaultCSSStyle::SL_DEFAULT_ALIGN_SELF),
      align_content_(DefaultCSSStyle::SL_DEFAULT_ALIGN_CONTENT),
      order_(DefaultCSSStyle::SL_DEFAULT_ORDER) {}

FlexData::FlexData(const FlexData& data)
    : flex_grow_(data.flex_grow_),
      flex_shrink_(data.flex_shrink_),
      flex_basis_(data.flex_basis_),
      flex_direction_(data.flex_direction_),
      flex_wrap_(data.flex_wrap_),
      justify_content_(data.justify_content_),
      align_items_(data.align_items_),
      align_self_(data.align_self_),
      align_content_(data.align_content_),
      order_(data.order_) {}

void FlexData::Reset() {
  flex_grow_ = DefaultCSSStyle::SL_DEFAULT_FLEX_GROW;
  flex_shrink_ = DefaultCSSStyle::SL_DEFAULT_FLEX_SHRINK;
  flex_basis_ = DefaultCSSStyle::SL_DEFAULT_FLEX_BASIS();
  flex_direction_ = DefaultCSSStyle::SL_DEFAULT_FLEX_DIRECTION;
  flex_wrap_ = DefaultCSSStyle::SL_DEFAULT_FLEX_WRAP;
  justify_content_ = DefaultCSSStyle::SL_DEFAULT_JUSTIFY_CONTENT;
  align_items_ = DefaultCSSStyle::SL_DEFAULT_ALIGN_ITEMS;
  align_self_ = DefaultCSSStyle::SL_DEFAULT_ALIGN_SELF;
  align_content_ = DefaultCSSStyle::SL_DEFAULT_ALIGN_CONTENT;
  order_ = DefaultCSSStyle::SL_DEFAULT_ORDER;
}

}  // namespace starlight
}  // namespace lynx
