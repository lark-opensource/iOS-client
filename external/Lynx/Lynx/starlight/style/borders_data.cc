// Copyright 2021 The Lynx Authors. All rights reserved.

#include "starlight/style/borders_data.h"

#include "starlight/style/css_style_utils.h"
#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

BordersData::BordersData(bool css_align_with_legacy_w3c)
    : width_top(DEFAULT_CSS_VALUE(css_align_with_legacy_w3c, BORDER)),
      width_right(DEFAULT_CSS_VALUE(css_align_with_legacy_w3c, BORDER)),
      width_bottom(DEFAULT_CSS_VALUE(css_align_with_legacy_w3c, BORDER)),
      width_left(DEFAULT_CSS_VALUE(css_align_with_legacy_w3c, BORDER)),
      radius_x_top_left(DefaultCSSStyle::SL_DEFAULT_RADIUS()),
      radius_x_top_right(DefaultCSSStyle::SL_DEFAULT_RADIUS()),
      radius_x_bottom_right(DefaultCSSStyle::SL_DEFAULT_RADIUS()),
      radius_x_bottom_left(DefaultCSSStyle::SL_DEFAULT_RADIUS()),
      radius_y_top_left(DefaultCSSStyle::SL_DEFAULT_RADIUS()),
      radius_y_top_right(DefaultCSSStyle::SL_DEFAULT_RADIUS()),
      radius_y_bottom_right(DefaultCSSStyle::SL_DEFAULT_RADIUS()),
      radius_y_bottom_left(DefaultCSSStyle::SL_DEFAULT_RADIUS()),
      color_top(DefaultCSSStyle::SL_DEFAULT_BORDER_COLOR),
      color_right(DefaultCSSStyle::SL_DEFAULT_BORDER_COLOR),
      color_bottom(DefaultCSSStyle::SL_DEFAULT_BORDER_COLOR),
      color_left(DefaultCSSStyle::SL_DEFAULT_BORDER_COLOR),
      style_top(DEFAULT_CSS_VALUE(css_align_with_legacy_w3c, BORDER_STYLE)),
      style_right(DEFAULT_CSS_VALUE(css_align_with_legacy_w3c, BORDER_STYLE)),
      style_bottom(DEFAULT_CSS_VALUE(css_align_with_legacy_w3c, BORDER_STYLE)),
      style_left(DEFAULT_CSS_VALUE(css_align_with_legacy_w3c, BORDER_STYLE)),
      css_align_with_legacy_w3c_(css_align_with_legacy_w3c) {}

void BordersData::Reset() {
  width_top = DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER);
  width_right = DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER);
  width_bottom = DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER);
  width_left = DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER);
  radius_x_top_left = DefaultCSSStyle::SL_DEFAULT_RADIUS();
  radius_x_top_right = DefaultCSSStyle::SL_DEFAULT_RADIUS();
  radius_x_bottom_right = DefaultCSSStyle::SL_DEFAULT_RADIUS();
  radius_x_bottom_left = DefaultCSSStyle::SL_DEFAULT_RADIUS();
  radius_y_top_left = DefaultCSSStyle::SL_DEFAULT_RADIUS();
  radius_y_top_right = DefaultCSSStyle::SL_DEFAULT_RADIUS();
  radius_y_bottom_right = DefaultCSSStyle::SL_DEFAULT_RADIUS();
  radius_y_bottom_left = DefaultCSSStyle::SL_DEFAULT_RADIUS();
  color_top = DefaultCSSStyle::SL_DEFAULT_COLOR;
  color_right = DefaultCSSStyle::SL_DEFAULT_COLOR;
  color_bottom = DefaultCSSStyle::SL_DEFAULT_COLOR;
  color_left = DefaultCSSStyle::SL_DEFAULT_COLOR;
  style_top = DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE);
  style_right = DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE);
  style_bottom = DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE);
  style_left = DEFAULT_CSS_VALUE(css_align_with_legacy_w3c_, BORDER_STYLE);
}
}  // namespace starlight
}  // namespace lynx
