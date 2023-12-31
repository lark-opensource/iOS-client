// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_ANIMATION_CSS_TRANSITION_MANAGER_H_
#define LYNX_ANIMATION_CSS_TRANSITION_MANAGER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "animation/css_keyframe_manager.h"
#include "starlight/style/transition_data.h"

namespace lynx {
namespace animation {

std::string ConvertAnimationPropertyTypeToString(
    lynx::starlight::AnimationPropertyType type);

class CSSTransitionManager : public CSSKeyframeManager {
 public:
  CSSTransitionManager(tasm::Element* element) : CSSKeyframeManager(element) {}
  ~CSSTransitionManager() = default;

  void setTransitionData(
      std::vector<starlight::TransitionData>& transition_data);

  tasm::CSSKeyframesMap& GetKeyframesStyleMap(
      const std::string& animation_name) override;

  void TickAllAnimation(fml::TimePoint& time) override;

  bool ConsumeCSSProperty(tasm::CSSPropertyID css_id,
                          const tasm::CSSValue& end_value);

 private:
  void TryToStopTransitionAnimator(
      starlight::AnimationPropertyType property_type);
  bool IsValueValid(starlight::AnimationPropertyType type,
                    const tasm::CSSValue& value,
                    const tasm::CSSParserConfigs& configs);
  void SetTransitionDataInternal(
      const starlight::TransitionData& data,
      std::unordered_map<lepus::String, std::shared_ptr<Animation>>&
          active_animations_map);

  static starlight::AnimationPropertyType GetAnimationPropertyType(
      tasm::CSSPropertyID id);

 protected:
  std::unordered_map<unsigned int, starlight::AnimationData> transition_data_;
  std::unordered_map<std::string, tasm::CSSKeyframesMap> keyframe_tokens_;
  unsigned int property_type_value_{0};
};

}  // namespace animation
}  // namespace lynx

#endif  // LYNX_ANIMATION_CSS_TRANSITION_MANAGER_H_
