// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/outline_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

OutLineData::OutLineData()
    : width(DefaultCSSStyle::SL_DEFAULT_FLOAT),
      style(DefaultCSSStyle::SL_DEFAULT_OUTLINE_STYLE),
      color(DefaultCSSStyle::SL_DEFAULT_OUTLINE_COLOR) {}
}  // namespace starlight
}  // namespace lynx
