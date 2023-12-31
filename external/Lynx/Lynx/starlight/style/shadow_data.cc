// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/shadow_data.h"

#include <base/float_comparison.h>

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {
void ShadowData::Reset() {
  h_offset = 0;
  v_offset = 0;
  blur = 0;
  spread = 0;
  color = DefaultCSSStyle::SL_DEFAULT_SHADOW_COLOR;
  option = ShadowOption::kNone;
}

}  // namespace starlight
}  // namespace lynx
