// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_ANIMATION_CSS_KEYFRAME_MANAGER_H_
#define LYNX_ANIMATION_CSS_KEYFRAME_MANAGER_H_

#include <memory>
#include <string>
#include <unordered_map>
#include <utility>
#include <vector>

#include "animation/animation.h"
#include "animation/animation_delegate.h"
#include "animation/keyframe_effect.h"
#include "animation/keyframed_animation_curve.h"
#include "animation/timing_function.h"
#include "css/css_keyframes_token.h"
#include "css/css_property.h"
#include "starlight/style/animation_data.h"
#include "starlight/style/computed_css_style.h"
#include "third_party/fml/time/time_point.h"

namespace lynx {

namespace shell {
class VSyncMonitor;
}

namespace tasm {
class Element;
class CSSKeyframesToken;
}  // namespace tasm
namespace animation {
const std::unordered_map<tasm::CSSPropertyID, starlight::AnimationPropertyType>&
GetPropertyIDToAnimationPropertyTypeMap();

// Check that is this property a animatable property for new animator.
bool IsAnimatableProperty(tasm::CSSPropertyID css_id);

class CSSKeyframeManager : public AnimationDelegate {
 public:
  static const starlight::CssMeasureContext& GetLengthContext(
      tasm::Element* element);

  CSSKeyframeManager(tasm::Element* element);
  ~CSSKeyframeManager() = default;

  void SetAnimationDataAndPlay(
      std::vector<starlight::AnimationData>& anim_data);

  virtual void TickAllAnimation(fml::TimePoint& time);

  void RequestNextFrame(std::weak_ptr<Animation> ptr) override;

  void UpdateFinalStyleMap(const tasm::StyleMap& styles) override;

  void FlushAnimatedStyle() override;

  void NotifyClientAnimated(tasm::StyleMap& styles, tasm::CSSValue value,
                            tasm::CSSPropertyID css_id) override;
  void SetNeedsAnimationStyleRecalc(const std::string& name) override;

  KeyframeModel* InitCurveAndModel(AnimationCurve::CurveType type,
                                   Animation* animation);
  bool InitCurveAndModelAndKeyframe(
      AnimationCurve::CurveType type, Animation* animation, double offset,
      std::unique_ptr<TimingFunction> timing_function,
      std::pair<tasm::CSSPropertyID, tasm::CSSValue> css_value_pair);

  KeyframeModel* ConstructModel(std::unique_ptr<AnimationCurve> curve,
                                AnimationCurve::CurveType type,
                                Animation* animation);
  bool SetKeyframeValue(
      const std::pair<tasm::CSSPropertyID, tasm::CSSValue>& css_value_pair);

  virtual tasm::CSSKeyframesMap& GetKeyframesStyleMap(
      const std::string& animation_name);

  tasm::CSSKeyframesMap& empty_keyframe_map() { return empty_keyframe_map_; }

  static tasm::CSSValue GetDefaultValue(starlight::AnimationPropertyType type);

  void NotifyElementSizeUpdated();

 protected:
  std::shared_ptr<Animation> CreateAnimation(starlight::AnimationData& data);

  std::vector<starlight::AnimationData> animation_data_;
  // animations of css style
  std::unordered_map<lepus::String, std::shared_ptr<Animation>> animations_map_;
  // save active animations for play and clear
  std::unordered_map<lepus::String, std::shared_ptr<Animation>>
      temp_active_animations_map_;

 private:
  void MakeKeyframeModel(Animation* animation,
                         const std::string& animation_name);

 private:
  std::shared_ptr<shell::VSyncMonitor> vsync_monitor_{nullptr};
  tasm::CSSKeyframesMap empty_keyframe_map_;
};

}  // namespace animation
}  // namespace lynx

#endif  // LYNX_ANIMATION_CSS_KEYFRAME_MANAGER_H_
