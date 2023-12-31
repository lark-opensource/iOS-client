// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/transition_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {

TransitionData::TransitionData()
    : duration(DefaultCSSStyle::SL_DEFAULT_LONG),
      delay(DefaultCSSStyle::SL_DEFAULT_LONG),
      property(AnimationPropertyType::kNone) {}
}  // namespace starlight
}  // namespace lynx
