// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/surround_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

SurroundData::SurroundData()
    : left_(DefaultCSSStyle::SL_DEFAULT_FOUR_POSITION()),
      right_(DefaultCSSStyle::SL_DEFAULT_FOUR_POSITION()),
      top_(DefaultCSSStyle::SL_DEFAULT_FOUR_POSITION()),
      bottom_(DefaultCSSStyle::SL_DEFAULT_FOUR_POSITION()),
      margin_left_(DefaultCSSStyle::SL_DEFAULT_MARGIN()),
      margin_right_(DefaultCSSStyle::SL_DEFAULT_MARGIN()),
      margin_top_(DefaultCSSStyle::SL_DEFAULT_MARGIN()),
      margin_bottom_(DefaultCSSStyle::SL_DEFAULT_MARGIN()),
      padding_left_(DefaultCSSStyle::SL_DEFAULT_PADDING()),
      padding_right_(DefaultCSSStyle::SL_DEFAULT_PADDING()),
      padding_top_(DefaultCSSStyle::SL_DEFAULT_PADDING()),
      padding_bottom_(DefaultCSSStyle::SL_DEFAULT_PADDING()) {
  border_data_.reset();
}

void SurroundData::Reset() {
  left_ = DefaultCSSStyle::SL_DEFAULT_FOUR_POSITION();
  right_ = DefaultCSSStyle::SL_DEFAULT_FOUR_POSITION();
  top_ = DefaultCSSStyle::SL_DEFAULT_FOUR_POSITION();
  bottom_ = DefaultCSSStyle::SL_DEFAULT_FOUR_POSITION();

  margin_left_ = DefaultCSSStyle::SL_DEFAULT_MARGIN();
  margin_right_ = DefaultCSSStyle::SL_DEFAULT_MARGIN();
  margin_top_ = DefaultCSSStyle::SL_DEFAULT_MARGIN();
  margin_bottom_ = DefaultCSSStyle::SL_DEFAULT_MARGIN();

  padding_left_ = DefaultCSSStyle::SL_DEFAULT_PADDING();
  padding_right_ = DefaultCSSStyle::SL_DEFAULT_PADDING();
  padding_top_ = DefaultCSSStyle::SL_DEFAULT_PADDING();
  padding_bottom_ = DefaultCSSStyle::SL_DEFAULT_PADDING();

  border_data_.reset();
}

}  // namespace starlight
}  // namespace lynx
