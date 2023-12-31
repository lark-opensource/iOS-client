// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_ANIMATION_TESTING_MOCK_CSS_TRANSITION_MANAGER_H_
#define LYNX_ANIMATION_TESTING_MOCK_CSS_TRANSITION_MANAGER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "animation/css_transition_manager.h"
#include "starlight/style/transition_data.h"

namespace lynx {
namespace animation {

class MockCSSTransitionManager : public CSSTransitionManager {
 public:
  MockCSSTransitionManager(tasm::Element* element)
      : CSSTransitionManager(element) {}
  ~MockCSSTransitionManager() = default;

  std::unordered_map<unsigned int, starlight::AnimationData>&
  transition_data() {
    return transition_data_;
  }

  std::vector<starlight::AnimationData>& animation_data() {
    return animation_data_;
  }

  unsigned int property_type_value() { return property_type_value_; }

  std::unordered_map<std::string, tasm::CSSKeyframesMap>& keyframe_tokens() {
    return keyframe_tokens_;
  }

  std::unordered_map<lepus::String, std::shared_ptr<Animation>>&
  animations_map() {
    return animations_map_;
  }

  void NotifyClientAnimated(tasm::StyleMap& styles, tasm::CSSValue value,
                            tasm::CSSPropertyID css_id) override {
    has_been_ticked_ = true;
  }

  void SetNeedsAnimationStyleRecalc(const std::string& name) override {
    clear_effect_animation_name_ = name;
  }

  bool has_been_ticked() { return has_been_ticked_; }

  const std::string& GetClearEffectAnimationName() {
    return clear_effect_animation_name_;
  }

 private:
  bool has_been_ticked_{false};
  std::string clear_effect_animation_name_;
};

}  // namespace animation
}  // namespace lynx

#endif  // LYNX_ANIMATION_TESTING_MOCK_CSS_TRANSITION_MANAGER_H_
