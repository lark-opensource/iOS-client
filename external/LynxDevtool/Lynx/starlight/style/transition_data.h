// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_TRANSITION_DATA_H_
#define LYNX_STARLIGHT_STYLE_TRANSITION_DATA_H_

#include <tuple>

#include "starlight/style/css_type.h"
#include "starlight/style/timing_function_data.h"

namespace lynx {
namespace starlight {
struct TransitionData {
  TransitionData();
  ~TransitionData() = default;

  long duration;
  long delay;
  AnimationPropertyType property;
  TimingFunctionData timing_func;
  bool operator==(const TransitionData& rhs) const {
    return std::tie(duration, delay, property, timing_func) ==
           std::tie(rhs.duration, rhs.delay, rhs.property, rhs.timing_func);
  }
};
}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_TRANSITION_DATA_H_
