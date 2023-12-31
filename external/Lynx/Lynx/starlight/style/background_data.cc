// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/background_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

BackgroundData::BackgroundData()
    : color(DefaultCSSStyle::SL_DEFAULT_COLOR),
      image_count(DefaultCSSStyle::SL_DEFAULT_LONG) {}

bool BackgroundData::HasBackground() const {
  return color != DefaultCSSStyle::SL_DEFAULT_COLOR ||
         image_count != DefaultCSSStyle::SL_DEFAULT_LONG;
}

}  // namespace starlight
}  // namespace lynx
