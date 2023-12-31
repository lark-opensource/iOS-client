// Copyright 2021 The Lynx Authors. All rights reserved.
// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef LYNX_ANIMATION_KEYFRAME_EFFECT_H_
#define LYNX_ANIMATION_KEYFRAME_EFFECT_H_

#include <memory>
#include <vector>

#include "animation/animation_curve.h"
#include "animation/animation_delegate.h"
#include "animation/keyframe_model.h"
#include "third_party/fml/time/time_point.h"

namespace lynx {

namespace tasm {
class Element;
class CSSKeyframesToken;
}  // namespace tasm

namespace animation {
class Animation;

class KeyframeEffect {
 public:
  KeyframeEffect();
  virtual ~KeyframeEffect() = default;

  void TickKeyframeModel(fml::TimePoint monotonic_time);

  void AddKeyframeModel(std::unique_ptr<KeyframeModel> keyframe_model);

  KeyframeModel* GetKeyframeModelByCurveType(AnimationCurve::CurveType type);

  void SetAnimation(Animation* animation) { animation_ = animation; }

  void SetStartTime(fml::TimePoint& time);

  void SetPauseTime(fml::TimePoint& time);

  static std::unique_ptr<KeyframeEffect> Create();
  void BindAnimationDelegate(AnimationDelegate* target) {
    animation_delegate_ = target;
  }
  void BindElement(tasm::Element* element) { element_ = element; }
  bool CheckHasFinished(fml::TimePoint& time);

  void ClearEffect();

  void UpdateAnimationData(starlight::AnimationData* data);

  bool SendStartEvent() {
    if (!send_start_event_) {
      send_start_event_ = true;
      return true;
    }
    return false;
  };

  void EnsureFromAndToKeyframe();

  Animation* GetAnimation() { return animation_; }

  std::vector<std::unique_ptr<KeyframeModel>>& keyframe_models() {
    return keyframe_models_;
  }

  void NotifyElementSizeUpdated();

 private:
  // The counter records the current iteration_count of the animation.
  int current_iteration_count_ = 0;
  tasm::Element* element_{nullptr};
  std::vector<std::unique_ptr<KeyframeModel>> keyframe_models_;
  AnimationDelegate* animation_delegate_;
  Animation* animation_{nullptr};
  bool send_start_event_ = false;
};

}  // namespace animation
}  // namespace lynx

#endif  // LYNX_ANIMATION_KEYFRAME_EFFECT_H_
