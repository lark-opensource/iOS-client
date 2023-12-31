// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/linear_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

LinearData::LinearData()
    : linear_weight_sum_(DefaultCSSStyle::SL_DEFAULT_LINEAR_WEIGHT_SUM),
      linear_weight_(DefaultCSSStyle::SL_DEFAULT_LINEAR_WEIGHT),
      linear_orientation_(DefaultCSSStyle::SL_DEFAULT_LINEAR_ORIENTATION),
      linear_layout_gravity_(DefaultCSSStyle::SL_DEFAULT_LINEAR_LAYOUT_GRAVITY),
      linear_gravity_(DefaultCSSStyle::SL_DEFAULT_LINEAR_GRAVITY),
      linear_cross_gravity_(DefaultCSSStyle::SL_DEFAULT_LINEAR_CROSS_GRAVITY) {}

LinearData::LinearData(const LinearData& data)
    : linear_weight_sum_(data.linear_weight_sum_),
      linear_weight_(data.linear_weight_),
      linear_orientation_(data.linear_orientation_),
      linear_layout_gravity_(data.linear_layout_gravity_),
      linear_gravity_(data.linear_gravity_),
      linear_cross_gravity_(data.linear_cross_gravity_) {}

void LinearData::Reset() {
  linear_weight_sum_ = DefaultCSSStyle::SL_DEFAULT_LINEAR_WEIGHT_SUM;
  linear_weight_ = DefaultCSSStyle::SL_DEFAULT_LINEAR_WEIGHT;
  linear_orientation_ = DefaultCSSStyle::SL_DEFAULT_LINEAR_ORIENTATION;
  linear_layout_gravity_ = DefaultCSSStyle::SL_DEFAULT_LINEAR_LAYOUT_GRAVITY;
  linear_gravity_ = DefaultCSSStyle::SL_DEFAULT_LINEAR_GRAVITY;
  linear_cross_gravity_ = DefaultCSSStyle::SL_DEFAULT_LINEAR_CROSS_GRAVITY;
}

}  // namespace starlight
}  // namespace lynx
