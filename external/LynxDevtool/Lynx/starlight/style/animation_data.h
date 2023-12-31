// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_ANIMATION_DATA_H_
#define LYNX_STARLIGHT_STYLE_ANIMATION_DATA_H_

#include "lepus/value.h"
#include "starlight/style/css_type.h"
#include "starlight/style/timing_function_data.h"

namespace lynx {
namespace starlight {
struct AnimationData {
  AnimationData();
  ~AnimationData() = default;
  lepus::String name;
  long duration;
  long delay;
  TimingFunctionData timing_func;
  int iteration_count;
  AnimationFillModeType fill_mode;
  AnimationDirectionType direction;
  AnimationPlayStateType play_state;

  bool operator==(const AnimationData& rhs) const {
    return std::tie(name, timing_func, iteration_count, fill_mode, duration,
                    delay, direction, play_state) ==
           std::tie(rhs.name, rhs.timing_func, rhs.iteration_count,
                    rhs.fill_mode, rhs.duration, rhs.delay, rhs.direction,
                    rhs.play_state);
  }

  bool operator!=(const AnimationData& rhs) const { return !operator==(rhs); }
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_ANIMATION_DATA_H_
