// Copyright 2020 The Lynx Authors. All rights reserved.

#ifndef LYNX_STARLIGHT_STYLE_LAYOUT_ANIMATION_DATA_H_
#define LYNX_STARLIGHT_STYLE_LAYOUT_ANIMATION_DATA_H_

#include <tuple>

#include "starlight/style/css_type.h"
#include "starlight/style/timing_function_data.h"

namespace lynx {
namespace starlight {

struct BaseLayoutAnimationData {
  long duration;
  long delay;
  starlight::AnimationPropertyType property;
  TimingFunctionData timing_function;
  BaseLayoutAnimationData();
  ~BaseLayoutAnimationData() = default;
  void Reset();
  bool operator==(const BaseLayoutAnimationData& rhs) const {
    return std::tie(duration, delay, property, timing_function) ==
           std::tie(rhs.duration, rhs.delay, rhs.property, rhs.timing_function);
  }
};

struct LayoutAnimationData {
  LayoutAnimationData() = default;
  ~LayoutAnimationData() = default;

  BaseLayoutAnimationData create_ani;
  BaseLayoutAnimationData update_ani;
  BaseLayoutAnimationData delete_ani;
};

}  // namespace starlight
}  // namespace lynx

#endif  // LYNX_STARLIGHT_STYLE_LAYOUT_ANIMATION_DATA_H_
