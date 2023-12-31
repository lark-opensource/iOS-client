// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/box_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

BoxData::BoxData()
    : width_(DefaultCSSStyle::SL_DEFAULT_WIDTH()),
      height_(DefaultCSSStyle::SL_DEFAULT_HEIGHT()),
      min_width_(DefaultCSSStyle::SL_DEFAULT_MIN_WIDTH()),
      max_width_(DefaultCSSStyle::SL_DEFAULT_MAX_WIDTH()),
      min_height_(DefaultCSSStyle::SL_DEFAULT_MIN_HEIGHT()),
      max_height_(DefaultCSSStyle::SL_DEFAULT_MAX_HEIGHT()),
      aspect_ratio_(DefaultCSSStyle::SL_DEFAULT_ASPECT_RATIO) {}

BoxData::BoxData(const BoxData& other)
    : width_(other.width_),
      height_(other.height_),
      min_width_(other.min_width_),
      max_width_(other.max_height_),
      min_height_(other.min_height_),
      max_height_(other.max_height_),
      aspect_ratio_(other.aspect_ratio_) {}

void BoxData::Reset() {
  width_ = DefaultCSSStyle::SL_DEFAULT_WIDTH();
  height_ = DefaultCSSStyle::SL_DEFAULT_HEIGHT();
  max_width_ = DefaultCSSStyle::SL_DEFAULT_MAX_WIDTH();
  max_height_ = DefaultCSSStyle::SL_DEFAULT_MAX_HEIGHT();
  min_width_ = DefaultCSSStyle::SL_DEFAULT_MIN_WIDTH();
  min_height_ = DefaultCSSStyle::SL_DEFAULT_MIN_HEIGHT();
  aspect_ratio_ = DefaultCSSStyle::SL_DEFAULT_ASPECT_RATIO;
}

}  // namespace starlight
}  // namespace lynx
