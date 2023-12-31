// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_ANIMATION_ANIMATION_H_
#define LYNX_ANIMATION_ANIMATION_H_

#include <memory>
#include <string>
#include <unordered_set>

#include "animation/keyframe_effect.h"
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
class KeyframeEffect;
class Animation : public std::enable_shared_from_this<Animation> {
 public:
  // It is a dummy animation start time used to indicate that the starting time
  // for the animation has not yet been properly set.
  // Q: Why do we need this dummy time?
  // A: This dummy time is used to immediately tick the animation when it is
  // created to ensure the style is correct. When the next vsync arrives, the
  // correct frame time should be used to update the animation's start time.

  // TODO(wujintian): Mark the fml::TimePoint parameter as const in all
  // interfaces of animation, and then mark this variable as const.
  static fml::TimePoint& GetAnimationDummyStartTime();

  enum class State { kIdle = 0, kPlay, kPause, kStop };
  Animation(const std::string& name);
  ~Animation() = default;
  void Play();
  void Pause();
  void Stop();
  void Destroy(bool need_clear_effect = true);

  void DoFrame(fml::TimePoint& frame_time);

  void CreateEventAndSend(const char* event);

  std::string& name() { return name_; }

  void BindDelegate(AnimationDelegate* target);

  bool HasFinishedAll(fml::TimePoint& time);

  void SetKeyframeEffect(std::unique_ptr<KeyframeEffect> keyframe_effect);

  KeyframeEffect* keyframe_effect() { return keyframe_effect_.get(); }

  void BindElement(tasm::Element* element) { element_ = element; }

  tasm::Element* GetElement() { return element_; }

  void set_animation_data(starlight::AnimationData& data) {
    animation_data_ = data;
  }

  starlight::AnimationData& get_animation_data() { return animation_data_; }

  void UpdateAnimationData(starlight::AnimationData& data);

  // TODO: (WUJINTIAN) Refine it, return AnimationData& instead of
  // AnimationData*.
  starlight::AnimationData* animation_data() { return &animation_data_; }

  void SetRawCssId(tasm::CSSPropertyID id) { raw_style_set_.insert(id); }

  std::unordered_set<tasm::CSSPropertyID>& GetRawStyleSet() {
    return raw_style_set_;
  }

  State GetState() { return state_; }

  void SetTransitionFlag() { is_transition_ = true; }

  bool GetTransitionFlag() { return is_transition_; }

  void NotifyElementSizeUpdated();

 protected:
  fml::TimePoint start_time_{fml::TimePoint::Min()};

 private:
  void Tick(fml::TimePoint& time);
  void RequestNextFrame();
  AnimationDelegate* animation_delegate_{nullptr};
  std::string name_;
  std::unique_ptr<KeyframeEffect> keyframe_effect_;

  // FIXME(linxs): each Keyframe segment may can use different timing function
  starlight::AnimationData animation_data_;

  tasm::Element* element_{nullptr};

  std::unordered_set<tasm::CSSPropertyID> raw_style_set_{};

  State state_{State::kIdle};

  // TODO(WANGYIFEI): remove this flag, using inherited class instead.
  bool is_transition_ = false;
};

}  // namespace animation
}  // namespace lynx

#endif  // LYNX_ANIMATION_ANIMATION_H_
