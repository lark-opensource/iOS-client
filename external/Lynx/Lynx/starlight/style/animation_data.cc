// Copyright 2020 The Lynx Authors. All rights reserved.

#include "starlight/style/animation_data.h"

#include "starlight/style/default_css_style.h"

namespace lynx {
namespace starlight {
AnimationData::AnimationData()
    : name(DefaultCSSStyle::EMPTY_LEPUS_STRING()),
      duration(DefaultCSSStyle::SL_DEFAULT_LONG),
      delay(DefaultCSSStyle::SL_DEFAULT_LONG),
      iteration_count(1),
      fill_mode(AnimationFillModeType::kNone),
      direction(AnimationDirectionType::kNormal),
      play_state(AnimationPlayStateType::kRunning) {}

}  // namespace starlight
}  // namespace lynx
