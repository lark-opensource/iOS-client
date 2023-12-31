// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_ANIMATION_TESTING_MOCK_CSS_KEYFRAME_MANAGER_H_
#define LYNX_ANIMATION_TESTING_MOCK_CSS_KEYFRAME_MANAGER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "animation/animation.h"
#include "animation/animation_delegate.h"
#include "animation/css_keyframe_manager.h"
#include "animation/keyframe_effect.h"
#include "animation/keyframed_animation_curve.h"
#include "animation/timing_function.h"
#include "css/css_keyframes_token.h"
#include "css/css_property.h"
#include "starlight/style/animation_data.h"
#include "starlight/style/computed_css_style.h"
#include "third_party/fml/time/time_point.h"

namespace lynx {

namespace animation {

class MockCSSKeyframeManager : public CSSKeyframeManager {
 public:
  MockCSSKeyframeManager(tasm::Element* element)
      : CSSKeyframeManager(element) {}
  ~MockCSSKeyframeManager() = default;
  std::unordered_map<lepus::String, std::shared_ptr<Animation>>&
  animations_map() {
    return animations_map_;
  }

  void SetNeedsAnimationStyleRecalc(const std::string& name) override {
    clear_effect_animation_name_ = name;
  }

  const std::string& GetClearEffectAnimationName() {
    return clear_effect_animation_name_;
  }

  void RequestNextFrame(std::weak_ptr<Animation> ptr) override {
    has_request_next_frame_ = true;
  }

  void FlushAnimatedStyle() override { has_flush_animated_style_ = true; }

  bool has_flush_animated_style() { return has_flush_animated_style_; }

  bool has_request_next_frame() { return has_request_next_frame_; }

  void ClearUTStatus();

 private:
  std::string clear_effect_animation_name_;
  bool has_flush_animated_style_{false};
  bool has_request_next_frame_{false};
};

}  // namespace animation
}  // namespace lynx

#endif  // LYNX_ANIMATION_TESTING_MOCK_CSS_KEYFRAME_MANAGER_H_
