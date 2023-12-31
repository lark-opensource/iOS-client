// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/relative_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

RelativeData::RelativeData()
    : relative_id_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_ID),
      relative_align_top_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_TOP),
      relative_align_right_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_RIGHT),
      relative_align_bottom_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_BOTTOM),
      relative_align_left_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_LEFT),
      relative_top_of_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_TOP_OF),
      relative_right_of_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_RIGHT_OF),
      relative_bottom_of_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_BOTTOM_OF),
      relative_left_of_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_LEFT_OF),
      relative_layout_once_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_LAYOUT_ONCE),
      relative_center_(DefaultCSSStyle::SL_DEFAULT_RELATIVE_CENTER) {}

RelativeData::RelativeData(const RelativeData& data)
    : relative_id_(data.relative_id_),
      relative_align_top_(data.relative_align_top_),
      relative_align_right_(data.relative_align_right_),
      relative_align_bottom_(data.relative_align_bottom_),
      relative_align_left_(data.relative_align_left_),
      relative_top_of_(data.relative_top_of_),
      relative_right_of_(data.relative_right_of_),
      relative_bottom_of_(data.relative_bottom_of_),
      relative_left_of_(data.relative_left_of_),
      relative_layout_once_(data.relative_layout_once_),
      relative_center_(data.relative_center_) {}

void RelativeData::RelativeData::Reset() {
  relative_id_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_ID;
  relative_align_top_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_TOP;
  relative_align_right_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_RIGHT;
  relative_align_bottom_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_BOTTOM;
  relative_align_left_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_ALIGN_LEFT;
  relative_top_of_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_TOP_OF;
  relative_right_of_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_RIGHT_OF;
  relative_bottom_of_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_BOTTOM_OF;
  relative_left_of_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_LEFT_OF;
  relative_layout_once_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_LAYOUT_ONCE;
  relative_center_ = DefaultCSSStyle::SL_DEFAULT_RELATIVE_CENTER;
}

}  // namespace starlight
}  // namespace lynx
